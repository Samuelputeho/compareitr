import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/sales/data/datasources/sale_card_remote_data_source.dart';
import 'package:compareitr/features/sales/domain/entity/sale_card_entity.dart';
import 'package:compareitr/features/sales/domain/repository/sale_card_repository.dart';
import 'package:compareitr/core/services/cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fpdart/src/either.dart';

class SaleCardRepositoryImpl implements SaleCardRepository {
  final SaleCardRemoteDataSource remoteDataSource;

  SaleCardRepositoryImpl(this.remoteDataSource);
  @override
  Future<Either<Failure, List<SaleCardEntity>>> getSaleCard() async {
    try {
      // First, check for cached sale cards
      final box = Hive.box('recently_viewed'); // Use the same box as other cached data
      final cacheKey = 'sale_cards';
      final lastSyncKey = 'sale_cards_last_sync';
      final cachedData = box.get(cacheKey);
      final lastSync = box.get(lastSyncKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final saleEntities = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return SaleCardEntity(
            storeName: itemData['storeName'],
            image: itemData['image'],
            startDate: itemData['startDate'],
            endDate: itemData['endDate'],
          );
        }).toList();
        
        if (saleEntities.isNotEmpty) {
          print('✅ Using cached sale cards (${saleEntities.length} items)');
          
          // If offline, always use cached data
          if (CacheManager.isOffline) {
            return right(saleEntities);
          }
          
          // Check if cache is fresh (less than 1 minute old)
          if (lastSync != null) {
            final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
            final now = DateTime.now();
            final difference = now.difference(lastSyncTime);
            
            if (difference.inMinutes < 1) {
              print('🔍 Sale cards cache is fresh (${difference.inSeconds}s old) - using cached data');
              return right(saleEntities);
            } else {
              print('🔍 Sale cards cache is stale (${difference.inMinutes}m old) - fetching fresh data');
            }
          }
        }
      }

      // If offline and no cached sale cards, return error
      if (CacheManager.isOffline) {
        return left(Failure('You\'re offline and no cached sale cards available'));
      }

      // Fetch sale cards from the remote data source
      final saleModels = await remoteDataSource.getSaleCard();

      // Convert SaleCardModel list to SaleCardEntity list
      final saleEntities = saleModels.map((model) {
        return SaleCardEntity(
          storeName: model.storeName,
          image: model.image,
          startDate: model.startDate,
          endDate: model.endDate,
        );
      }).toList();

      // Cache the fresh data
      final cacheData = saleEntities.map((item) => {
        'storeName': item.storeName,
        'image': item.image,
        'startDate': item.startDate,
        'endDate': item.endDate,
      }).toList();
      
      print('🔍 Repository: Caching sale cards data: ${cacheData.length} items');
      if (cacheData.isNotEmpty) {
        print('🔍 Repository: First cached sale card: ${cacheData.first}');
      }
      
      box.put(cacheKey, cacheData);
      box.put(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
      
      // Store sale card images in Hive for offline use (non-blocking)
      _storeSaleCardImagesInHive(saleEntities);
      
      print('✅ Sale cards: Cached ${saleEntities.length} items');
      return right(saleEntities);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure('Unexpected error: $e'));
    }
  }

  // Store sale card images as base64 in Hive for offline persistence
  Future<void> _storeSaleCardImagesInHive(List<SaleCardEntity> saleCards) async {
    try {
      final box = Hive.box('recently_viewed');
      
      for (final item in saleCards) {
        final imageUrl = item.image;
        
        if (imageUrl?.isNotEmpty == true) {
          try {
            // Download the image and convert to base64
            final response = await http.get(Uri.parse(imageUrl!));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              final imageKey = 'saleCardImage_${item.storeName.hashCode}';
              await box.put(imageKey, base64Image);
              print('💾 Stored sale card image: ${item.storeName}');
            }
          } catch (e) {
            print('❌ Failed to store sale card image ${item.storeName}: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error storing sale card images in Hive: $e');
    }
  }
}
