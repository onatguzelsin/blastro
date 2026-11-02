import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_menu.dart';
import '../core/i18n/supported_language.dart';
import '../state/locale_provider.dart';

/// Opens the language list. Picking a row switches the whole app at once.
Future<void> showLanguageModal(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF171B2B),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const LanguageSelectModal(),
    );

/// A scrollable list of every registered language, so adding a language to
/// `Languages.all` adds a row here with no UI change.
class LanguageSelectModal extends ConsumerWidget {
  const LanguageSelectModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final active = ref.watch(languageProvider);
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                strings.t(MenuStr.languageTitle),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final l in Languages.all)
                    _LanguageRow(
                      language: l,
                      selected: l.code == active.code,
                      onTap: () {
                        ref.read(languageProvider.notifier).select(l);
                        Navigator.of(context).maybePop();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final SupportedLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey('language_${language.code}'),
      leading: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          language.badge,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      title: Text(
        language.nativeName,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF69F0AE))
          : null,
      onTap: onTap,
    );
  }
}
