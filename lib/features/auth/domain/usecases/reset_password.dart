import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class ResetPassword implements UseCase<void, ResetPasswordParams> {
  final AuthRepository authRepository;

  const ResetPassword(this.authRepository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await authRepository.resetPassword(params.token, params.newPassword);
  }
}

class ResetPasswordParams {
  final String token;
  final String newPassword;

  ResetPasswordParams({required this.token, required this.newPassword});
} 