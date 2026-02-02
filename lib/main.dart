import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fdkswvzrozijbizdthge.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZka3N3dnpyb3ppamJpemR0aGdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0NzQ2MzMsImV4cCI6MjA4MzA1MDYzM30.ZENEwSy2E8iSHuy4Y4uTd7CBd32iaE-tJmSww6cw0TY',
  );

  // Check session validity (5 days inactivity rule)
  final sessionManager = SessionManager();
  await sessionManager.checkSessionValidity();

  runApp(const ProviderScope(child: DUnaApp()));
}

class DUnaApp extends ConsumerWidget {
  const DUnaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
