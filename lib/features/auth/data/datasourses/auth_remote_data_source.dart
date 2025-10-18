import 'dart:io';

import 'package:compareitr/core/error/exceptions.dart';
import 'package:compareitr/features/auth/data/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRemoteDataSource {
  Session? get currentUserSession;
  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String street,
    required String location,
    required int phoneNumber,
    required String email,
    required String password,
  });

  Future<UserModel> logInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel?> getCurrentUserData();
  Future<void> logout();

  Future<void> updateUserProfile({
    required String userId,
    required String email,
    required String name,
    required String street,
    required String location,
    required int phoneNumber,
    File? imagePath, // Optional - null means keep existing profile picture
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> resetPassword(String token, String newPassword);

  Future<void> sendPasswordResetOTP(String email);

  Future<void> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;

  @override
  Session? get currentUserSession => supabaseClient.auth.currentSession;

  AuthRemoteDataSourceImpl(this.supabaseClient);
  @override
  Future<UserModel> logInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        password: password,
        email: email,
      );
      if (response.user == null) {
        throw ServerException("User is null!");
      }
      return UserModel.fromJson(
        response.user!.toJson(),
      );
    } catch (e) {
      throw ServerException(
        e.toString(),
      );
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String street,
    required String location,
    required String email,
    required String password,
    required int phoneNumber,
  }) async {
    try {
      final response = await supabaseClient.auth
          .signUp(password: password, email: email, data: {
        'name': name,
        'email': email,
        'street': street,
        'location': location,
        'phoneNumber': phoneNumber,
      });
      if (response.user == null) {
        throw ServerException("User is null!");
      }
      return UserModel.fromJson(
        response.user!.toJson(),
      );
    } catch (e) {
      throw ServerException(
        e.toString(),
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUserData() async {
    try {
      if (currentUserSession != null) {
        final userData = await supabaseClient
            .from('profiles')
            .select()
            .eq('id', currentUserSession!.user.id);
        return UserModel.fromJson(userData.first).copyWith(
          email: currentUserSession!.user.email,
        );
      }

      return null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateUserProfile({
    required String userId,
    required String name,
    required String email,
    required String street,
    required String location,
    required int phoneNumber,
    File? imagePath, // Optional - null means keep existing profile picture
  }) async {
    try {
      String? publicURL;
      
      // Only upload image if a new one was provided
      if (imagePath != null && imagePath.path.isNotEmpty && await imagePath.exists()) {
      // 1. Upload image to bucket
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_$userId.jpg";
      final storageResponse = await supabaseClient.storage
            .from('profile-pictures')
          .upload(fileName, imagePath);

      if (storageResponse.isEmpty) {
        throw ServerException("Image upload failed.");
      }
        
      // 2. Get public URL for the uploaded image
        publicURL = supabaseClient.storage
          .from('profile-pictures')
          .getPublicUrl(fileName);

      if (publicURL.isEmpty) {
        throw ServerException("Failed to retrieve public URL for image.");
        }
      }

      // 3. Update user's profile in the database
      final updateData = {
        'name': name,
        'street': street,
        'location': location,
        'email': email,
        'phonenumber': phoneNumber,  // Use lowercase to match database column
      };
      
      // Only update profile picture if a new one was uploaded
      if (publicURL != null) {
        updateData['propic'] = publicURL;
      }
      
      await supabaseClient
          .from('profiles')
          .update(updateData)
          .eq('id', userId);
      
      print('✅ Profile updated successfully');
    } catch (e) {
      print('❌ Error updating profile: $e');
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // No redirectTo - user clicks link, opens app, and PASSWORD_RECOVERY event triggers
      await supabaseClient.auth.resetPasswordForEmail(email);
      print('Password reset email sent to: $email');
    } catch (e) {
      throw ServerException(
          "Failed to send password reset email: ${e.toString()}");
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw ServerException("Failed to reset password: ${e.toString()}");
    }
  }

  @override
  Future<void> sendPasswordResetOTP(String email) async {
    try {
      // First check if user exists and get their role
      final userData = await supabaseClient
          .from('profiles')
          .select('role')
          .eq('email', email)
          .single();
      
      // Check if user is a driver
      if (userData['role'] == 'driver') {
        throw ServerException("Password reset is not available for drivers. Please contact your administrator to reset your password.");
      }
      
      // Use signInWithOtp to send a NUMERIC 6-digit code (not a magic link!)
      // This sends an actual OTP code that users can type in the app
      await supabaseClient.auth.signInWithOtp(
        email: email,
        emailRedirectTo: null,
        shouldCreateUser: false, // Don't create new users, only existing ones
      );
      print('OTP code sent to: $email');
      print('User should receive a 6-digit code in their email');
    } catch (e) {
      if (e.toString().contains('Password reset is not available for drivers')) {
        rethrow; // Re-throw the driver restriction error as-is
      }
      throw ServerException("Failed to send OTP: ${e.toString()}");
    }
  }

  @override
  Future<void> verifyOTPAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      print('Verifying OTP: $otp for email: $email');
      
      // Step 1: Verify the OTP code (6-digit code from email)
      final response = await supabaseClient.auth.verifyOTP(
        email: email,
        token: otp.trim(), // Remove any whitespace
        type: OtpType.email,
      );

      print('OTP verification response: ${response.session != null ? "Success" : "Failed"}');

      if (response.session == null) {
        throw ServerException("Invalid or expired OTP code. Please request a new code.");
      }

      print('OTP verified! Session created. Now updating password...');

      // Step 2: Update the password using the verified session
      await supabaseClient.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      print('Password updated successfully for: $email');
      
      // Step 3: Sign out after password reset (user needs to login with new password)
      await supabaseClient.auth.signOut();
      
      print('Password reset complete!');
    } catch (e) {
      print('Error in verifyOTPAndResetPassword: $e');
      if (e.toString().contains('invalid') || e.toString().contains('expired')) {
        throw ServerException("Invalid or expired OTP code. Please request a new code.");
      }
      throw ServerException("Failed to reset password: ${e.toString()}");
    }
  }
}
