import 'dart:async';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/features/order/data/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class OrderRemoteDataSource {
  Future<void> createOrder(OrderModel order);
  Future<List<OrderModel>> getUserOrders(String userId);
  Future<OrderModel> getOrderById(String orderId);
  Future<void> cancelOrder(String orderId);
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  });
  Stream<OrderModel> listenToOrderUpdates(String orderId);
}


class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient supabaseClient;
  OrderRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<void> createOrder(OrderModel order) async {
    try {
      final orderJson = order.toJson();
      print('Order JSON: $orderJson'); // Debug log
      await supabaseClient.from('orders').insert(orderJson);
    } catch (e) {
      print('Error creating order: $e'); // Debug log
      throw ServerException('Failed to create order: $e');
    }
  }

  @override
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      print('🔍 Orders: Fetching from remote data source for user: $userId');
      final response = await supabaseClient
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('order_date', ascending: false)
          .timeout(const Duration(seconds: 10)); // Add 10 second timeout
      
      // DEBUG: Print raw response from database
      print('========== DATABASE RESPONSE DEBUG ==========');
      print('Fetching orders for user: $userId');
      print('Number of orders: ${(response as List).length}');
      
      final orders = <OrderModel>[];
      
      for (var i = 0; i < (response as List).length; i++) {
        final orderData = response[i];
        print('--- Order ${i + 1} Raw Data ---');
        print('order_id: ${orderData['order_id']}');
        print('order_status: ${orderData['order_status']}');
        print('driver_id: ${orderData['driver_id']}');
        
        // If order has a driver assigned, fetch driver details from profiles
        if (orderData['driver_id'] != null) {
          try {
            print('Fetching driver profile for ID: ${orderData['driver_id']}');
            final driverProfile = await supabaseClient
                .from('profiles')
                .select('name, phonenumber, propic')
                .eq('id', orderData['driver_id'])
                .single();
            
            print('Driver Profile Found:');
            print('  name: ${driverProfile['name']}');
            print('  phonenumber: ${driverProfile['phonenumber']}');
            print('  propic: ${driverProfile['propic']}');
            
            // Add driver details to order data
            orderData['driver_name'] = driverProfile['name'];
            orderData['driver_phone'] = driverProfile['phonenumber'];
            orderData['driver_profile_pic'] = driverProfile['propic'];
          } catch (e) {
            print('Error fetching driver profile: $e');
            // Continue without driver details if profile fetch fails
          }
        }
        
        orders.add(OrderModel.fromJson(orderData));
      }
      print('==========================================');
      
      print('✅ Orders: Successfully fetched ${orders.length} orders from remote');
      return orders;
    } on PostgrestException catch (e) {
      print('❌ Orders: PostgrestException - ${e.message}');
      throw ServerException('Failed to fetch orders: ${e.message}');
    } on TimeoutException {
      print('❌ Orders: TimeoutException - Request timed out');
      throw ServerException('Request timed out. Please check your internet connection.');
    } catch (e) {
      print('❌ Orders: Unexpected error - $e');
      throw ServerException('Failed to fetch orders: $e');
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select()
          .eq('order_id', orderId)
          .single();
      return OrderModel.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch order: $e');
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      await supabaseClient
          .from('orders')
          .update({'order_status': 'cancelled'})
          .eq('order_id', orderId);
    } catch (e) {
      throw ServerException('Failed to cancel order: $e');
    }
  }

  @override
  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await supabaseClient
          .from('orders')
          .update({'order_status': status})
          .eq('order_id', orderId);
    } catch (e) {
      throw ServerException('Failed to update order status: $e');
    }
  }

  @override
  Stream<OrderModel> listenToOrderUpdates(String orderId) {
    return supabaseClient
        .from('orders')
        .stream(primaryKey: ['order_id'])
        .eq('order_id', orderId)
        .asyncMap((data) async {
          if (data.isEmpty) {
            throw ServerException('Order not found');
          }
          
          final orderData = Map<String, dynamic>.from(data.first);
          
          // If order has a driver assigned, fetch driver details from profiles
          if (orderData['driver_id'] != null) {
            try {
              print('Stream: Fetching driver profile for ID: ${orderData['driver_id']}');
              final driverProfile = await supabaseClient
                  .from('profiles')
                  .select('name, phonenumber, propic')
                  .eq('id', orderData['driver_id'])
                  .single();
              
              print('Stream: Driver Profile Found:');
              print('  name: ${driverProfile['name']}');
              print('  phonenumber: ${driverProfile['phonenumber']}');
              print('  propic: ${driverProfile['propic']}');
              
              // Add driver details to order data
              orderData['driver_name'] = driverProfile['name'];
              orderData['driver_phone'] = driverProfile['phonenumber'];
              orderData['driver_profile_pic'] = driverProfile['propic'];
            } catch (e) {
              print('Stream: Error fetching driver profile: $e');
              // Continue without driver details if profile fetch fails
            }
          }
          
          return OrderModel.fromJson(orderData);
        });
  }
}

