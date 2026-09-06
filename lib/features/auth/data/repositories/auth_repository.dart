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

  SupabaseAuthRepository(this._supabase);

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
      await GoogleSignIn().signOut();
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
    final googleSignIn = GoogleSignIn(
      serverClientId: AuthConstants.googleWebClientId,
    );

    // Desconectar sesión en caché para forzar a que Google
    // siempre muestre el diálogo de selección de cuentas al pulsar el botón
    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final googleUser = await googleSignIn.signIn();
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
  }
}
