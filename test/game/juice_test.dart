import 'package:blastro/core/scoring/score_step_event.dart';
import 'package:blastro/game/haptic_throttle.dart';
import 'package:blastro/game/juice_effects.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CameraShake', () {
    test('no shake for 0 or 1 line, shake for 2 or more', () {
      expect(CameraShake.steps(0), isEmpty);
      expect(CameraShake.steps(1), isEmpty);
      expect(CameraShake.steps(2), isNotEmpty);
    });

    test('amplitude grows with lines and is capped', () {
      expect(CameraShake.amplitude(2), 3);
      expect(CameraShake.amplitude(4), 6);
      expect(CameraShake.amplitude(40), 10);
      expect(CameraShake.amplitude(5), greaterThan(CameraShake.amplitude(3)));
    });

    test('moves return the camera to where it started', () {
      for (final lines in [2, 3, 6, 12]) {
        final total = CameraShake.steps(lines)
            .fold<Vector2>(Vector2.zero(), (sum, m) => sum + m);
        expect(total.x, closeTo(0, 1e-9), reason: '$lines lines');
        expect(total.y, closeTo(0, 1e-9), reason: '$lines lines');
      }
    });

    test('is deterministic', () {
      expect(CameraShake.steps(3), CameraShake.steps(3));
    });
  });

  testWidgets('a double clear shakes the viewfinder and settles back', (
    t,
  ) async {
    final game = FlameGame();
    await t.pumpWidget(GameWidget(game: game));
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    final finder = game.camera.viewfinder;
    final start = finder.position.clone();
    CameraShake.shake(finder, 3);
    var maxOffset = 0.0;
    for (var i = 0; i < 40; i++) {
      await t.pump(const Duration(milliseconds: 16));
      final d = (finder.position - start).length;
      if (d > maxOffset) maxOffset = d;
    }
    expect(maxOffset, greaterThan(1));
    expect((finder.position - start).length, lessThan(1e-3));
  });

  testWidgets('a single line does not shake', (t) async {
    final game = FlameGame();
    await t.pumpWidget(GameWidget(game: game));
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    CameraShake.shake(game.camera.viewfinder, 1);
    await t.pump(const Duration(milliseconds: 16));
    expect(
      game.camera.viewfinder.children.whereType<SequenceEffect>(),
      isEmpty,
    );
  });

  testWidgets('CellBounceEffect pops via ScaleEffect then removes itself', (
    t,
  ) async {
    final game = FlameGame();
    await t.pumpWidget(GameWidget(game: game));
    await t.pump();
    await t.pump(const Duration(milliseconds: 16));
    final bounce = CellBounceEffect(center: Vector2(50, 50), cell: 40);
    game.world.add(bounce);
    await t.pump(const Duration(milliseconds: 16));
    await t.pump(const Duration(milliseconds: 16));
    expect(bounce.children.whereType<ScaleEffect>(), isNotEmpty);
    var peak = 1.0;
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 16));
      if (bounce.scale.x > peak) peak = bounce.scale.x;
    }
    expect(peak, greaterThan(1.1));
    expect(peak, lessThanOrEqualTo(CellBounceEffect.peakScale + 1e-6));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 16));
    }
    expect(bounce.isMounted, isFalse);
  });

  group('HapticThrottle', () {
    test('none never fires', () {
      expect(HapticThrottle().shouldFire(HapticIntensity.none, 0), isFalse);
    });

    test('same intensity is limited to one per gap', () {
      final t = HapticThrottle();
      expect(t.shouldFire(HapticIntensity.light, 0.00), isTrue);
      expect(t.shouldFire(HapticIntensity.light, 0.03), isFalse);
      expect(t.shouldFire(HapticIntensity.light, 0.07), isTrue);
    });

    test('escalating intensity always fires', () {
      final t = HapticThrottle();
      expect(t.shouldFire(HapticIntensity.light, 0.00), isTrue);
      expect(t.shouldFire(HapticIntensity.medium, 0.01), isTrue);
      expect(t.shouldFire(HapticIntensity.heavy, 0.02), isTrue);
      expect(t.shouldFire(HapticIntensity.heavy, 0.03), isFalse);
    });

    test('dropping back down is throttled; reset starts fresh', () {
      final t = HapticThrottle();
      t.shouldFire(HapticIntensity.heavy, 0);
      expect(t.shouldFire(HapticIntensity.light, 0.02), isFalse);
      t.reset();
      expect(t.shouldFire(HapticIntensity.light, 0.02), isTrue);
    });
  });
}
