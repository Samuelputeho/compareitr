import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeleteNotificationUseCase implements UseCase<void, String> {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String notificationId) async {
    return await repository.deleteNotification(
      notificationId: notificationId,
    );
  }
}

