import 'dart:io';

import 'package:compareitr/core/common/network/network_connection.dart';
import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/core/error/failures.dart';
import 'package:compareitr/core/services/user_cache_service.dart';
import 'package:compareitr/features/auth/data/datasourses/auth_remote_data_source.dart';
import 'package:compareitr/core/common/entities/user_entity.dart';
import 'package:compareitr/features/auth/data/models/user_model.dart';
import 'package:compareitr/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final ConnectionChecker connectionChecker;
  const AuthRepositoryImpl(this.remoteDataSource, this.connectionChecker);

  @override
  Future<Either<Failure, UserEntity>> currentUser() async {
    try {
      // First, try to get cached user data
      final cachedUser = UserCacheService.getCachedUser();
      
      if (!await (connectionChecker.isConnected)) {
        // No internet connection - use cached data if available
        if (cachedUser != null) {
          return right(cachedUser);
        }
        
        // Fallback to minimal session data if no cache
        final session = remoteDataSource.currentUserSession;
        if (session == null) {
          return left(Failure('User not logged in!'));
        }

        return right(UserModel(
            name: '',
            phoneNumber: 0,
            email: session.user.email ?? '',
            id: session.user.id,
            street: '',
            location: '',
            proPic: '',
            role: 'customer'));  // Default role for offline users
      }

      // Internet available - fetch fresh data from server
      final user = await remoteDataSource.getCurrentUserData();

      if (user == null) {
        // If server returns null but we have cached data, use cached data
        if (cachedUser != null) {
          return right(cachedUser);
        }
        return left(Failure('User not logged in!'));
      }
      
      // Cache the fresh user data
      await UserCacheService.cacheUser(user);
      
      return right(user);
    } on AuthException catch (e) {
      // Handle Supabase auth exceptions (e.g., invalid refresh token)
      print('Auth exception in currentUser: ${e.message}');
      
      // Clear cache if refresh token is invalid
      if (e.message.contains('refresh_token') || e.message.contains('Invalid Refresh Token')) {
        await UserCacheService.clearCache();
      }
      
      return left(Failure('User not logged in!'));
    } on ServerException catch (e) {
      // If server fails but we have cached data, use cached data
      final cachedUser = UserCacheService.getCachedUser();
      if (cachedUser != null) {
        return right(cachedUser);
      }
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> logInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => await remoteDataSource.logInWithEmailPassword(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({
    required String name,
    required String street,
    required String location,
    required int phoneNumber,
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => await remoteDataSource.signUpWithEmailPassword(
        name: name,
        email: email,
        location: location,
        phoneNumber: phoneNumber,
        street: street,
        password: password,
      ),
    );
  }

  Future<Either<Failure, UserEntity>> _getUser(
    Future<UserEntity> Function() fn,
  ) async {
    try {
      if (!await (connectionChecker.isConnected)) {
        return left(Failure('No Internet Connection'));
      }
      final user = await fn();
      
      // Cache the user data after successful login/signup
      await UserCacheService.cacheUser(user);
      
      return right(user);
    } on AuthException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      
      // Clear cached user data on logout
      await UserCacheService.clearCache();
      
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    required String street,
    required String location,
    required int phoneNumber,
    File? imagePath, // Optional - null means keep existing profile picture
  }) async {
    try {
      await remoteDataSource.updateUserProfile(
        userId: userId,
        email: email,
        name: name,
        street: street,
        location: location,
        phoneNumber: phoneNumber,
        imagePath: imagePath,
      );
      
      // Update cached user data with new profile information
      final updatedUser = UserModel(
        id: userId,
        email: email,
        name: name,
        street: street,
        location: location,
        phoneNumber: phoneNumber,
        proPic: '', // Will be updated when we fetch fresh data
        role: 'customer', // Default role for profile updates
      );
      await UserCacheService.cacheUser(updatedUser);
      
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
      String token, String newPassword) async {
    try {
      await remoteDataSource.resetPassword(token, newPassword);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetOTP(String email) async {
    try {
      await remoteDataSource.sendPasswordResetOTP(email);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.verifyOTPAndResetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
