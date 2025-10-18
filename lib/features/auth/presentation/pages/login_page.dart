import 'package:compareitr/core/common/widgets/loader.dart';
import 'package:compareitr/core/theme/app_pallete.dart';
import 'package:compareitr/core/utils/show_snackbar.dart';
import 'package:compareitr/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:compareitr/features/auth/presentation/widgets/auth_button.dart';
import 'package:compareitr/features/auth/presentation/widgets/auth_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'sign_up_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          body: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                showSnackBar(context, state.message);
              }
            },
            builder: (context, state) {
              if (state is AuthLoading) {
                return const Loader();
              }
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Container
                          Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height * 0.25,
                            decoration: const BoxDecoration(
                              color: AppPallete.authColor,
                            ),
                            child: const SafeArea(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Sign In to Your \nAccount",
                                      style: TextStyle(
                                        color: AppPallete.backgroundColor,
                                        fontSize: 23,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Form Fields
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 25),
                                  AuthField(
                                    hintText: "Email",
                                    controller: emailController,
                                  ),
                                  const SizedBox(height: 20),
                                  AuthField(
                                    hintText: "Password",
                                    controller: passwordController,
                                    isObscureText: true,
                                  ),
                                  const SizedBox(height: 5),
                                   Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      GestureDetector(
                                         onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const ForgotPasswordPage(),
                                          ),
                                        );
                                        },
                                        child: Text(
                                          "Forgot Password?",
                                          style: TextStyle(
                                            color: AppPallete.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  AuthButton(
                                    buttonText: "Log In",
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        context.read<AuthBloc>().add(
                                              AuthLogin(
                                                email: emailController.text.trim(),
                                                password:
                                                    passwordController.text.trim(),
                                              ),
                                            );
                                      }
                                    },
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Don't have an account?"),
                                      const SizedBox(width: 5),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SignUpPage(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          "SignUp",
                                          style: TextStyle(
                                            color: AppPallete.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
