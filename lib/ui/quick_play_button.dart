import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n/str_keys_menu.dart';
import '../state/locale_provider.dart';

/// The big gold Quick Play button at the top of the Main Menu. Shows your best
/// score, or how far your saved Quick Play run is.
class QuickPlayButton extends ConsumerWidget {
  const QuickPlayButton({
    super.key,
    required this.onPressed,
    required this.subtitle,
    required this.best,
  });

  final VoidCallback onPressed;

  /// "Instant arcade run" or the resume details.
  final String subtitle;
  final int best;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider).t;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFDE047)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                blurRadius: 18,
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt, size: 38, color: Color(0xFF1B1300)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(MenuStr.quickPlay),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Color(0xFF1B1300),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3B2A00),
                      ),
                    ),
                  ],
                ),
              ),
              if (best > 0)
                Column(
                  children: [
                    Text(
                      t(MenuStr.best),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3B2A00),
                      ),
                    ),
                    Text(
                      '$best',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B1300),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
