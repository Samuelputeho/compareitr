import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:compareitr/core/common/entities/category_entity.dart';
import 'package:compareitr/core/common/entities/product_entity.dart';
import 'package:compareitr/core/common/entities/shop_entity.dart';
import 'package:compareitr/core/common/models/branch_model.dart';
import 'package:compareitr/core/common/models/category_model.dart';
import 'package:compareitr/core/common/models/product_model.dart';
import 'package:compareitr/core/services/user_cache_service.dart';
import 'package:compareitr/core/services/image_cache_service.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repository/repo.dart';
import '../datasources/shops_remote_datasource.dart';

class ShopsRepositoryImpl implements ShopsRepository {
  final ShopsRemoteDataSource remoteDataSource;

  ShopsRepositoryImpl(
    this.remoteDataSource,
  );

  @override
  Future<Either<Failure, List<ShopEntity>>> getAllShops() async {
    try {
      print('🔍 ShopsRepository: Starting getAllShops - isOffline: ${CacheManager.isOffline}');
      print('🔍 ShopsRepository: Cache info: ${UserCacheService.getCacheInfo()}');
      
      // First, always check for cached shops (whether online or offline)
      if (UserCacheService.hasCachedShops()) {
        print('🔍 ShopsRepository: Found cached shops, retrieving...');
        final cachedShops = UserCacheService.getCachedShops();
        if (cachedShops != null && cachedShops.isNotEmpty) {
          print('✅ ShopsRepository: Using cached shops (${cachedShops.length} shops)');
          
          // If offline, always use cached data
          if (CacheManager.isOffline) {
            print('🔍 ShopsRepository: Offline mode - returning cached shops');
            return right(cachedShops);
          }
          
          // If online and cache is fresh, use cached data
          if (UserCacheService.isCacheFresh()) {
            print('🔍 ShopsRepository: Cache is fresh - returning cached shops');
            return right(cachedShops);
          }
          
          print('🔍 ShopsRepository: Cache is stale, fetching fresh data...');
          // If online but cache is stale, continue to fetch fresh data below
        } else {
          print('❌ ShopsRepository: Cached shops is null or empty');
        }
      } else {
        print('❌ ShopsRepository: No cached shops found');
      }

      // If offline and no cached shops, return error
      if (CacheManager.isOffline) {
        print('❌ ShopsRepository: Offline and no cached shops available');
        return left(Failure('You\'re offline and no cached shops available'));
      }

      // Online: Fetch from remote and cache the result
      final shops = await remoteDataSource.getAllShops();
      print('Fetched shops from remote: ${shops.length} shops');
      
      // Cache the fresh data
      print('🔍 ShopsRepository: Caching ${shops.length} shops...');
      await UserCacheService.cacheShops(shops);
      
      // Verify shops were cached
      final cachedShops = UserCacheService.getCachedShops();
      print('🔍 ShopsRepository: Verifying cached data - ${cachedShops?.length ?? 0} shops cached');
      print('🔍 ShopsRepository: Cache info after caching: ${UserCacheService.getCacheInfo()}');
      
      // Pre-cache shop images in the background
      ImageCacheService.preCacheShopImages(shops);
      
      // Store shop logos in Hive for offline use (non-blocking)
      _storeShopLogosInHive(shops);
      
      return right(shops);
    } on ServerException catch (e) {
      // If server error, try to use cached data as fallback
      final cachedShops = UserCacheService.getCachedShops();
      if (cachedShops != null && cachedShops.isNotEmpty) {
        print('Server error, using cached shops: ${e.message}');
        return right(cachedShops);
      }
      return left(Failure(e.message));
    } catch (e) {
      // For any other error (including client exceptions), try cached data as fallback
      final cachedShops = UserCacheService.getCachedShops();
      if (cachedShops != null && cachedShops.isNotEmpty) {
        print('Network error, using cached shops: $e');
        return right(cachedShops);
      }
      
      // Check if it's a network-related error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('socket') || errorMessage.contains('network') || errorMessage.contains('client')) {
        return left(Failure('Network connection error. Please check your internet connection.'));
      }
      
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CategoryEntity>>> getAllCategories() async {
    try {
      // First, check for cached categories
      final box = Hive.box('shops');
      final cachedData = box.get('categories');
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final categories = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return CategoryModel.fromJson(itemData);
        }).toList();
        
        if (categories.isNotEmpty) {
          print('✅ Using cached categories (${categories.length} categories)');
          
          // If offline, always use cached data
          if (CacheManager.isOffline) {
            return right(categories);
          }
          
          // If online, continue to fetch fresh data below
        }
      }

      // If offline and no cached categories, return error
      if (CacheManager.isOffline) {
        return left(Failure('You\'re offline and no cached categories available'));
      }

      // Fetch categories from the remote data source
      final categories = await remoteDataSource.getAllCategories();
      
      // Cache the fresh data
      final cacheData = categories.map((category) => {
        'id': category.id,
        'category_name': category.categoryName,  // Use the correct property name for fromJson
        'shopName': category.shopName,
        'category_url': category.categoryUrl,    // Use the correct property name for fromJson
      }).toList();
      
      print('🔍 Repository: Caching categories data: ${cacheData.length} items');
      if (cacheData.isNotEmpty) {
        print('🔍 Repository: First cached category: ${cacheData.first}');
      }
      
      box.put('categories', cacheData);
      
