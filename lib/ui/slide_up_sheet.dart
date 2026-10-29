import 'package:flutter/material.dart';

/// Bottom sheet that slides up over a dimmed barrier. Used as a Flame game
/// overlay (so it can be driven by run state) instead of a route.
class SlideUpSheet extends StatelessWidget {
  const SlideUpSheet({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.maxHeightFactor = 0.86,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * maxHeightFactor;
    return Stack(
      children: [
        const ModalBarrier(color: Colors.black54, dismissible: false),
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) =>
                FractionalTranslation(translation: Offset(0, t), child: child),
            child: Material(
              color: const Color(0xFF171B2B),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Spacer(),
                            ?trailing,
                          ],
                        ),
                        const SizedBox(height: 8),
                        Flexible(child: SingleChildScrollView(child: child)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
