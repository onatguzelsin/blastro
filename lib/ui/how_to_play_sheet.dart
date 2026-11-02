import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/app_strings.dart';
import '../core/i18n/str_keys_help.dart';
import '../core/i18n/supported_language.dart';
import '../state/locale_provider.dart';

/// (title, body) pairs shown in the How to Play modal, in [strings]'s
/// language (English if omitted).
List<(String, String)> howToPlaySections([AppStrings? strings]) {
  final s = strings ?? AppStrings(Languages.english);
  return [
    (s.t(HelpStr.goalHead), s.t(HelpStr.goalBody)),
    (s.t(HelpStr.placingHead), s.t(HelpStr.placingBody)),
    (s.t(HelpStr.scoringHead), s.t(HelpStr.scoringBody)),
    (s.t(HelpStr.comboHead), s.t(HelpStr.comboBody)),
    (s.t(HelpStr.traysHead), s.t(HelpStr.traysBody)),
    (s.t(HelpStr.blindsHead), s.t(HelpStr.blindsBody)),
    (s.t(HelpStr.shopHead), s.t(HelpStr.shopBody)),
    (s.t(HelpStr.losingHead), s.t(HelpStr.losingBody)),
  ];
}

/// Opens the How to Play modal.
Future<void> showHowToPlay(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (context) => const HowToPlaySheet(),
);

class HowToPlaySheet extends ConsumerWidget {
  const HowToPlaySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.88,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: const BoxDecoration(
        color: Color(0xFF171B2B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  strings.t(HelpStr.title),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (title, body) in howToPlaySections(strings)) ...[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD54F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        body,
                        style: const TextStyle(fontSize: 14, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
