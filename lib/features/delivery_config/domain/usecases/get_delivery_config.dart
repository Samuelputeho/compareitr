import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/delivery_config/domain/entities/delivery_config_entity.dart';
import 'package:compareitr/features/delivery_config/domain/repositories/delivery_config_repository.dart';
import 'package:dartz/dartz.dart';

class GetDeliveryConfig {
  final DeliveryConfigRepository repository;

  GetDeliveryConfig(this.repository);

  Future<Either<Failure, DeliveryConfigEntity>> call() async {
    return await repository.getDeliveryConfig();
  }
}
