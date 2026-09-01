import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../../settings/data/models/shipping_method.dart';
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

  UserProfile? lastKnownProfile;

  // Retry loop to handle token expiry race conditions
  while (true) {
    final user = supabase.auth.currentUser;
    if (user == null) {
      yield null;
      return;
    }

    // Proactive Expiry Check (60s buffer)
    final session = supabase.auth.currentSession;
    if (session != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        session.expiresAt! * 1000,
      );
      if (DateTime.now().add(const Duration(seconds: 60)).isAfter(expiresAt)) {
        try {
          await supabase.auth.refreshSession();
        } catch (_) {
          // If refresh fails, proceed and let stream fail if token is invalid
        }
      }
    }

    try {
      // Listen to realtime changes on the profiles table for this user
      final stream = supabase
          .from('profiles')
          .stream(primaryKey: ['id'])
          .eq('id', user.id);

      await for (final data in stream) {
        if (data.isNotEmpty) {
          lastKnownProfile = UserProfile.fromJson(data.first);
          yield lastKnownProfile;
        } else {
          yield null;
        }
      }
      // Stream completed normally
      break;
    } on RealtimeSubscribeException catch (e) {
      // Check for token expiry error
      // Error: RealtimeSubscribeException(status: channelError, details: Exception: "InvalidJWTToken: ...")
      final msg = e.toString();
      if (msg.contains('expired') ||
          msg.contains('InvalidJWTToken') ||
          msg.contains('JWT')) {
        // Attempt to refresh session and retry
        try {
          await supabase.auth.refreshSession();
          continue; // Retry loop
        } catch (_) {
          if (lastKnownProfile != null) rethrow;
          yield null;
          return;
        }
      }
      // Si ocurre desconexión de red / caída de WebSocket, no sobreescribir con null
      if (lastKnownProfile != null) {
        rethrow;
      }
      yield null;
      return;
    } catch (e) {
      // Re-throw to allow dependent providers and UI to handle the error state
      rethrow;
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

      while (true) {
        final user = supabase.auth.currentUser;
        if (user == null) {
          yield [];
          return;
        }

        // Proactive Expiry Check (60s buffer)
        final session = supabase.auth.currentSession;
        if (session != null) {
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(
            session.expiresAt! * 1000,
          );
          if (DateTime.now()
              .add(const Duration(seconds: 60))
              .isAfter(expiresAt)) {
            try {
              await supabase.auth.refreshSession();
            } catch (_) {}
          }
        }

        try {
          // Fetch global (system) methods once
          final globalMethods = await supabase
              .from('shipping_methods')
              .select()
              .isFilter('user_id', null)
              .order('created_at', ascending: true);
          final globalList = globalMethods
              .map((json) => ShippingMethod.fromJson(json))
              .toList();

          final stream = supabase
              .from('shipping_methods')
              .stream(primaryKey: ['id'])
              .eq('user_id', user.id)
              .order('is_primary', ascending: false)
              .order('created_at', ascending: true);

          await for (final data in stream) {
            final userList = data.map((json) => ShippingMethod.fromJson(json)).toList();
            // Yield user methods first, then system methods at the end
            yield [...userList, ...globalList];
          }
          break;
        } on RealtimeSubscribeException catch (e) {
          final msg = e.toString();
          if (msg.contains('expired') ||
              msg.contains('InvalidJWTToken') ||
              msg.contains('JWT')) {
            try {
              await supabase.auth.refreshSession();
              continue;
            } catch (_) {
              yield [];
              return;
            }
          }
          yield [];
          return;
        } catch (e) {
          yield [];
          return;
        }
      }
    });

// --- Verification Documents Provider ---
final verificationDocumentsProvider =
    StreamProvider.autoDispose<List<VerificationDocument>>((ref) async* {
      final supabase = Supabase.instance.client;

      while (true) {
        final user = supabase.auth.currentUser;
        if (user == null) {
          yield [];
          return;
        }

        // Proactive Expiry Check (60s buffer)
        final session = supabase.auth.currentSession;
        if (session != null) {
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(
            session.expiresAt! * 1000,
          );
          if (DateTime.now()
              .add(const Duration(seconds: 60))
              .isAfter(expiresAt)) {
            try {
              await supabase.auth.refreshSession();
            } catch (_) {}
          }
        }

        try {
          final stream = supabase
              .from('verification_documents')
              .stream(primaryKey: ['id'])
              .eq('user_id', user.id)
              .order('created_at', ascending: false);

          await for (final data in stream) {
            yield data
                .map((json) => VerificationDocument.fromJson(json))
                .toList();
          }
          break;
        } on RealtimeSubscribeException catch (e) {
          final msg = e.toString();
          if (msg.contains('expired') ||
              msg.contains('InvalidJWTToken') ||
              msg.contains('JWT')) {
            try {
              await supabase.auth.refreshSession();
              continue;
            } catch (_) {
              yield [];
              return;
            }
          }
          yield [];
          return;
        } catch (e) {
          yield [];
          return;
        }
      }
    });
