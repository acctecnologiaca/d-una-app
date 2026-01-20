import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/shipping_method.dart';
import '../../domain/models/verification_document.dart';
import '../../data/repositories/profile_repository.dart';

// Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// --- Profile Providers ---

// Stream of User Profile
final userProfileProvider = StreamProvider.autoDispose<UserProfile?>((
  ref,
) async* {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    yield null;
    return;
  }

  // Check if session is expired and refresh if necessary
  final session = supabase.auth.currentSession;
  if (session != null && session.isExpired) {
    try {
      await supabase.auth.refreshSession();
    } catch (_) {
      // Refresh failed, likely session invalid
      yield null;
      return;
    }
  }

  // Listen to realtime changes on the profiles table for this user
  final stream = supabase
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id);

  await for (final data in stream) {
    if (data.isNotEmpty) {
      yield UserProfile.fromJson(data.first);
    } else {
      yield null;
    }
  }
});

// Single fetch (Future) if needed, but Stream is better for reactive UI
final fetchUserProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  final repo = ref.watch(profileRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;
  return repo.getProfile(user.id);
});

// --- Shipping Methods Providers ---

// Stream of Shipping Methods
final shippingMethodsProvider =
    StreamProvider.autoDispose<List<ShippingMethod>>((ref) async* {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        yield [];
        return;
      }

      // Check if session is expired and refresh if necessary
      final session = supabase.auth.currentSession;
      if (session != null && session.isExpired) {
        try {
          await supabase.auth.refreshSession();
        } catch (_) {
          yield [];
          return;
        }
      }

      final stream = supabase
          .from('shipping_methods')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('is_primary', ascending: false)
          .order('created_at', ascending: true);

      await for (final data in stream) {
        yield data.map((json) => ShippingMethod.fromJson(json)).toList();
      }
    });

// --- Verification Documents Provider ---
final verificationDocumentsProvider =
    StreamProvider.autoDispose<List<VerificationDocument>>((ref) async* {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        yield [];
        return;
      }

      // Check if session is expired and refresh if necessary
      final session = supabase.auth.currentSession;
      if (session != null && session.isExpired) {
        try {
          await supabase.auth.refreshSession();
        } catch (_) {
          yield [];
          return;
        }
      }

      final stream = supabase
          .from('verification_documents')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      await for (final data in stream) {
        yield data.map((json) => VerificationDocument.fromJson(json)).toList();
      }
    });
