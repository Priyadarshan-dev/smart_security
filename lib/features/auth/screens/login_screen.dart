import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../model/auth_state.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.status == AuthStatus.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.error ?? "Error")));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    'assets/images/CDS_logo.svg',
                    height: 180,
                    width: 180,
                    fit: BoxFit.contain,
                  ),

                  // Email Input
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: "Enter Email Address",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) => value!.isEmpty ? "Enter email" : null,
                  ),
                  const SizedBox(height: 24),
                  // Password Input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      labelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: "Enter Password",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Color(0xFFF1F5F9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey.shade400,
                          width: 2,
                        ),
                      ),
                    ),
                    validator:
                        (value) => value!.isEmpty ? "Enter password" : null,
                  ),
                  const SizedBox(height: 20),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          authState.status == AuthStatus.loading
                              ? null
                              : () {
                                if (_formKey.currentState!.validate()) {
                                  ref
                                      .read(authProvider.notifier)
                                      .login(
                                        _emailController.text,
                                        _passwordController.text,
                                      );
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6), // Bright Blue
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          authState.status == AuthStatus.loading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                "Login",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
