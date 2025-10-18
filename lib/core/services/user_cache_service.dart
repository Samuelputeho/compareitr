import 'package:compareitr/core/common/entities/user_entity.dart';
import 'package:compareitr/features/auth/data/models/user_model.dart';
import 'package:compareitr/core/common/entities/shop_entity.dart';
import 'package:compareitr/core/common/models/shop_model.dart';
import 'package:hive/hive.dart';

class UserCacheService {
  static const String _userBoxName = 'user_cache';
  static const String _userKey = 'current_user';
  static const String _shopsKey = 'cached_shops';
  static const String _lastSyncKey = 'last_sync_time';

  static Box? _box;

  // Initialize the cache service
  static Future<void> init() async {
    _box = await Hive.openBox(_userBoxName);
    print('✅ UserCacheService initialized with box: $_userBoxName');
  }

  // Store user data in cache
  static Future<void> cacheUser(UserEntity user) async {
    if (_box == null) {
      await init();
    }
    
    final userMap = {
      'id': user.id,
      'email': user.email,
      'name': user.name,
      'location': user.location,
      'street': user.street,
      'phoneNumber': user.phoneNumber,
      'proPic': user.proPic,
      'cached_at': DateTime.now().millisecondsSinceEpoch,
    };
    
    await _box!.put(_userKey, userMap);
    print('💾 User cached successfully: ${user.name} (Location: ${user.location}, Street: ${user.street})');
  }

  // Retrieve user data from cache
  static UserEntity? getCachedUser() {
    if (_box == null) {
      print('❌ UserCacheService: Box is null');
      return null;
    }
    
    final userMap = _box!.get(_userKey);
    if (userMap == null) {
      print('❌ UserCacheService: No cached user data found');
      return null;
    }
    
    try {
      // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      final userData = Map<String, dynamic>.from(userMap as Map);
      final user = UserModel.fromJson(userData);
      print('✅ UserCacheService: Retrieved cached user: ${user.name}');
      return user;
    } catch (e) {
      print('❌ UserCacheService: Error parsing cached user: $e');
      return null;
    }
  }

  // Clear cached user data
  static Future<void> clearCache() async {
    if (_box != null) {
      await _box!.delete(_userKey);
      await _box!.delete(_shopsKey);
      await _box!.delete(_lastSyncKey);
      print('🗑️ Cleared all user cache data');
    }
  }

  // Check if user data is cached
  static bool hasCachedUser() {
    if (_box == null) return false;
    return _box!.containsKey(_userKey);
  }

  // Check if user cache is fresh (less than 24 hours old)
  static bool isUserCacheFresh() {
    if (_box == null) return false;
    
    final userMap = _box!.get(_userKey);
    if (userMap == null || userMap is! Map<String, dynamic>) return false;
    
    final cachedAt = userMap['cached_at'];
    if (cachedAt == null) return false;
    
    final lastCacheTime = DateTime.fromMillisecondsSinceEpoch(cachedAt);
    final now = DateTime.now();
    final difference = now.difference(lastCacheTime);
    
    return difference.inHours < 24; // User cache is fresh for 24 hours
  }

