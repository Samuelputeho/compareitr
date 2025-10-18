import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:compareitr/core/common/entities/recently_viewed_entity.dart';
import 'package:compareitr/core/common/models/recently_viewed_model.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/recently_viewed/data/datasource/recently_viewed_remote_data_source.dart'; // For connection check
import 'package:compareitr/features/recently_viewed/domain/repository/recent_repo.dart';
import 'package:compareitr/features/sales/presentation/bloc/salecard_bloc.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:fpdart/fpdart.dart'; // Functional programming support
import 'package:uuid/uuid.dart'; // For generating temporary UUIDs
import 'package:hive_flutter/hive_flutter.dart';

class RecentRepoImpl implements RecentRepository {
  final RecentlyViewedRemoteDataSource remoteDataSource;
  static const String _recentItemsKey = 'recent_items';

  RecentRepoImpl(
    this.remoteDataSource,
  );

  @override
  Future<Either<Failure, RecentlyViewedEntity>> addRecentItem({
    required String name,
    required String image,
    required String measure,
    required String shopName,
    required String recentId,
    required double price,
  }) async {
    try {
      final recentlyViewedModel = RecentlyViewedModel(
        id: const Uuid().v4(), // Generate a temporary ID if offline (this will not be used)
        name: name,
        image: image,
        measure: measure,
        shopName: shopName,
        recentId: recentId,
        price: price,
      );

      // Add item to remote data source (no internet check)
      await remoteDataSource.addRecentItem(
        name: name,
        image: image,
        measure: measure,
        shopName: shopName,
        recentId: recentId,
        price: price,
      );

      return right(RecentlyViewedEntity(
        id: recentlyViewedModel.id, // Using the generated ID
        name: name,
        image: image,
        measure: measure,
        shopName: shopName,
        recentId: recentId,
        price: price,
      ));
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(Failure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> removeRecentlyItem(String id) async {
    try {
      // Remove item from remote data source (no internet check)
      await remoteDataSource.removeRecentlyItem(id);

      return right(null); // Void return for success
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(Failure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<RecentlyViewedEntity>>> getRecentItems(String recentId) async {
    try {
      // Check if we have cached data for this user
      final cacheKey = '${_recentItemsKey}_$recentId';
      final box = Hive.box('recently_viewed');
      
      // First, check for cached data (like cart does)
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final recentEntities = cachedItems.map((item) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          final itemData = Map<String, dynamic>.from(item as Map);
          return RecentlyViewedEntity(
            id: itemData['id'],
            name: itemData['name'],
            image: itemData['image'],
            measure: itemData['measure'],
            shopName: itemData['shopName'],
            recentId: itemData['recentId'],
            price: itemData['price'].toDouble(),
          );
        }).toList();
        
        if (recentEntities.isNotEmpty) {
          print('✅ Using cached recent items (${recentEntities.length} items)');
          
          // If offline, always use cached data
          if (CacheManager.isOffline) {
            return right(recentEntities);
          }
          
          // If online, continue to fetch fresh data below (like cart does)
        }
      }

      // If offline and no cached data, return error
      if (CacheManager.isOffline) {
        print('📱 Offline: No cached recent items found for key: $cacheKey');
        return left(Failure('You\'re offline and no cached recent items available'));
      }

      // Online: Fetch from remote and cache the result
      final recentModels = await remoteDataSource.getRecentItems(recentId);

      final recentEntities = recentModels.map((model) {
        return RecentlyViewedEntity(
          id: model.id,
          name: model.name,
          image: model.image,
          measure: model.measure,
          shopName: model.shopName,
          recentId: model.recentId,
          price: model.price,
        );
      }).toList();

      // Cache the fresh data
      final cacheData = recentEntities.map((entity) => {
        'id': entity.id,
        'name': entity.name,
        'image': entity.image,
        'measure': entity.measure,
        'shopName': entity.shopName,
        'recentId': entity.recentId,
        'price': entity.price,
      }).toList();
      
      box.put(cacheKey, cacheData);
      
      // Store images as base64 in Hive for offline use (non-blocking)
      _storeRecentImagesInHive(recentEntities);
      
      // Verify the data was actually stored
      final storedData = box.get(cacheKey);
      print('🔍 Recent items: Verifying stored data - ${storedData != null ? storedData.length : 0} items for key: $cacheKey');
      print('💾 Cached recent items (${recentEntities.length} items) in Hive');

      return right(recentEntities);
    } on ServerException catch (e) {
      // If server error, try to use cached data as fallback
      final cacheKey = '${_recentItemsKey}_$recentId';
      final box = Hive.box('recently_viewed');
      final cachedData = box.get(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final recentEntities = cachedItems.map((item) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          final itemData = Map<String, dynamic>.from(item as Map);
          return RecentlyViewedEntity(
            id: itemData['id'],
            name: itemData['name'],
            image: itemData['image'],
            measure: itemData['measure'],
            shopName: itemData['shopName'],
            recentId: itemData['recentId'],
            price: itemData['price'].toDouble(),
          );
        }).toList();
        
        print('🔄 Server error, using cached recent items: ${e.message}');
        return right(recentEntities);
      }
      
      return left(ServerFailure(e.message));
    } catch (e) {
      // For any other error, try cached data as fallback
      final cacheKey = '${_recentItemsKey}_$recentId';
      final box = Hive.box('recently_viewed');
      final cachedData = box.get(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final recentEntities = cachedItems.map((item) {
          // Convert Map<dynamic, dynamic> to Map<String, dynamic>
          final itemData = Map<String, dynamic>.from(item as Map);
          return RecentlyViewedEntity(
            id: itemData['id'],
            name: itemData['name'],
            image: itemData['image'],
            measure: itemData['measure'],
            shopName: itemData['shopName'],
            recentId: itemData['recentId'],
            price: itemData['price'].toDouble(),
          );
        }).toList();
        
        print('🔄 Network error, using cached recent items: $e');
        return right(recentEntities);
      }
      
      return left(Failure('Unexpected error: $e'));
    }
  }

  // Store recently viewed images as base64 in Hive for offline persistence
  Future<void> _storeRecentImagesInHive(List<RecentlyViewedEntity> recentItems) async {
    try {
      final box = Hive.box('recently_viewed');
      
      for (final item in recentItems) {
        final imageUrl = item.image;
        
        if (imageUrl.isNotEmpty) {
          try {
            // Download the image and convert to base64
            final response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              final imageKey = 'recentImage_${item.name.hashCode}';
              await box.put(imageKey, base64Image);
              print('📸 Stored recent item image: ${item.name}');
            }
          } catch (e) {
            print('❌ Failed to store recent item image ${item.name}: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error storing recent item images in Hive: $e');
    }
  }
}
