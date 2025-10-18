import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarkAsReadUseCase implements UseCase<void, String> {
  final NotificationRepository repository;

  MarkAsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String notificationId) async {
    return await repository.markAsRead(notificationId: notificationId);
  }
}


