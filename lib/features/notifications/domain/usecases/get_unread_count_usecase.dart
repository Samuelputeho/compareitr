import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/notifications/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetUnreadCountUseCase implements UseCase<int, String> {
  final NotificationRepository repository;

  GetUnreadCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(String userId) async {
    return await repository.getUnreadCount(userId: userId);
  }
}


