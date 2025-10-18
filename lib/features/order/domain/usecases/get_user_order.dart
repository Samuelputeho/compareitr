import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetUserOrders implements UseCase<List<OrderEntity>, GetUserOrdersParams> {
  final OrderRepository repository;

  const GetUserOrders(this.repository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(GetUserOrdersParams params) async {
    return await repository.getUserOrders(params.userId);
  }
}

class GetUserOrdersParams {
  final String userId;

  GetUserOrdersParams({required this.userId});
}
