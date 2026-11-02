import 'str_key.dart';
import 'str_keys_game.dart';
import 'str_keys_help.dart';
import 'str_keys_menu.dart';

/// Every translatable key in the app. Add a new key enum here.
final List<StrKey> allStrKeys = List.unmodifiable([
  ...MenuStr.values,
  ...HudStr.values,
  ...FlowStr.values,
  ...HelpStr.values,
]);
