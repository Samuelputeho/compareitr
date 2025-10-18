import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/common/network/network_connection.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:compareitr/features/order/data/datasources/order_remote_data_source.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/domain/repositories/order_repository.dart';
import 'package:compareitr/features/order/data/models/order_model.dart';
import 'package:fpdart/fpdart.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final ConnectionChecker connectionChecker;

  OrderRepositoryImpl(this.remoteDataSource, this.connectionChecker);

  @override
  Future<Either<Failure, void>> createOrder(OrderEntity order) async {
    try {
      if (!await connectionChecker.isConnected) {
        return left(Failure('No Internet Connection'));
      }

      final orderModel = OrderModel(
        orderId: order.orderId,
        orderNumber: order.orderNumber,
        userId: order.userId,
        items: order.items,
        subtotal: order.subtotal,
        deliveryFee: order.deliveryFee,
        totalAmount: order.totalAmount,
        orderDate: order.orderDate,
        deliveryAddress: order.deliveryAddress,
        orderStatus: order.orderStatus,
        paymentMethod: order.paymentMethod,
      );

      await remoteDataSource.createOrder(orderModel);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getUserOrders(String userId) async {
    try {
      // First, check for cached orders
      final box = Hive.box('recently_viewed'); // Use the same box as other cached data
      final cacheKey = 'orders_$userId';
      final cachedData = box.get(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final orders = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return OrderModel.fromJson(itemData);
        }).toList();
        
        if (orders.isNotEmpty) {
          print('✅ Using cached orders (${orders.length} orders)');
          
          // If offline, always use cached data
          if (CacheManager.isOffline) {
            return right(orders);
          }
          
          // If online, continue to fetch fresh data below
        }
      }

      // If offline and no cached orders, return error
      if (CacheManager.isOffline) {
        return left(Failure('You\'re offline and no cached orders available'));
      }

      if (!await connectionChecker.isConnected) {
        return left(Failure('No Internet Connection'));
      }

      final orderModels = await remoteDataSource.getUserOrders(userId);
      
      // Cache the fresh data
      final cacheData = orderModels.map((order) => order.toJson()).toList();
      
      print('🔍 Repository: Caching orders data: ${cacheData.length} items');
      if (cacheData.isNotEmpty) {
        print('🔍 Repository: First cached order: ${cacheData.first}');
      }
      
      box.put(cacheKey, cacheData);
      
      // Store order item images in Hive for offline use (non-blocking)
      _storeOrderImagesInHive(orderModels);
      
      print('✅ Orders: Cached ${orderModels.length} orders');
      return right(orderModels);
    } on ServerException catch (e) {
      // If server error, try to use cached data as fallback
      final box = Hive.box('recently_viewed');
      final cacheKey = 'orders_$userId';
      final cachedData = box.get(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> cachedItems = List<dynamic>.from(cachedData);
        final orders = cachedItems.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return OrderModel.fromJson(itemData);
        }).toList();
        
        if (orders.isNotEmpty) {
          print('✅ Server error, using cached orders: ${e.message}');
          return right(orders);
        }
      }
      return left(Failure(e.message));
    } catch (e) {
      // Check if it's a network-related error
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('socket') || errorMessage.contains('network') || errorMessage.contains('client')) {
        return left(Failure('Network connection error. Please check your internet connection.'));
      }
      return left(Failure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrderById(String orderId) async {
    try {
      if (!await connectionChecker.isConnected) {
        return left(Failure('No Internet Connection'));
      }

      final orderModel = await remoteDataSource.getOrderById(orderId);
      return right(orderModel);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(String orderId) async {
    try {
      if (!await connectionChecker.isConnected) {
        return left(Failure('No Internet Connection'));
      }

      await remoteDataSource.cancelOrder(orderId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      if (!await connectionChecker.isConnected) {
        return left(Failure('No Internet Connection'));
      }

      await remoteDataSource.updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  // Store order item images as base64 in Hive for offline persistence
  Future<void> _storeOrderImagesInHive(List<OrderModel> orders) async {
    try {
      final box = Hive.box('recently_viewed');
      
      for (final order in orders) {
        for (final item in order.items) {
          final imageUrl = item.imageUrl;
          
          if (imageUrl.isNotEmpty) {
            try {
              // Download the image and convert to base64
              final response = await http.get(Uri.parse(imageUrl));
              if (response.statusCode == 200) {
                final base64Image = base64Encode(response.bodyBytes);
                final imageKey = 'orderImage_${item.itemName.hashCode}';
                await box.put(imageKey, base64Image);
                print('📦 Stored order item image: ${item.itemName}');
              }
            } catch (e) {
              print('❌ Failed to store order item image ${item.itemName}: $e');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error storing order item images in Hive: $e');
    }
  }
}
