import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/connectivity_service.dart';
import 'package:mobile/services/logger_service.dart';

enum SyncActionType {
  addToCart,
  removeFromCart,
  updateCartItem,
  addToFavorites,
  removeFromFavorites,
  updateProfile,
}

class SyncAction {
  SyncAction({
    required this.id,
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.retryCount = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SyncAction.fromJson(Map<String, dynamic> json) => SyncAction(
    id: json['id'],
    type: SyncActionType.values.firstWhere((e) => e.toString() == json['type']),
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
    retryCount: json['retryCount'] ?? 0,
  );

  final String id;
  final SyncActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };
}

@lazySingleton
class SyncService {
  SyncService(this._connectivityService) {
    _init();
  }
  static const String _queueBoxName = 'sync_queue';
  static const int _maxRetries = 3;
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService;

  // Flag to prevent concurrent processing
  bool _isProcessing = false;

  Future<void> _init() async {
    // Listen to connectivity changes and process queue when online
    _connectivityService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        // Use unawaited to prevent blocking, but processQueue handles concurrency
        processQueue();
      }
    });
  }

  Future<void> addToQueue(SyncAction action) async {
    try {
      final box = await Hive.openBox(_queueBoxName);
      await box.put(action.id, jsonEncode(action.toJson()));
      await box.close();
    } catch (e, stackTrace) {
      LoggerService().error('Error adding to sync queue', e, stackTrace);
    }
  }

  Future<void> removeFromQueue(String actionId) async {
    try {
      final box = await Hive.openBox(_queueBoxName);
      await box.delete(actionId);
      await box.close();
    } catch (e, stackTrace) {
      LoggerService().error('Error removing from sync queue', e, stackTrace);
    }
  }

  Future<List<SyncAction>> getQueuedActions() async {
    try {
      final box = await Hive.openBox(_queueBoxName);
      final actions = <SyncAction>[];

      for (final key in box.keys) {
        try {
          final jsonString = box.get(key) as String?;
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            actions.add(SyncAction.fromJson(json));
          }
        } catch (e, stackTrace) {
          LoggerService().warning('Error parsing queued action', e, stackTrace);
        }
      }

      await box.close();
      return actions;
    } catch (e, stackTrace) {
      LoggerService().error('Error getting queued actions', e, stackTrace);
      return [];
    }
  }

  Future<void> processQueue() async {
    // Prevent concurrent processing
    if (_isProcessing) {
      return;
    }

    if (!_connectivityService.isOnline) {
      return;
    }

    // Set processing flag before async operations
    _isProcessing = true;

    try {
      final actions = await getQueuedActions();

      // Early return if no actions, but finally will still execute
      if (actions.isEmpty) {
        return;
      }

      // Sort by timestamp (oldest first)
      actions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      for (final action in actions) {
        try {
          final success = await _executeAction(action);

          if (success) {
            await removeFromQueue(action.id);
          } else {
            // Increment retry count
            final updatedAction = SyncAction(
              id: action.id,
              type: action.type,
              data: action.data,
              timestamp: action.timestamp,
              retryCount: action.retryCount + 1,
            );

            if (updatedAction.retryCount >= _maxRetries) {
              // Remove after max retries
              await removeFromQueue(action.id);
              LoggerService().warning(
                '❌ [SYNC] Action failed after max retries: ${action.type} (${action.id})',
              );
            } else {
              // Update retry count
              await addToQueue(updatedAction);
            }
          }
        } catch (e, stackTrace) {
          LoggerService().error(
            '❌ [SYNC] Error processing action ${action.id}',
            e,
            stackTrace,
          );

          // Increment retry count on error
          final updatedAction = SyncAction(
            id: action.id,
            type: action.type,
            data: action.data,
            timestamp: action.timestamp,
            retryCount: action.retryCount + 1,
          );

          if (updatedAction.retryCount < _maxRetries) {
            await addToQueue(updatedAction);
          } else {
            await removeFromQueue(action.id);
          }
        }
      }
    } finally {
      // Always reset processing flag, even if an error occurs
      _isProcessing = false;
    }
  }

  Future<bool> _executeAction(SyncAction action) async {
    try {
      switch (action.type) {
        case SyncActionType.addToCart:
          await _apiService.addToCart(
            action.data['productId'] as String,
            action.data['quantity'] as int,
          );
          return true;

        case SyncActionType.removeFromCart:
          await _apiService.removeFromCart(action.data['itemId'] as String);
          return true;

        case SyncActionType.updateCartItem:
          await _apiService.updateCartItem(
            action.data['itemId'] as String,
            action.data['quantity'] as int,
          );
          return true;

        case SyncActionType.addToFavorites:
          await _apiService.addToFavorites(action.data['productId'] as String);
          return true;

        case SyncActionType.removeFromFavorites:
          await _apiService.removeFromFavorites(
            action.data['productId'] as String,
          );
          return true;

        case SyncActionType.updateProfile:
          await _apiService.updateProfile(
            action.data['profile'] as Map<String, dynamic>,
          );
          return true;
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error executing sync action', e, stackTrace);
      return false;
    }
  }

  Future<void> clearQueue() async {
    try {
      await Hive.deleteBoxFromDisk(_queueBoxName);
    } catch (e, stackTrace) {
      LoggerService().error('Error clearing sync queue', e, stackTrace);
    }
  }

  Future<int> getQueueSize() async {
    final actions = await getQueuedActions();
    return actions.length;
  }
}
