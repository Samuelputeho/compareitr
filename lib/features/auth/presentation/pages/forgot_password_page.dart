import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:compareitr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:compareitr/core/utils/show_snackbar.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();
  bool otpSent = false;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showSnackBar(context, state.message);
          } else if (state is AuthOTPSentSuccess) {
            setState(() {
              otpSent = true;
            });
            showSnackBar(context, 
              "✅ 6-digit code sent to your email!\n\n"
              "Check your inbox and enter the code below."
            );
          } else if (state is AuthPasswordResetSuccess) {
            showSnackBar(context, "Password reset successful! Please login.");
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return Center(child: CircularProgressIndicator(color: Colors.green));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: otpSent ? _buildOTPForm() : _buildEmailForm(),
          );
        },
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Enter your email to receive a 6-digit verification code",
            style: TextStyle(fontSize: 16.0),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: "Email",
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your email";
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value.trim())) {
                return "Please enter a valid email address";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (emailFormKey.currentState!.validate()) {
                  context.read<AuthBloc>().add(
                    AuthSendPasswordResetOTP(email: emailController.text.trim()),
                  );
                }
              },
              child: const Text("Send Verification Code"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPForm() {
    return Form(
      key: resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    otpSent = false;
                  });
                },
              ),
              Expanded(
                child: Text(
                  "Code sent to ${emailController.text}",
                  style: const TextStyle(fontSize: 14.0, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: otpController,
            decoration: const InputDecoration(
              labelText: "6-Digit Code",
              prefixIcon: Icon(Icons.lock_outline),
              border: OutlineInputBorder(),
              hintText: "Enter code from email",
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            autofocus: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter the code";
              }
              if (value.length != 6) {
                return "Code must be 6 digits";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: "New Password",
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter a new password";
              }
              if (value.length < 6) {
                return "Password must be at least 6 characters";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmPasswordController,
            decoration: const InputDecoration(
              labelText: "Confirm Password",
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value != passwordController.text) {
                return "Passwords do not match";
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (resetFormKey.currentState!.validate()) {
                  context.read<AuthBloc>().add(
                    AuthVerifyOTPAndResetPassword(
                      email: emailController.text.trim(),
                      otp: otpController.text.trim(),
                      newPassword: passwordController.text.trim(),
                    ),
                  );
                }
              },
              child: const Text("Reset Password"),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                  AuthSendPasswordResetOTP(email: emailController.text.trim()),
                );
              },
              child: const Text("Resend Code"),
            ),
          ),
        ],
      ),
    );
  }
}
