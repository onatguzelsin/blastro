import 'package:flame/components.dart';

import '../core/polyomino/polyomino_shape.dart';
import 'game_layout.dart';
import 'tray_piece_component.dart';

/// The bottom tray (3 slots, or 4 in Quick Play). Owns one
/// [TrayPieceComponent] per slot.
class TrayComponent extends Component {
  TrayComponent(GameLayout layout)
    : slots = [
        for (var i = 0; i < layout.traySlots; i++)
          TrayPieceComponent(i, layout),
      ];

  final List<TrayPieceComponent> slots;

  @override
  Future<void> onLoad() async => addAll(slots);

  /// Advances the animation clock of every slot.
  set time(double t) {
    for (final slot in slots) {
      slot.time = t;
    }
  }

  /// Mirrors run state: a null entry means that piece was already placed.
  void sync(List<Polyomino?> tray) {
    for (var i = 0; i < slots.length; i++) {
      slots[i].piece = tray[i];
    }
  }
}
