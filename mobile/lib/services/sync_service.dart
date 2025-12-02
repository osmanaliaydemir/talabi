import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/connectivity_service.dart';

enum SyncActionType {
  addToCart,
  removeFromCart,
  updateCartItem,
  addToFavorites,
  removeFromFavorites,
  updateProfile,
}

class SyncAction {
  final String id;
  final SyncActionType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  SyncAction({
    required this.id,
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.retryCount = 0,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'retryCount': retryCount,
  };

  factory SyncAction.fromJson(Map<String, dynamic> json) => SyncAction(
    id: json['id'],
    type: SyncActionType.values.firstWhere((e) => e.toString() == json['type']),
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
    retryCount: json['retryCount'] ?? 0,
  );
}

class SyncService {
  static const String _queueBoxName = 'sync_queue';
  static const int _maxRetries = 3;
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService;

  SyncService(this._connectivityService) {
    _init();
  }

  Future<void> _init() async {
    // Listen to connectivity changes and process queue when online
    _connectivityService.connectivityStream.listen((isOnline) {
      if (isOnline) {
        processQueue();
      }
    });
  }

  Future<void> addToQueue(SyncAction action) async {
    try {
      final box = await Hive.openBox(_queueBoxName);
      await box.put(action.id, jsonEncode(action.toJson()));
      await box.close();
      print('📦 [SYNC] Action queued: ${action.type} (${action.id})');
    } catch (e) {
      print('Error adding to sync queue: $e');
    }
  }

  Future<void> removeFromQueue(String actionId) async {
    try {
      final box = await Hive.openBox(_queueBoxName);
      await box.delete(actionId);
      await box.close();
    } catch (e) {
      print('Error removing from sync queue: $e');
    }
  }

  Future<List<SyncAction>> getQueuedActions() async {
    try {
      final box = await Hive.openBox(_queueBoxName);
      final actions = <SyncAction>[];

      for (var key in box.keys) {
        try {
          final jsonString = box.get(key) as String?;
          if (jsonString != null) {
            final json = jsonDecode(jsonString) as Map<String, dynamic>;
            actions.add(SyncAction.fromJson(json));
          }
        } catch (e) {
          print('Error parsing queued action: $e');
        }
      }

      await box.close();
      return actions;
    } catch (e) {
      print('Error getting queued actions: $e');
      return [];
    }
  }

  Future<void> processQueue() async {
    if (!_connectivityService.isOnline) {
      print('📦 [SYNC] Skipping queue processing - offline');
      return;
    }

    print('📦 [SYNC] Processing queue...');
    final actions = await getQueuedActions();

    if (actions.isEmpty) {
      print('📦 [SYNC] Queue is empty');
      return;
    }

    // Sort by timestamp (oldest first)
    actions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (var action in actions) {
      try {
        final success = await _executeAction(action);

        if (success) {
          await removeFromQueue(action.id);
          print('✅ [SYNC] Action synced: ${action.type} (${action.id})');
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
            print(
              '❌ [SYNC] Action failed after max retries: ${action.type} (${action.id})',
            );
          } else {
            // Update retry count
            await addToQueue(updatedAction);
            print(
              '🔄 [SYNC] Action retry queued: ${action.type} (${action.id}) - Retry ${updatedAction.retryCount}/$_maxRetries',
            );
          }
        }
      } catch (e) {
        print('❌ [SYNC] Error processing action ${action.id}: $e');

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
    } catch (e) {
      print('Error executing sync action: $e');
      return false;
    }
  }

  Future<void> clearQueue() async {
    try {
      await Hive.deleteBoxFromDisk(_queueBoxName);
      print('📦 [SYNC] Queue cleared');
    } catch (e) {
      print('Error clearing sync queue: $e');
    }
  }

  Future<int> getQueueSize() async {
    final actions = await getQueuedActions();
    return actions.length;
  }
}
