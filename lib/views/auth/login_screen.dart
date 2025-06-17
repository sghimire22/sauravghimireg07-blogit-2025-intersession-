import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();

    return Scaffold(
      // 1) Change AppBar title to “BlogIt”
      appBar: AppBar(title: const Text('BlogIt')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // 2) Add this “Login” header immediately under the bar
            Text('Login', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 32),

            // --- your existing email/password fields & buttons ---
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    authController.isLoading
                        ? null
                        : () async {
                          await authController.login(
                            _emailCtrl.text,
                            _passwordCtrl.text,
                          );
                          if (mounted && authController.errorMessage == null) {
                            context.go('/');
                          }
                        },
                child:
                    authController.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Log in'),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Create an account'),
              ),
            ),

            const SizedBox(height: 8),
            Center(
              child: OutlinedButton(
                onPressed:
                    authController.isLoading
                        ? null
                        : () async {
                          // your existing Google sign-in logic
                        },
                child: const Text('Sign in with Google'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
