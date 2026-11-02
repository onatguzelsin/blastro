import 'package:flutter/material.dart';

/// The launcher-icon block mark, drawn with plain containers.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key});

  static const _pattern = [
    [0xFF5C8DFF, 0xFF5C8DFF, 0xFF5C8DFF],
    [0xFFEF5350, null, 0xFFFFD54F],
    [0xFFEF5350, 0xFFEF5350, 0xFFFFD54F],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _pattern)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in row)
                Container(
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: c == null ? null : Color(c),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
