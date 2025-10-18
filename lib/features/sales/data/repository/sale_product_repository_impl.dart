import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/sales/data/datasources/sale_products_data_source.dart';
import 'package:compareitr/features/sales/domain/entity/sale_products_entity.dart';
import 'package:compareitr/features/sales/domain/repository/sale_product_repository.dart';
import 'package:compareitr/core/services/cache_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fpdart/src/either.dart';

class SaleProductRepositoryImpl implements SaleProductRepository {
  final SaleProductRemoteDataSource remoteDataSource;

  SaleProductRepositoryImpl(this.remoteDataSource);
  @override
  Future<Either<Failure, List<SaleProductsEntity>>> getSaleProducts() async {
    try {
      // First, check for cached sale products
      final box = Hive.box('recently_viewed'); // Use the same box as other cached data
      final cacheKey = 'sale_products';
      final cachedData = box.get(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final saleEntities = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return SaleProductsEntity(
            storeName: itemData['storeName'],
            image: itemData['image'],
            name: itemData['name'],
            description: itemData['description'],
            price: itemData['price'].toDouble(),
            oldprice: itemData['oldprice'].toDouble(),
            measure: itemData['measure'],
            save: itemData['save'].toDouble(),
            startDate: itemData['startDate'],
            endDate: itemData['endDate'],
          );
        }).toList();
        
        if (saleEntities.isNotEmpty) {
          print('✅ Using cached sale products (${saleEntities.length} items)');
          
          // If offline, always use cached data
          if (CacheManager.isOffline) {
            return right(saleEntities);
          }
          
          // If online, continue to fetch fresh data below
        }
      }

      // If offline and no cached sale products, return error
      if (CacheManager.isOffline) {
        return left(Failure('You\'re offline and no cached sale products available'));
      }

      // Fetch sale products from the remote data source
      final saleProducts = await remoteDataSource.getSaleProducts();

      // Convert SaleProductModel list to SaleProductsEntity list
      final saleEntities = saleProducts.map((model) {
        return SaleProductsEntity(
          storeName: model.storeName,
          image: model.image,
          name: model.name,
          description: model.description,
          price: model.price,
          oldprice: model.oldprice,
          measure: model.measure,
          save: model.save,
          startDate: model.startDate,
          endDate: model.endDate,
        );
      }).toList();

      // Cache the fresh data
      final cacheData = saleEntities.map((item) => {
        'storeName': item.storeName,
        'image': item.image,
        'name': item.name,
        'description': item.description,
        'price': item.price,
        'oldprice': item.oldprice,
        'measure': item.measure,
        'save': item.save,
        'startDate': item.startDate,
        'endDate': item.endDate,
      }).toList();
      
      print('🔍 Repository: Caching sale products data: ${cacheData.length} items');
      if (cacheData.isNotEmpty) {
        print('🔍 Repository: First cached sale product: ${cacheData.first}');
      }
      
      box.put(cacheKey, cacheData);
      
      // Store sale product images in Hive for offline use (non-blocking)
      _storeSaleProductImagesInHive(saleEntities);
      
      print('✅ Sale products: Cached ${saleEntities.length} items');
      return right(saleEntities);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure('Unexpected error: $e'));
    }
  }

  // Store sale product images as base64 in Hive for offline persistence
  Future<void> _storeSaleProductImagesInHive(List<SaleProductsEntity> saleProducts) async {
    try {
      final box = Hive.box('recently_viewed');
      
      for (final item in saleProducts) {
        final imageUrl = item.image;
        
        if (imageUrl?.isNotEmpty == true) {
          try {
            // Download the image and convert to base64
            final response = await http.get(Uri.parse(imageUrl!));
            if (response.statusCode == 200) {
              final base64Image = base64Encode(response.bodyBytes);
              final imageKey = 'saleProductImage_${item.name.hashCode}';
              await box.put(imageKey, base64Image);
              print('💾 Stored sale product image: ${item.name}');
            }
          } catch (e) {
            print('❌ Failed to store sale product image ${item.name}: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Error storing sale product images in Hive: $e');
    }
  }
}
