import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/session_manager.dart';
import 'core/services/reconnection_sync_service.dart';
import 'core/providers/network_status_provider.dart';
import 'package:d_una_app/shared/providers/pdf_preview_provider.dart';
import 'core/widgets/connectivity_gate.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/draft_providers.dart';

final GlobalKey<RootAppState> rootAppKey = GlobalKey();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

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

  runApp(RootApp(key: rootAppKey, prefs: prefs));
}

class RootApp extends StatefulWidget {
  final SharedPreferences prefs;
  const RootApp({super.key, required this.prefs});

  static void restart(BuildContext? context) {
    debugPrint(
      'RootApp.restart() called. Context provided: ${context != null}',
    );
    if (context != null) {
      final state = context.findAncestorStateOfType<RootAppState>();
      if (state != null) {
        state.restart();
      } else {
        debugPrint(
          'Warning: RootAppState not found in context. Falling back to rootAppKey.',
        );
        rootAppKey.currentState?.restart();
      }
    } else {
      rootAppKey.currentState?.restart();
    }
  }

  @override
  State<RootApp> createState() => RootAppState();
}

class RootAppState extends State<RootApp> {
  Key _providerScopeKey = UniqueKey();

  Future<void> restart() async {
    debugPrint(
      'RootAppState.restart() executing. Full cleanup and Recreating ProviderScope.',
    );

    try {
      // 1. Clear Supabase Auth
      await Supabase.instance.client.auth.signOut();

      // 2. Clear Session Manager (SharedPreferences)
      await SessionManager().clearSessionData();

      // 3. Clear Static Caches (like PDF preview)
      PdfPreviewData.lastData = null;
    } catch (e) {
      debugPrint('Error during full restart cleanup: $e');
    }

    if (mounted) {
      setState(() {
        _providerScopeKey = UniqueKey();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      key: _providerScopeKey,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(widget.prefs),
      ],
      child: const DUnaApp(),
    );
  }
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
    debugPrint('DUnaApp.initState() - App is starting or restarting.');
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

      // 1. Forzar re-comprobación inmediata del estado de red
      ref.read(networkStatusProvider.notifier).checkImmediately();

      // 2. Validar sesión y sincronizar datos
      final sessionManager = SessionManager();
      final isValid = await sessionManager.checkSessionValidity();

      if (isValid) {
        ReconnectionSyncService.syncAfterReconnection(ref);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'D-Una',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      builder: (context, child) {
        return ConnectivityGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
