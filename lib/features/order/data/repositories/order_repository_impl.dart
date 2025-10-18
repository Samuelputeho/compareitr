import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/common/network/network_connection.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/features/order/data/datasources/order_remote_data_source.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/data/models/order_model.dart';
import 'package:compareitr/features/order/domain/repositories/order_repository.dart';
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

      await remoteDataSource.createOrder(order as OrderModel);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getUserOrders(String userId) async {
    try {
      if (!await connectionChecker.isConnected) {
        return left(Failure('No Internet Connection'));
      }

      final orders = await remoteDataSource.getUserOrders(userId);
      return right(orders.map((order) => order as OrderEntity).toList());
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrderById(String orderId) async {
    try {
      if (!await connectionChecker.isConnected) {
        return left(Failure('No Internet Connection'));
      }

      final order = await remoteDataSource.getOrderById(orderId);
      return right(order);
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

      await remoteDataSource.updateOrderStatus(orderId: orderId, status: status);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
