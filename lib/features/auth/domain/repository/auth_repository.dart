import 'dart:io';

import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/common/entities/user_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository {
  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({
    required String name,
    required String street,
    required String location,
    required int phoneNumber,
    required String email,
    required String password,
  });
  Future<Either<Failure, UserEntity>> logInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> currentUser();
  Future<Either<Failure, void>> logout();

  // New method to update user profile
  Future<Either<Failure, void>> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    required String street,
    required String location,
    required int phoneNumber,
    File? imagePath, // Optional - null means keep existing profile picture
  });

  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  Future<Either<Failure, void>> resetPassword(String token, String newPassword);

  // OTP-based password reset methods
  Future<Either<Failure, void>> sendPasswordResetOTP(String email);
  Future<Either<Failure, void>> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}
