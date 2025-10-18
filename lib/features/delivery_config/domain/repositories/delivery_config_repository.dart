import 'package:compareitr/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:compareitr/features/delivery_config/domain/entities/delivery_config_entity.dart';

abstract class DeliveryConfigRepository {
  Future<Either<Failure, DeliveryConfigEntity>> getDeliveryConfig();
}









