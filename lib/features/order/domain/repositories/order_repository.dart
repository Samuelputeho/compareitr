import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class OrderRepository {
  /// Create a new order
  Future<Either<Failure, void>> createOrder(OrderEntity order);

  /// Get a list of all orders placed by a specific user
  Future<Either<Failure, List<OrderEntity>>> getUserOrders(String userId);

  /// Get a specific order by its ID
  Future<Either<Failure, OrderEntity>> getOrderById(String orderId);

  /// Cancel an order (if allowed)
  Future<Either<Failure, void>> cancelOrder(String orderId);

  /// Update order status (admin or internal use)
  Future<Either<Failure, void>> updateOrderStatus({
    required String orderId,
    required String status, // e.g. 'processing', 'shipped', 'delivered'
  });
}
