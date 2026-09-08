import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:d_una_app/core/constants/auth_constants.dart';

enum EmailStatus { available, verified, unverified }

abstract class AuthRepository {
  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  });

  Future<void> verifyOtp({required String email, required String token});

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> resendOtp({required String email});

  Future<void> resetPassword({required String email});

  Future<void> updatePassword(String newPassword);
  Future<EmailStatus> getEmailStatus(String email);
  User? get currentUser;

  /// Inicia sesión con Google (nativo en Android).
  /// Retorna el AuthResponse de Supabase si fue exitoso.
  /// Retorna null si el usuario canceló la selección de cuenta.
  Future<AuthResponse?> signInWithGoogle();
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  SupabaseAuthRepository(
    this._supabase, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: AuthConstants.googleWebClientId,
            );

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> data,
  }) async {
    await _supabase.auth.signUp(email: email, password: password, data: data);
  }

  @override
  Future<void> verifyOtp({required String email, required String token}) async {
    await _supabase.auth.verifyOTP(
      type: OtpType.signup,
      token: token,
      email: email,
    );
  }

  @override
  Future<void> resendOtp({required String email}) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<EmailStatus> getEmailStatus(String email) async {
    final response = await _supabase.rpc('check_email_status', params: {
      'email_to_check': email,
    });

    switch (response.toString()) {
      case 'AVAILABLE':
        return EmailStatus.available;
      case 'VERIFIED':
        return EmailStatus.verified;
      case 'UNVERIFIED':
        return EmailStatus.unverified;
      default:
        return EmailStatus.verified;
    }
  }

  @override
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Desconectar sesión en caché para forzar a que Google
      // siempre muestre el diálogo de selección de cuentas al pulsar el botón
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const AuthException(
          'No se pudo obtener el token de autenticación de Google. '
          'Verifica la configuración de OAuth en Google Cloud Console.',
        );
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled' ||
          (e.code == 'network_error' &&
              e.message?.contains('canceled') == true)) {
        return null;
      }
      if (e.code == '10' ||
          e.message?.contains('10') == true ||
          e.code == 'DEVELOPER_ERROR') {
        throw const AuthException(
          'Error de configuración en Google Sign In (SHA-1 o Client ID). Contacta a soporte.',
        );
      }
      if (e.code == '7' || e.code == 'network_error') {
        throw const AuthException(
          'Error de red al conectar con Google. Verifica tu conexión.',
        );
      }
      throw AuthException('Error de Google Sign In: ${e.message ?? e.code}');
    }
  }
}
