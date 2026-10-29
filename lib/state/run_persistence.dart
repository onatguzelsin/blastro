import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/polyomino/block_bag.dart';
import 'run_state.dart';
import 'run_state_codec.dart';

/// Overridden in `main()` once SharedPreferences is ready; null disables
/// auto-save (tests, previews).
final runPersistenceProvider = Provider<RunPersistence?>((ref) => null);

/// A run restored from disk at startup, if any.
final savedRunProvider = Provider<SavedRun?>((ref) => null);

/// Stores the active run as one JSON string so Android backgrounding or
/// process death never loses it.
class RunPersistence {
  RunPersistence(this._prefs);

  static const String key = 'blastro_active_run';

  final SharedPreferences _prefs;

  /// The saved run, or null if none exists or it is corrupt / from an
  /// incompatible version (a corrupt save is discarded).
  SavedRun? load() {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return RunStateCodec.decode(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _prefs.remove(key);
      return null;
    }
  }

  /// Lost runs are deleted instead of saved so they are not resumed.
  Future<void> save(RunState state, BlockBagSnapshot bag) {
    if (state.status == RunStatus.lost) return clear();
    return _prefs.setString(key, jsonEncode(RunStateCodec.encode(state, bag)));
  }

  Future<void> clear() => _prefs.remove(key);
}
