import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class SaveDeviceTokenUseCase
    implements UseCase<void, SaveDeviceTokenParams> {
  final NotificationRepository repository;

  SaveDeviceTokenUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SaveDeviceTokenParams params) async {
    return await repository.saveDeviceToken(
      userId: params.userId,
      token: params.token,
      platform: params.platform,
    );
  }
}

class SaveDeviceTokenParams {
  final String userId;
  final String token;
  final String platform;

  SaveDeviceTokenParams({
    required this.userId,
    required this.token,
    required this.platform,
  });
}

