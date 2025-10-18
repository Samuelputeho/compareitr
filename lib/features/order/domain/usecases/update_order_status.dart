import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateOrderStatus implements UseCase<void, UpdateOrderStatusParams> {
  final OrderRepository repository;

  const UpdateOrderStatus(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateOrderStatusParams params) async {
    return await repository.updateOrderStatus(
      orderId: params.orderId,
      status: params.status,
    );
  }
}

class UpdateOrderStatusParams {
  final String orderId;
  final String status;

  UpdateOrderStatusParams({required this.orderId, required this.status});
}
