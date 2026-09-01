import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/draft_data.dart';
import '../constants/draft_constants.dart';

class DraftStorageService {
  final SharedPreferences _prefs;
  final Map<String, Timer> _debounceTimers = {};

  DraftStorageService(this._prefs);

  String _buildKey(String moduleKey) {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    return 'user_draft_${userId}_$moduleKey';
  }

  /// Guarda inmediatamente un borrador sin debounce
  Future<void> saveDraftNow(DraftData draft) async {
    try {
      final key = _buildKey(draft.moduleKey);
      final jsonString = draft.toJson();
      await _prefs.setString(key, jsonString);
      debugPrint('[DraftStorageService] Draft guardado para ${draft.moduleKey} (Tab: ${draft.tabIndex})');
    } catch (e) {
      debugPrint('[DraftStorageService] Error guardando borrador ${draft.moduleKey}: $e');
    }
  }

  /// Guarda un borrador aplicando debounce (por defecto 500ms)
  void saveDraftDebounced(DraftData draft, {Duration duration = DraftConstants.autoSaveDebounce}) {
    _debounceTimers[draft.moduleKey]?.cancel();
    _debounceTimers[draft.moduleKey] = Timer(duration, () {
      saveDraftNow(draft);
    });
  }

  /// Obtiene el borrador almacenado si existe
  Future<DraftData?> getDraft(String moduleKey) async {
    try {
      final key = _buildKey(moduleKey);
      final jsonString = _prefs.getString(key);
      if (jsonString == null || jsonString.isEmpty) return null;
      return DraftData.fromJson(jsonString);
    } catch (e) {
      debugPrint('[DraftStorageService] Error leyendo borrador $moduleKey: $e');
      return null;
    }
  }

  /// Verifica si existe un borrador
  bool hasDraft(String moduleKey) {
    final key = _buildKey(moduleKey);
    return _prefs.containsKey(key);
  }

  /// Elimina el borrador del módulo (al guardar en DB o al descartar)
  Future<void> clearDraft(String moduleKey) async {
    _debounceTimers[moduleKey]?.cancel();
    _debounceTimers.remove(moduleKey);
    try {
      final key = _buildKey(moduleKey);
      await _prefs.remove(key);
      debugPrint('[DraftStorageService] Borrador eliminado para $moduleKey');
    } catch (e) {
      debugPrint('[DraftStorageService] Error eliminando borrador $moduleKey: $e');
    }
  }

  /// Limpia todos los borradores del usuario actual (ej. al cerrar sesión)
  Future<void> clearAllUserDrafts() async {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? 'anonymous';
    final prefix = 'user_draft_$userId';
    final keys = _prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      await _prefs.remove(key);
    }
    debugPrint('[DraftStorageService] Todos los borradores del usuario han sido eliminados');
  }
}
