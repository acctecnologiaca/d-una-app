import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_button.dart';

class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white, // Using Theme Surface
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Welcome Text
              Text(
                'Bienvenido a',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Logo d.una
              // Using the same asset path as LoginScreen based on view_file result
              Image.asset(
                'assets/images/logo_d_una.png',
                height: 60, // Sizing based on visual estimate from image
              ),

              const SizedBox(height: 32),

              // Illustration (Worker Thumbs Up)
              // User mentioned 'welcome.png' in 'imagenes' folder.
              // Assuming standard path 'assets/images/welcome.png'
              Image.asset(
                'assets/images/welcome.png',
                height: 300, // Visual estimate
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 32),

              // Success Message
              Text(
                'Tu cuenta ha sido creada exitosamente.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 60),
              // Continue Button
              CustomButton(
                text: 'Continuar',
                onPressed: () {
                  // Navigate to the main app home or dashboard
                  // For now, replacing with '/home' or back to login if no auth session exists yet (depends on if verifyOtp logged them in).
                  // Usually after verification, they are logged in.
                  // Since we are mocking, let's go to '/login' or a placeholder '/home'.
                  // GoRouter helper: while true home isn't built, maybe '/login' is safer or staying here?
                  // User prompt didn't specify post-success destination. Assuming '/login' or '/home'.
                  // Let's use '/login' for now as MVP might not have Home ready.
                  // Or better, context.go('/login');
                  context.go('/clients');
                },
                type: ButtonType.primary,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