  // Cache shops data
  static Future<void> cacheShops(List<ShopEntity> shops) async {
    if (_box == null) {
      await init();
    }
    
    final shopsJson = shops.map((shop) => {
      'id': shop.id,
      'shopName': shop.shopName,
      'shopLogoUrl': shop.shopLogoUrl,
      'shopType': shop.shopType,
      'service_fee_percentage': shop.serviceFeePercentage, // Include service fee percentage
      // Flatten operating hours to avoid complex nested structure issues
      'operating_hours': shop.operatingHours != null ? 
        shop.operatingHours!.weeklyHours.entries.map((entry) => {
          'day': entry.key,
          'open': entry.value.openTime,
          'close': entry.value.closeTime,
          'is_open': entry.value.isOpen,
        }).toList() : null,
    }).toList();
    
    
    await _box!.put(_shopsKey, shopsJson);
    await _box!.put(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
    print('💾 Shops cached successfully: ${shops.length} shops');
    
    // Debug: Check operating hours in cached data
    for (int i = 0; i < shopsJson.length && i < 3; i++) {
      final shop = shopsJson[i];
      print('🔍 Cached shop ${i + 1}: ${shop['shopName']} - Operating hours: ${shop['operating_hours'] != null ? "Present" : "NULL"}');
    }
  }

  // Get cached shops
  static List<ShopEntity>? getCachedShops() {
    if (_box == null) {
      print('❌ UserCacheService: Box is null for shops');
      return null;
    }
    
    final shopsJson = _box!.get(_shopsKey);
    if (shopsJson == null) {
      print('❌ UserCacheService: No cached shops data found');
      return null;
    }
    
    try {
      final List<dynamic> shopsList = List<dynamic>.from(shopsJson);
      
      final shops = shopsList.map((shopJson) {
        
        // Convert Map<dynamic, dynamic> to Map<String, dynamic>
        final shopData = Map<String, dynamic>.from(shopJson as Map<dynamic, dynamic>);
        
        // Reconstruct operating hours from flattened structure
        if (shopData['operating_hours'] != null) {
          final List<dynamic> hoursList = List<dynamic>.from(shopData['operating_hours']);
          final Map<String, dynamic> weeklyHours = {};
          
          for (var hourData in hoursList) {
            final hourMap = Map<String, dynamic>.from(hourData as Map);
            weeklyHours[hourMap['day']] = {
              'open': hourMap['open'],
              'close': hourMap['close'],
              'is_open': hourMap['is_open'],
            };
          }
          
          // Fix: Set operating_hours directly to weeklyHours (not nested under 'weeklyHours')
          // This matches what OperatingHoursModel.fromJson() expects
          shopData['operating_hours'] = weeklyHours;
        }
        
        
        return ShopModel.fromJson(shopData);
      }).toList();
      print('✅ UserCacheService: Retrieved cached shops: ${shops.length} shops');
      
      // Debug: Check operating hours in retrieved data
      for (int i = 0; i < shops.length && i < 3; i++) {
        final shop = shops[i];
        print('🔍 Retrieved shop ${i + 1}: ${shop.shopName} - Operating hours: ${shop.operatingHours != null ? "Present" : "NULL"}');
        if (shop.operatingHours != null) {
          print('   - Monday: ${shop.operatingHours!.weeklyHours['monday']?.openTime}-${shop.operatingHours!.weeklyHours['monday']?.closeTime}');
        }
      }
      
      return shops;
    } catch (e) {
      print('❌ UserCacheService: Error parsing cached shops: $e');
      return null;
    }
  }

  // Check if shops are cached
  static bool hasCachedShops() {
    if (_box == null) return false;
    return _box!.containsKey(_shopsKey);
  }

  // Get last sync time
  static DateTime? getLastSyncTime() {
    if (_box == null) return null;
    
    final timestamp = _box!.get(_lastSyncKey);
    if (timestamp == null) return null;
    
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  // Check if cache is fresh (less than 1 minute old)
  static bool isCacheFresh() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    return difference.inMinutes < 1; // Cache is fresh for 1 minute
  }

  // Clear shops cache
  static Future<void> clearShopsCache() async {
    if (_box != null) {
      await _box!.delete(_shopsKey);
      await _box!.delete(_lastSyncKey);
    }
  }

  // Get cache info for debugging
  static Map<String, dynamic> getCacheInfo() {
    if (_box == null) return {'status': 'not_initialized'};
    
    return {
      'status': 'initialized',
      'has_user': hasCachedUser(),
      'has_shops': hasCachedShops(),
      'last_sync': getLastSyncTime()?.toIso8601String(),
      'is_fresh': isCacheFresh(),
      'box_size': _box!.length,
    };
  }

  // Debug method to check what's stored in all Hive boxes
  static void debugCacheContents() {
    print('🔍 === DEBUGGING CACHE CONTENTS ===');
    
    // Check user cache box
    if (_box != null) {
      print('📦 User Cache Box Contents:');
      print('  - User data: ${_box!.containsKey(_userKey) ? "✅ Present" : "❌ Missing"}');
      print('  - Shops data: ${_box!.containsKey(_shopsKey) ? "✅ Present" : "❌ Missing"}');
      print('  - Last sync: ${_box!.containsKey(_lastSyncKey) ? "✅ Present" : "❌ Missing"}');
      
      if (_box!.containsKey(_shopsKey)) {
        final shopsData = _box!.get(_shopsKey);
        print('  - Shops count: ${shopsData is List ? shopsData.length : "Invalid"}');
      }
    }
    
          // Check shops box
          final shopsBox = Hive.box('shops');
          print('📦 Shops Box Contents:');
          print('  - Card swiper: ${shopsBox.containsKey('cardSwiperPictures') ? "✅ Present" : "❌ Missing"}');
          print('  - Categories: ${shopsBox.containsKey('categories') ? "✅ Present" : "❌ Missing"}');
          print('  - Products: ${shopsBox.containsKey('products') ? "✅ Present" : "❌ Missing"}');
          
          if (shopsBox.containsKey('cardSwiperPictures')) {
            final cardData = shopsBox.get('cardSwiperPictures');
            print('  - Card swiper count: ${cardData is List ? cardData.length : "Invalid"}');
          }
          
          if (shopsBox.containsKey('categories')) {
            final categoriesData = shopsBox.get('categories');
            print('  - Categories count: ${categoriesData is List ? categoriesData.length : "Invalid"}');
          }
          
          if (shopsBox.containsKey('products')) {
            final productsData = shopsBox.get('products');
            print('  - Products count: ${productsData is List ? productsData.length : "Invalid"}');
          }
          
          // Check for saved items in recently_viewed box
          final recentBox = Hive.box('recently_viewed');
          final savedKeys = recentBox.keys.where((key) => key.toString().startsWith('saved_items_')).toList();
          print('  - Saved items: ${savedKeys.isNotEmpty ? "✅ Present" : "❌ Missing"}');
          if (savedKeys.isNotEmpty) {
            for (final key in savedKeys) {
              final savedData = recentBox.get(key);
              print('    - $key: ${savedData is List ? savedData.length : "Invalid"} items');
            }
          }
          
          // Check for orders in recently_viewed box
          final orderKeys = recentBox.keys.where((key) => key.toString().startsWith('orders_')).toList();
          print('  - Orders: ${orderKeys.isNotEmpty ? "✅ Present" : "❌ Missing"}');
          if (orderKeys.isNotEmpty) {
            for (final key in orderKeys) {
              final orderData = recentBox.get(key);
              print('    - $key: ${orderData is List ? orderData.length : "Invalid"} items');
            }
          }
          
          // Check for notifications in recently_viewed box
          final notificationKeys = recentBox.keys.where((key) => key.toString().startsWith('notifications_')).toList();
          print('  - Notifications: ${notificationKeys.isNotEmpty ? "✅ Present" : "❌ Missing"}');
          if (notificationKeys.isNotEmpty) {
            for (final key in notificationKeys) {
              final notificationData = recentBox.get(key);
              print('    - $key: ${notificationData is List ? notificationData.length : "Invalid"} items');
            }
          }
          
          // Check for cart items in recently_viewed box
          final cartKeys = recentBox.keys.where((key) => key.toString().startsWith('cart_items_')).toList();
          print('  - Cart items: ${cartKeys.isNotEmpty ? "✅ Present" : "❌ Missing"}');
          if (cartKeys.isNotEmpty) {
            for (final key in cartKeys) {
              final cartData = recentBox.get(key);
              print('    - $key: ${cartData is List ? cartData.length : "Invalid"} items');
            }
          }
    
    // Check recently viewed box
    print('📦 Recently Viewed Box Contents:');
    final keys = recentBox.keys.toList();
    print('  - Total keys: ${keys.length}');
    for (final key in keys) {
      final data = recentBox.get(key);
      if (data is List) {
        print('  - $key: ${data.length} items');
      } else {
        print('  - $key: Invalid data type');
      }
    }
    
    print('🔍 === END CACHE DEBUG ===');
  }

}
