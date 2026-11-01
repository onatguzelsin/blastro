import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/bag_modal.dart';
import 'package:blastro/ui/cash_out_sheet.dart';
import 'package:blastro/ui/lifecycle_auto_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(
  WidgetTester t,
  Widget child, {
  RunState Function(RunState)? setup,
  RunPersistence? store,
}) async {
  await t.binding.setSurfaceSize(const Size(400, 900));
  addTearDown(() => t.binding.setSurfaceSize(null));
  final c = ProviderContainer(
    overrides: [runPersistenceProvider.overrideWithValue(store)],
  );
  addTearDown(c.dispose);
  final n = c.read(runProvider.notifier)..newRun(1);
  if (setup != null) n.debugSet(setup(c.read(runProvider)));
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await t.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('Cash Out shows reward, unused trays, interest and total', (
    t,
  ) async {
    final c = await _pump(
      t,
      const CashOutSheet(),
      setup: (s) => s.copyWith(
        status: RunStatus.blindCleared,
        gold: 12,
        traysRemaining: 4,
      ),
    );
    expect(find.text('Blind Defeated!'), findsOneWidget);
    expect(find.text('Blind reward'), findsOneWidget);
    expect(find.text('+\$4'), findsOneWidget);
    expect(find.text('Unused trays'), findsOneWidget);
    expect(find.text('+\$3'), findsOneWidget);
    expect(find.text('+\$2'), findsNWidgets(1), reason: 'interest on \$12');
    expect(find.text('Cash Out  \$9'), findsOneWidget);
    await t.tap(find.text('Cash Out  \$9'));
    await t.pump();
    expect(c.read(runProvider).status, RunStatus.shopping);
    expect(c.read(runProvider).gold, 21);
  });

  testWidgets('Bag modal shows remaining counts and enhanced cells', (t) async {
    var closed = false;
    await _pump(
      t,
      BagModal(onClose: () => closed = true),
      setup: (s) => s.copyWith(
        grid: GridMatrix.fromAscii(['XX'])
          ..setCell(0, 0, const GridCell(enhancement: CellEnhancement.steel))
          ..setCell(
            0,
            1,
            const GridCell(
              enhancement: CellEnhancement.steel,
              edition: CellEdition.foil,
            ),
          ),
      ),
    );
    expect(find.text('Block Bag'), findsOneWidget);
    expect(
      find.textContaining('21 of 24'),
      findsOneWidget,
      reason: '3 in the tray',
    );
    expect(find.textContaining('steel x2'), findsOneWidget);
    expect(find.textContaining('foil x1'), findsOneWidget);
    await t.tap(find.byIcon(Icons.close));
    expect(closed, isTrue);
  });

  test('BagModal helpers', () {
    final counts = BagModal.countsById([]);
    expect(counts.length, 24);
    expect(counts.values.every((v) => v == 0), isTrue);
    expect(BagModal.enhancementSummary(GridMatrix()), isEmpty);
  });

  testWidgets('pausing the app saves the run', (t) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await _pump(
      t,
      const LifecycleAutoSave(child: SizedBox()),
      store: RunPersistence(prefs),
    );
    await prefs.remove(RunPersistence.key);
    expect(prefs.containsKey(RunPersistence.key), isFalse);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    expect(prefs.containsKey(RunPersistence.key), isTrue);
    await prefs.remove(RunPersistence.key);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(
      prefs.containsKey(RunPersistence.key),
      isFalse,
      reason: 'resuming does not need a save',
    );
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.detached);
    expect(prefs.containsKey(RunPersistence.key), isTrue);
  });
}
