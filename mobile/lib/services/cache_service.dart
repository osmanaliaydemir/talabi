import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:mobile/models/product.dart';
import 'package:mobile/models/vendor.dart';

class CacheService {
  static const String _productsBoxName = 'products_cache';
  static const String _categoriesBoxName = 'categories_cache';
  static const String _vendorsBoxName = 'vendors_cache';
  static const String _profileBoxName = 'profile_cache';

  // Cache TTL: 1 hour for products, 24 hours for categories
  static const Duration _productsTTL = Duration(hours: 1);
  static const Duration _categoriesTTL = Duration(hours: 24);
  static const Duration _vendorsTTL = Duration(hours: 1);
  static const Duration _profileTTL = Duration(hours: 1);

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      // Use initFlutter which handles path_provider internally
      // Delay removed for faster startup - Hive.initFlutter() handles platform channels internally
      await Hive.initFlutter();
      _initialized = true;
      print('✅ [CACHE] Hive initialized successfully');
    } catch (e) {
      print('❌ [CACHE] Error initializing Hive: $e');
      // Don't rethrow - app can still work without cache
      // Cache operations will gracefully fail
      _initialized = false;
    }
  }

  // Products Cache
  Future<void> cacheProducts(List<Product> products) async {
    try {
      final box = await Hive.openBox(_productsBoxName);
      final jsonList = products
          .map(
            (p) => {
              'id': p.id,
              'vendorId': p.vendorId,
              'vendorName': p.vendorName,
              'name': p.name,
              'description': p.description,
              'category': p.category,
              'price': p.price,
              'imageUrl': p.imageUrl,
            },
          )
          .toList();
      await box.put('products', jsonEncode(jsonList));
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
      await box.close();
    } catch (e) {
      print('Error caching products: $e');
    }
  }

  Future<List<Product>?> getCachedProducts() async {
    try {
      final box = await Hive.openBox(_productsBoxName);
      final timestamp = box.get('timestamp') as int?;

      if (timestamp == null) {
        await box.close();
        return null;
      }

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );

      if (cacheAge > _productsTTL) {
        await box.delete('products');
        await box.delete('timestamp');
        await box.close();
        return null;
      }

      final jsonString = box.get('products') as String?;
      await box.close();

      if (jsonString == null) return null;

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      print('Error getting cached products: $e');
      return null;
    }
  }

  // Categories Cache
  Future<void> cacheCategories(List<String> categories) async {
    try {
      final box = await Hive.openBox(_categoriesBoxName);
      await box.put('categories', categories);
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
      await box.close();
    } catch (e) {
      print('Error caching categories: $e');
    }
  }

  Future<List<String>?> getCachedCategories() async {
    try {
      final box = await Hive.openBox(_categoriesBoxName);
      final timestamp = box.get('timestamp') as int?;

      if (timestamp == null) {
        await box.close();
        return null;
      }

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );

      if (cacheAge > _categoriesTTL) {
        await box.delete('categories');
        await box.delete('timestamp');
        await box.close();
        return null;
      }

      final categories = box.get('categories') as List<dynamic>?;
      await box.close();

      if (categories == null) return null;
      return categories.map((e) => e.toString()).toList();
    } catch (e) {
      print('Error getting cached categories: $e');
      return null;
    }
  }

  // Vendors Cache
  Future<void> cacheVendors(List<Vendor> vendors) async {
    try {
      final box = await Hive.openBox(_vendorsBoxName);
      final jsonList = vendors
          .map(
            (v) => {
              'id': v.id,
              'name': v.name,
              'imageUrl': v.imageUrl,
              'address': v.address,
              'city': v.city,
              'rating': v.rating,
              'ratingCount': v.ratingCount,
              'latitude': v.latitude,
              'longitude': v.longitude,
              'distanceInKm': v.distanceInKm,
            },
          )
          .toList();
      await box.put('vendors', jsonEncode(jsonList));
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
      await box.close();
    } catch (e) {
      print('Error caching vendors: $e');
    }
  }

  Future<List<Vendor>?> getCachedVendors() async {
    try {
      final box = await Hive.openBox(_vendorsBoxName);
      final timestamp = box.get('timestamp') as int?;

      if (timestamp == null) {
        await box.close();
        return null;
      }

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );

      if (cacheAge > _vendorsTTL) {
        await box.delete('vendors');
        await box.delete('timestamp');
        await box.close();
        return null;
      }

      final jsonString = box.get('vendors') as String?;
      await box.close();

      if (jsonString == null) return null;

      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      print('Error getting cached vendors: $e');
      return null;
    }
  }

  // Profile Cache
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    try {
      final box = await Hive.openBox(_profileBoxName);
      await box.put('profile', jsonEncode(profile));
      await box.put('timestamp', DateTime.now().millisecondsSinceEpoch);
      await box.close();
    } catch (e) {
      print('Error caching profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final box = await Hive.openBox(_profileBoxName);
      final timestamp = box.get('timestamp') as int?;

      if (timestamp == null) {
        await box.close();
        return null;
      }

      final cacheAge = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(timestamp),
      );

      if (cacheAge > _profileTTL) {
        await box.delete('profile');
        await box.delete('timestamp');
        await box.close();
        return null;
      }

      final jsonString = box.get('profile') as String?;
      await box.close();

      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting cached profile: $e');
      return null;
    }
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    try {
      await Hive.deleteBoxFromDisk(_productsBoxName);
      await Hive.deleteBoxFromDisk(_categoriesBoxName);
      await Hive.deleteBoxFromDisk(_vendorsBoxName);
      await Hive.deleteBoxFromDisk(_profileBoxName);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Get cache size info
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final productsBox = await Hive.openBox(_productsBoxName);
      final categoriesBox = await Hive.openBox(_categoriesBoxName);
      final vendorsBox = await Hive.openBox(_vendorsBoxName);
      final profileBox = await Hive.openBox(_profileBoxName);

      final info = {
        'products': {
          'hasData': productsBox.get('products') != null,
          'timestamp': productsBox.get('timestamp'),
        },
        'categories': {
          'hasData': categoriesBox.get('categories') != null,
          'timestamp': categoriesBox.get('timestamp'),
        },
        'vendors': {
          'hasData': vendorsBox.get('vendors') != null,
          'timestamp': vendorsBox.get('timestamp'),
        },
        'profile': {
          'hasData': profileBox.get('profile') != null,
          'timestamp': profileBox.get('timestamp'),
        },
      };

      await productsBox.close();
      await categoriesBox.close();
      await vendorsBox.close();
      await profileBox.close();

      return info;
    } catch (e) {
      print('Error getting cache info: $e');
      return {};
    }
  }
}
