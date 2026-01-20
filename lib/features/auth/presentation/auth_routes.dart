import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/auth/presentation/login_screen.dart';
import 'package:d_una_app/features/auth/presentation/register_intro_screen.dart';
import 'package:d_una_app/features/auth/presentation/register_email_screen.dart';
import 'package:d_una_app/features/auth/presentation/register_password_screen.dart';
import 'package:d_una_app/features/auth/presentation/register_name_screen.dart';
import 'package:d_una_app/features/auth/presentation/register_occupation_screen.dart';
import 'package:d_una_app/features/auth/presentation/register_verification_screen.dart';
import 'package:d_una_app/features/auth/presentation/register_success_screen.dart';

final authRoutes = [
  GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
  GoRoute(
    path: '/register',
    builder: (context, state) => const RegisterIntroScreen(),
    routes: [
      GoRoute(
        path: 'email',
        builder: (context, state) => const RegisterEmailScreen(),
      ),
      GoRoute(
        path: 'password',
        builder: (context, state) => const RegisterPasswordScreen(),
      ),
      GoRoute(
        path: 'name',
        builder: (context, state) => const RegisterNameScreen(),
      ),
      GoRoute(
        path: 'occupation',
        builder: (context, state) => const RegisterOccupationScreen(),
      ),
      GoRoute(
        path: 'verification',
        builder: (context, state) => const RegisterVerificationScreen(),
      ),
      GoRoute(
        path: 'success',
        builder: (context, state) => const RegisterSuccessScreen(),
      ),
    ],
  ),
];
