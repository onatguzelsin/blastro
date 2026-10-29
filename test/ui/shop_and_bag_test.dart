import 'package:blastro/core/grid/grid_cell.dart';
import 'package:blastro/core/grid/grid_matrix.dart';
import 'package:blastro/core/roguelite/joker_registry.dart';
import 'package:blastro/core/roguelite/shop_generator.dart';
import 'package:blastro/state/run_notifier.dart';
import 'package:blastro/state/run_persistence.dart';
import 'package:blastro/state/run_state.dart';
import 'package:blastro/ui/bag_modal.dart';
import 'package:blastro/ui/cash_out_sheet.dart';
import 'package:blastro/ui/lifecycle_auto_save.dart';
import 'package:blastro/ui/shop_sheet.dart';
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

const _plainItem = ShopItem(id: 'joker_plain', isJoker: true, price: 4);
const _cardItem = ShopItem(id: 'chisel_bonus', isJoker: false, price: 3);

RunState _shopping(RunState s, {int gold = 10}) => s.copyWith(
  status: RunStatus.shopping,
  gold: gold,
  shop: const ShopState(stock: [_plainItem, _cardItem]),
);

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

  testWidgets('Shop: buy a joker, reroll, and advance to the next blind', (
    t,
  ) async {
    final c = await _pump(t, const ShopSheet(), setup: _shopping);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Plain Joker'), findsOneWidget);
    expect(find.text('Chisel: Bonus'), findsOneWidget);
    expect(find.text('Reroll  \$5'), findsOneWidget);

    await t.tap(find.text('Buy \$4'));
    await t.pumpAndSettle();
    expect(c.read(runProvider).jokers.single.id, 'joker_plain');
    expect(c.read(runProvider).gold, 6);
    expect(find.text('Sell Plain Joker +\$2'), findsOneWidget);

    await t.tap(find.text('Reroll  \$5'));
    await t.pumpAndSettle();
    expect(c.read(runProvider).shop!.rerolls, 1);
    expect(c.read(runProvider).gold, 1);
    expect(find.text('Reroll  \$6'), findsOneWidget);

    await t.ensureVisible(find.text('Next Blind'));
    await t.tap(find.text('Next Blind'));
    await t.pump();
    expect(c.read(runProvider).status, RunStatus.playing);
    expect(c.read(runProvider).blind.name, 'big');
  });

  testWidgets('Shop disables buying when you cannot afford it', (t) async {
    final c = await _pump(
      t,
      const ShopSheet(),
      setup: (s) => _shopping(s, gold: 2),
    );
    final button = t.widget<FilledButton>(
      find.widgetWithText(FilledButton, '\$4'),
    );
    expect(button.onPressed, isNull);
    await t.tap(find.text('\$4'), warnIfMissed: false);
    expect(c.read(runProvider).jokers, isEmpty);
  });

  testWidgets('Shop can sell a joker and use a held card', (t) async {
    final c = await _pump(
      t,
      const ShopSheet(),
      setup: (s) => _shopping(s).copyWith(
        jokers: [JokerRegistry.byId('joker_plain').joker],
        consumables: ['blueprint_single'],
      ),
    );
    await t.ensureVisible(find.text('Use'));
    await t.tap(find.text('Use'));
    await t.pump();
    expect(c.read(runProvider).consumables, isEmpty);
    await t.tap(find.text('Sell Plain Joker +\$2'));
    await t.pump();
    expect(c.read(runProvider).jokers, isEmpty);
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
