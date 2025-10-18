import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class CancelOrder implements UseCase<void, CancelOrderParams> {
  final OrderRepository repository;

  const CancelOrder(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelOrderParams params) async {
    return await repository.cancelOrder(params.orderId);
  }
}

class CancelOrderParams {
  final String orderId;

  CancelOrderParams({required this.orderId});
}
