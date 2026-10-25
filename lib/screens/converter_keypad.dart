import 'package:flutter/material.dart';
import '../theme.dart';

/// لوحة الأرقام
class Keypad extends StatelessWidget {
  final double keyH;
  final ValueChanged<String> onKey;
  const Keypad({super.key, required this.keyH, required this.onKey});

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        for (final row in _rows)
          SizedBox(
            height: keyH,
            child: Row(children: [
              for (final k in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: InkWell(
                      onTap: () => onKey(k),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.border),
                        ),
                        child: k == '⌫'
                            ? Icon(Icons.backspace_outlined, color: p.ink)
                            : Text(k, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
      ]),
    );
  }
}