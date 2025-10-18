import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetOrderById implements UseCase<OrderEntity, GetOrderByIdParams> {
  final OrderRepository repository;

  const GetOrderById(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(GetOrderByIdParams params) async {
    return await repository.getOrderById(params.orderId);
  }
}

class GetOrderByIdParams {
  final String orderId;

  GetOrderByIdParams({required this.orderId});
}
