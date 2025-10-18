import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class VerifyOTPAndResetPassword implements UseCase<void, VerifyOTPAndResetPasswordParams> {
  final AuthRepository authRepository;

  const VerifyOTPAndResetPassword(this.authRepository);

  @override
  Future<Either<Failure, void>> call(VerifyOTPAndResetPasswordParams params) async {
    return await authRepository.verifyOTPAndResetPassword(
      email: params.email,
      otp: params.otp,
      newPassword: params.newPassword,
    );
  }
}

class VerifyOTPAndResetPasswordParams {
  final String email;
  final String otp;
  final String newPassword;

  VerifyOTPAndResetPasswordParams({
    required this.email,
    required this.otp,
    required this.newPassword,
  });
}


