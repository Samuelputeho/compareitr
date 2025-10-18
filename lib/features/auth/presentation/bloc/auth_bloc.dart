import 'dart:io';

import 'package:compareitr/core/common/cubits/app_user/app_user_cubit.dart';
import 'package:compareitr/core/usecase/usecase.dart';
import 'package:compareitr/core/common/entities/user_entity.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:compareitr/core/services/user_cache_service.dart';
import 'package:compareitr/features/auth/domain/usecases/current_user.dart';
import 'package:compareitr/features/auth/domain/usecases/reset_password.dart';
import 'package:compareitr/features/auth/domain/usecases/update_user.dart';
import 'package:compareitr/features/auth/domain/usecases/user_login.dart';
import 'package:compareitr/features/auth/domain/usecases/user_sign_up.dart';
import 'package:compareitr/features/auth/domain/usecases/logout_usecase.dart';
import 'package:compareitr/features/auth/domain/usecases/send_password_reset_email.dart';
import 'package:compareitr/features/auth/domain/usecases/send_password_reset_otp.dart';
import 'package:compareitr/features/auth/domain/usecases/verify_otp_and_reset_password.dart';
// New import
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserSignUp _userSignUp;
  final UserLogin _userLogin;
  final CurrentUser _currentUser;
  final LogoutUsecase _logoutUsecase;
  final UpdateUserProfile _updateUserProfile; // New use case
  final AppUserCubit _appUserCubit;
  final SendPasswordResetEmail _sendPasswordResetEmail;
  final ResetPassword _resetPassword;
  final SendPasswordResetOTP _sendPasswordResetOTP;
  final VerifyOTPAndResetPassword _verifyOTPAndResetPassword;
  // New use case

  AuthBloc({
    required UserSignUp userSignUp,
    required UserLogin userLogin,
    required CurrentUser currentUser,
    required LogoutUsecase logoutUsecase,
    required UpdateUserProfile updateUserProfile, // New use case
    required AppUserCubit appUserCubit,
    required SendPasswordResetEmail sendPasswordResetEmail,
    required ResetPassword resetPassword,
    required SendPasswordResetOTP sendPasswordResetOTP,
    required VerifyOTPAndResetPassword verifyOTPAndResetPassword, // New use case
  })  : _userSignUp = userSignUp,
        _userLogin = userLogin,
        _currentUser = currentUser,
        _logoutUsecase = logoutUsecase,
        _updateUserProfile = updateUserProfile, // New use case
        _appUserCubit = appUserCubit,
        _sendPasswordResetEmail = sendPasswordResetEmail,
        _resetPassword = resetPassword,
        _sendPasswordResetOTP = sendPasswordResetOTP,
        _verifyOTPAndResetPassword = verifyOTPAndResetPassword, // New use case
        super(AuthInitial()) {
    on<AuthEvent>((_, emit) => emit(AuthLoading()));
    on<AuthSignUp>(_onAuthSignUp);
    on<AuthLogin>(_onAuthLogin);
    on<AuthIsUserLoggedIn>(_isUserLoggedIn);
    on<AuthLogout>(_onAuthLogout);
    on<AuthUpdateProfile>(_onAuthUpdateProfile); // New event handler
    on<AuthSendPasswordResetEmail>(_onAuthSendPasswordResetEmail);
    on<AuthResetPassword>(_onAuthResetPassword);
    on<AuthSendPasswordResetOTP>(_onAuthSendPasswordResetOTP);
    on<AuthVerifyOTPAndResetPassword>(_onAuthVerifyOTPAndResetPassword); // New event handler
  }

  void _isUserLoggedIn(
    AuthIsUserLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    // If offline, try to use cached user data first
    if (CacheManager.isOffline) {
      final cachedUser = UserCacheService.getCachedUser();
      if (cachedUser != null) {
        print('📱 Offline mode: Using cached user data');
        _emitAuthSuccess(cachedUser, emit);
        return;
      } else {
        print('📱 Offline mode: No cached user data available');
        emit(const AuthFailure('No internet connection and no cached user data'));
        return;
      }
    }

    // Online: Try to fetch fresh user data
    final res = await _currentUser(NoParams());

    res.fold(
      (l) {
        // If server error, try cached user as fallback
        final cachedUser = UserCacheService.getCachedUser();
        if (cachedUser != null) {
          print('🔄 Server error, using cached user data: ${l.message}');
          _emitAuthSuccess(cachedUser, emit);
        } else {
          print('❌ No cached user data available: ${l.message}');
          emit(AuthFailure(l.message));
        }
      },
      (r) => _emitAuthSuccess(r, emit),
    );
  }

  void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    final res = await _userSignUp(
      UserSignUpParams(
        password: event.password,
        name: event.name,
        email: event.email,
        phoneNumber: event.phoneNumber,
        street: event.street,
        location: event.location,
      ),
    );

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    final res = await _userLogin(
      UserLoginParams(
        email: event.email,
        password: event.password,
      ),
    );

    res.fold(
      (l) => emit(AuthFailure(l.message)),
      (r) => _emitAuthSuccess(r, emit),
    );
  }

  void _onAuthLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _logoutUsecase();

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) {
        _appUserCubit.updateUser(null); // Clear user data
        emit(AuthInitial()); // Reset to initial state
      },
    );
  }

  void _onAuthUpdateProfile(
      AuthUpdateProfile event, Emitter<AuthState> emit) async {
    emit(AuthLoading()); // Show loading while updating the profile

    final res = await _updateUserProfile(UpdateUserProfileParams(
      userId: event.userId,
      name: event.name,
      email: event.email,
      street: event.street,
      location: event.location,
      phoneNumber: event.phoneNumber,
      imagePath: event.imagePath, // Optional: null = keep existing picture
    ));

    await res.fold(
      (failure) async {
        emit(AuthFailure(failure.message));
      },
      (_) async {
        // Profile updated successfully - fetch fresh user data from server
        // This ensures we get the correct proPic URL
        final userRes = await _currentUser(NoParams());
        
        userRes.fold(
      (failure) => emit(AuthFailure(failure.message)),
          (user) => _emitAuthSuccess(user, emit),
        );
      },
    );
  }

  void _onAuthSendPasswordResetEmail(
      AuthSendPasswordResetEmail event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _sendPasswordResetEmail(event.email);

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(const AuthPasswordResetSuccess()), // Emit the new state
    );
  }

  void _onAuthResetPassword(
      AuthResetPassword event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _resetPassword(ResetPasswordParams(
        token: event.token, newPassword: event.newPassword));

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }

  void _onAuthSendPasswordResetOTP(
      AuthSendPasswordResetOTP event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _sendPasswordResetOTP(event.email);

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(const AuthOTPSentSuccess()),
    );
  }

  void _onAuthVerifyOTPAndResetPassword(
      AuthVerifyOTPAndResetPassword event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final res = await _verifyOTPAndResetPassword(VerifyOTPAndResetPasswordParams(
      email: event.email,
      otp: event.otp,
      newPassword: event.newPassword,
    ));

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }

  void _emitAuthSuccess(UserEntity user, Emitter<AuthState> emit) {
    _appUserCubit.updateUser(user);
    // Cache the user data for offline access
    UserCacheService.cacheUser(user);
    emit(AuthSuccess(user));
  }
}
