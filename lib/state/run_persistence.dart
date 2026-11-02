import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/polyomino/block_bag.dart';
import '../core/roguelite/run_mode.dart';
import 'run_state.dart';
import 'run_state_codec.dart';

/// Overridden in `main()` once SharedPreferences is ready; null disables
/// auto-save (tests, previews).
final runPersistenceProvider = Provider<RunPersistence?>((ref) => null);

/// A run restored from disk at startup, if any.
final savedRunProvider = Provider<SavedRun?>((ref) => null);

/// Stores each active run as one JSON string so Android backgrounding or
/// process death never loses it. A normal run and a Quick Play run have
/// SEPARATE slots: one never reads, overwrites or deletes the other.
class RunPersistence {
  RunPersistence(this._prefs);

  /// The normal run's slot.
  static const String key = 'blastro_active_run';

  /// The Quick Play run's slot.
  static const String quickPlayKey = 'blastro_quick_play_run';
  static const String bestKey = 'blastro_quick_play_best';

  final SharedPreferences _prefs;

  static String keyFor(RunMode mode) => mode.isQuickPlay ? quickPlayKey : key;

  /// The saved run in [mode]'s slot, or null if none exists or it is corrupt
  /// / from an incompatible version (a corrupt save is discarded).
  SavedRun? load([RunMode mode = RunMode.normal]) {
    final slot = keyFor(mode);
    final raw = _prefs.getString(slot);
    if (raw == null) return null;
    try {
      return RunStateCodec.decode(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _prefs.remove(slot);
      return null;
    }
  }

  /// Saves into the slot of [state]'s own mode. Lost runs are deleted instead
  /// of saved so they are not resumed.
  Future<void> save(RunState state, BlockBagSnapshot bag) {
    if (state.status == RunStatus.lost) return clear(state.mode);
    return _prefs.setString(
      keyFor(state.mode),
      jsonEncode(RunStateCodec.encode(state, bag)),
    );
  }

  Future<void> clear([RunMode mode = RunMode.normal]) =>
      _prefs.remove(keyFor(mode));

  /// The best Quick Play score so far (0 if none).
  int get bestQuickPlayScore => _prefs.getInt(bestKey) ?? 0;

  Future<void> saveBestQuickPlayScore(int score) =>
      _prefs.setInt(bestKey, score);
}
