import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/order/domain/entities/order_entity.dart';
import 'package:compareitr/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateOrder implements UseCase<void, CreateOrderParams> {
  final OrderRepository repository;

  const CreateOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(CreateOrderParams params) async {
    return await repository.createOrder(params.order);
  }
}

class CreateOrderParams {
  final OrderEntity order;

  CreateOrderParams({required this.order});
}
