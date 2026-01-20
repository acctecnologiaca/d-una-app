import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/custom_button.dart';

class RegisterIntroScreen extends StatelessWidget {
  const RegisterIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white, // Removed to use Theme Surface
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 22.0, 16.0, 40.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight - 62, // Adjust for padding (22+40)
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Title
                      // Font size seems large, maybe headlineMedium or Large
                      Text(
                        'Crea una cuenta',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight
                              .w500, // Medium weight as per Material 3 defaults usually, or bold if image suggests
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Hero Image
                      // "new_account.png"
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            'assets/images/new_account.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Text
                      Text(
                        'Crea una cuenta y comienza a gestionar tu trabajo de manera rápida y sencilla.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Slogan
                      Text(
                        '¡Házlo ahora, házlo de una!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 24),

                      // Buttons
                      CustomButton(
                        text: 'Comenzar',
                        onPressed: () {
                          context.push('/register/email');
                        },
                        type: ButtonType.primary,
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () {
                          context.pop(); // Go back to Login
                        },
                        child: Text(
                          'Salir',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .primary, // Or specific color from design
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
