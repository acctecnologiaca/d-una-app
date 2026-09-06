import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_button.dart';

class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
                Image.asset(
                  'assets/images/logo_d_una.png',
                  height: 60,
                ),

                const SizedBox(height: 32),

                // Illustration (Worker Thumbs Up)
                Image.asset(
                  'assets/images/welcome.png',
                  height: 300,
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
                    context.go('/portfolio');
                  },
                  type: ButtonType.primary,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
