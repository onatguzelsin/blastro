import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_menu.dart';
import '../state/locale_provider.dart';
import 'language_select_modal.dart';
import 'menu_button.dart';

/// "Language / Dil" on the Main Menu, showing the language in use.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final active = ref.watch(languageProvider);
    return MenuButton(
      label: strings.t(MenuStr.language),
      subtitle: '${active.badge} · ${active.nativeName}',
      onPressed: () => showLanguageModal(context),
    );
  }
}
