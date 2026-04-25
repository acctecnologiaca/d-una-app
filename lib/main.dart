import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/session_manager.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fdkswvzrozijbizdthge.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZka3N3dnpyb3ppamJpemR0aGdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0NzQ2MzMsImV4cCI6MjA4MzA1MDYzM30.ZENEwSy2E8iSHuy4Y4uTd7CBd32iaE-tJmSww6cw0TY',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),

    debug: true, // Enable debug logs to track connection issues
  );

  // Check session validity (5 days inactivity rule)
  final sessionManager = SessionManager();
  sessionManager.checkSessionValidity(); // Fire and forget, don't block startup

  runApp(const ProviderScope(child: DUnaApp()));
}

class DUnaApp extends ConsumerStatefulWidget {
  const DUnaApp({super.key});

  @override
  ConsumerState<DUnaApp> createState() => _DUnaAppState();
}

class _DUnaAppState extends ConsumerState<DUnaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed: validando sesión y refrescando conectividad...');
      final sessionManager = SessionManager();
      final isValid = await sessionManager.checkSessionValidity();

      if (isValid) {
        try {
          // Forzar refresco proactivo de la sesión
          await Supabase.instance.client.auth.refreshSession();
          debugPrint('Sesión refrescada proactivamente en OnResume.');
        } catch (e) {
          debugPrint('Fallo al refrescar sesión proactivamente: $e');
        }

        // Invalidar providers realtime para forzar re-suscripción de WebSockets
        ref.invalidate(userProfileProvider);
        ref.invalidate(shippingMethodsProvider);
        ref.invalidate(verificationDocumentsProvider);
        debugPrint('Providers realtime invalidados para restaurar streams.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'd·una',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
    );
  }
}
