import 'dart:convert';

import 'package:blastro/core/polyomino/polyomino_catalog.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/state/run_state_codec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<RunPersistence> _store([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return RunPersistence(await SharedPreferences.getInstance());
}

ProviderContainer _container(RunPersistence? store, {SavedRun? saved}) {
  final c = ProviderContainer(
    overrides: [
      runPersistenceProvider.overrideWithValue(store),
      savedRunProvider.overrideWithValue(saved),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('a corrupt or old-version save is discarded', () async {
    final bad = await _store({RunPersistence.key: '{not json'});
    expect(bad.load(), isNull);
    expect(
      (await SharedPreferences.getInstance()).containsKey(RunPersistence.key),
      isFalse,
    );
    final old = await _store({
      RunPersistence.key: jsonEncode({'v': 0}),
    });
    expect(old.load(), isNull);
    final fresh = await _store();
    final prefs = await SharedPreferences.getInstance();
    final c = _container(fresh);
    c.read(runProvider.notifier).newRun(1);
    final json = jsonDecode(
      prefs.getString(RunPersistence.key)!,
    ) as Map<String, dynamic>;
    json['jokers'] = ['joker_does_not_exist'];
    await prefs.setString(RunPersistence.key, jsonEncode(json));
    expect(fresh.load(), isNull);
  });

  test('a lost run deletes the save instead of keeping it', () async {
    final store = await _store();
    final c = _container(store);
    final n = c.read(runProvider.notifier)..newRun(2);
    expect(store.load(), isNotNull);
    n.debugSet(
      c
          .read(runProvider)
          .copyWith(
            tray: [PolyominoCatalog.byId('dot'), null, null],
            traysRemaining: 1,
          ),
    );
    n.placePiece(0, 4, 4);
    expect(c.read(runProvider).status, RunStatus.lost);
    expect(store.load(), isNull);
  });

  test('with no persistence configured nothing crashes', () {
    final c = _container(null);
    final n = c.read(runProvider.notifier)..newRun(9);
    n.saveNow();
    expect(n.placePiece(0, 0, 0), isTrue);
  });
}
