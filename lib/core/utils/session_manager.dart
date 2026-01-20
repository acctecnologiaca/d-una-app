import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionManager {
  static const String _lastActiveKey = 'session_last_active_timestamp';
  static const int _daysToExpiration = 5;

  /// Checks if the current session is valid based on the last active timestamp.
  /// If the session has expired (inactive for > 5 days), it signs the user out.
  /// Returns true if session is valid or if there was no session to begin with.
  /// Returns false if session was expired and user was signed out.
  Future<bool> checkSessionValidity() async {
    final session = Supabase.instance.client.auth.currentUser;
    if (session == null) {
      return true; // No session to validate
    }

    final prefs = await SharedPreferences.getInstance();
    final lastActiveTs = prefs.getInt(_lastActiveKey);

    if (lastActiveTs != null) {
      final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveTs);
      final difference = DateTime.now().difference(lastActive);

      if (difference.inDays >= _daysToExpiration) {
        // Session expired due to inactivity
        await Supabase.instance.client.auth.signOut();
        await prefs.remove(_lastActiveKey);
        return false;
      }
    }

    // Session is valid, update timestamp
    await updateLastActive();
    return true;
  }

  /// Updates the last active timestamp to the current time.
  Future<void> updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear session data (useful on manual logout)
  Future<void> clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActiveKey);
  }
}
