import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/features/delivery_config/data/datasources/delivery_config_remote_data_source.dart';
import 'package:compareitr/features/delivery_config/domain/entities/delivery_config_entity.dart';
import 'package:compareitr/features/delivery_config/domain/repositories/delivery_config_repository.dart';
import 'package:dartz/dartz.dart';

class DeliveryConfigRepositoryImpl implements DeliveryConfigRepository {
  final DeliveryConfigRemoteDataSource remoteDataSource;

  DeliveryConfigRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, DeliveryConfigEntity>> getDeliveryConfig() async {
    try {
      final configModel = await remoteDataSource.getDeliveryConfig();
      return Right(configModel.toEntity());
    } on ServerException catch (e) {
      return Left(Failure('Server error occurred: ${e.message}'));
    } catch (e) {
      return Left(Failure('An unexpected error occurred: $e'));
    }
  }
}