      // Store category images in Hive for offline use (non-blocking)
      _storeCategoryImagesInHive(categories);
      
      print('✅ Categories: Cached ${categories.length} categories');
      return right(categories);
    } on ServerException catch (e) {
      // If server error, try to use cached data as fallback
      if (CacheManager.isOffline) {
        return left(Failure('You\'re offline and no cached categories available'));
      }
      return left(Failure(e.message));
    } catch (e) {
      // Check if it's a network-related error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('socket') || errorMessage.contains('network') || errorMessage.contains('client')) {
        return left(Failure('Network connection error. Please check your internet connection.'));
      }
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductEntity>>> getAllProducts() async {
    try {
      // First, check for cached products with 1-minute expiry (like shops)
      final box = Hive.box('shops');
      final cachedData = box.get('products');
      final lastSyncKey = 'products_last_sync';
      final lastSync = box.get(lastSyncKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final products = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return ProductModel.fromJson(itemData);
        }).toList();
        
        if (products.isNotEmpty) {
          print('✅ Using cached products (${products.length} products)');
          
          // If offline, always use cached data
          if (CacheManager.isOffline) {
            return right(products);
          }
          
          // Check if cache is fresh (less than 1 minute old)
          if (lastSync != null) {
            final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
            final now = DateTime.now();
            final difference = now.difference(lastSyncTime);
            
            if (difference.inMinutes < 1) {
              print('🔍 Products cache is fresh (${difference.inSeconds}s old) - using cached data');
              return right(products);
            } else {
              print('🔍 Products cache is stale (${difference.inMinutes}m old) - fetching fresh data');
            }
          }
        }
      }

      // If offline and no cached products, return error
      if (CacheManager.isOffline) {
        return left(Failure('You\'re offline and no cached products available'));
      }

      // Fetch products from the remote data source
      final products = await remoteDataSource.getAllProducts();
      
      // Cache the fresh data
      final cacheData = products.map((product) => {
        'id': product.id,
        'name': product.name,
        'price': product.price,
        'measure': product.measure,
        'imageUrl': product.imageUrl,
        'shopName': product.shopName,
        'category': product.category,
        'description': product.description,
        'salePrice': product.salePrice,
        'subCategory': product.subCategory,
      }).toList();
      
      print('🔍 Repository: Caching products data: ${cacheData.length} items');
      if (cacheData.isNotEmpty) {
        print('🔍 Repository: First cached product: ${cacheData.first}');
      }
      
      // Store products and timestamp
      box.put('products', cacheData);
      box.put(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      
      // Pre-cache product images in the background
      ImageCacheService.preCacheProductImages(products);
      
      // Store product images in Hive for offline use (non-blocking)
      _storeProductImagesInHive(products);
      
      print('✅ Products: Cached ${products.length} products');
      return right(products);
    } on ServerException catch (e) {
      // If server error, try to use cached data as fallback
      if (CacheManager.isOffline) {
        return left(Failure('You\'re offline and no cached products available'));
      }
      return left(Failure(e.message));
    } catch (e) {
      // Check if it's a network-related error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('socket') || errorMessage.contains('network') || errorMessage.contains('client')) {
        return left(Failure('Network connection error. Please check your internet connection.'));
      }
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BranchModel>>> getBranchesByShopId(String shopId) async {
    try {
      // Fetch branches from the remote data source
      final branches = await remoteDataSource.getBranchesByShopId(shopId);
      return right(branches);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Store shop logos as base64 in Hive for offline persistence
  Future<void> _storeShopLogosInHive(List<ShopEntity> shops) async {
    try {
      final box = Hive.box('shops');
      
      for (int i = 0; i < shops.length; i++) {
        final shop = shops[i];
        final logoUrl = shop.shopLogoUrl;
        
        if (logoUrl.isNotEmpty) {
          try {
            // Download the logo and convert to base64
            final response = await http.get(Uri.parse(logoUrl));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              final imageKey = 'shopLogo_$i';
              await box.put(imageKey, base64Image);
              print('🏪 Stored shop logo $i in Hive');
            }
          } catch (e) {
            print('❌ Failed to store shop logo $i: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error storing shop logos in Hive: $e');
    }
  }

  // Store category images as base64 in Hive for offline persistence
  Future<void> _storeCategoryImagesInHive(List<CategoryEntity> categories) async {
    try {
      final box = Hive.box('shops');
      
      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        final imageUrl = category.categoryUrl;
        
        if (imageUrl.isNotEmpty) {
          try {
            // Download the image and convert to base64
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              final imageKey = 'categoryImage_$i';
              await box.put(imageKey, base64Image);
              print('📂 Stored category image $i in Hive');
            }
          } catch (e) {
            print('❌ Failed to store category image $i: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error storing category images in Hive: $e');
    }
  }

  // Store product images as base64 in Hive for offline persistence
  Future<void> _storeProductImagesInHive(List<ProductEntity> products) async {
    try {
      final box = Hive.box('shops');
      
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final imageUrl = product.imageUrl;
        
        if (imageUrl.isNotEmpty) {
          try {
            // Download the image and convert to base64
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              final imageKey = 'productImage_$i';
              await box.put(imageKey, base64Image);
              print('📦 Stored product image $i in Hive');
            }
          } catch (e) {
            print('❌ Failed to store product image $i: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error storing product images in Hive: $e');
    }
  }
}
