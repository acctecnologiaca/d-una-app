import 'package:supabase_flutter/supabase_flutter.dart';

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

  User? get currentUser;
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
}
