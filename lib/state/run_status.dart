/// blindSelect (pick a blind) -> playing -> blindCleared (cash out) ->
/// shopping -> blindSelect (next blind). Beating the Ante 8 Finisher pauses
/// at [victory] first. Quick Play stays in [playing] forever.
enum RunStatus { blindSelect, playing, blindCleared, shopping, victory, lost }
