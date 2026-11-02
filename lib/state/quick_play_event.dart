import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_game.dart';
import '../core/i18n/supported_language.dart';

/// What a Quick Play move or settle did beyond scoring: trays refunded for
/// cleared cells, a Second Wind (fresh trays when they ran out) or a Rescue
/// (rows cleared because nothing fit). Drives the floating HUD callouts.
class QuickPlayEvent {
  const QuickPlayEvent({
    this.trayRefund = 0,
    this.windTrays = 0,
    this.rescuedRows = 0,
  });

  /// "Nothing happened". Always this one instance, so `identical` works.
  static const QuickPlayEvent none = QuickPlayEvent();

  /// Trays granted for the cells this move cleared.
  final int trayRefund;

  /// Trays granted by a Second Wind (0 if none).
  final int windTrays;

  /// Rows cleared by a Rescue (0 if none).
  final int rescuedRows;

  bool get isEmpty => trayRefund == 0 && windTrays == 0 && rescuedRows == 0;

  QuickPlayEvent copyWith({int? windTrays, int? rescuedRows}) => QuickPlayEvent(
    trayRefund: trayRefund,
    windTrays: windTrays ?? this.windTrays,
    rescuedRows: rescuedRows ?? this.rescuedRows,
  );

  /// The floating texts, most exciting first, in [strings]'s language
  /// (English if omitted).
  List<String> callouts([AppStrings? strings]) {
    final s = strings ?? AppStrings(Languages.english);
    return [
      if (trayRefund > 0) s.t(HudStr.calloutTrays, {'n': trayRefund}),
      if (windTrays > 0) s.t(HudStr.calloutWind, {'n': windTrays}),
      if (rescuedRows > 0)
        s.t(
          rescuedRows == 1 ? HudStr.calloutRescueOne : HudStr.calloutRescueMany,
          {'n': rescuedRows},
        ),
    ];
  }
}
