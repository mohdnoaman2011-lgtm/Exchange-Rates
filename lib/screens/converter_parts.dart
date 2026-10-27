import 'package:flutter/material.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// شرائح اختيار العملة
class CurrencyChips extends StatelessWidget {
  final String code;
  final ValueChanged<String> onSelect;
  const CurrencyChips({super.key, required this.code, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return SizedBox(
      height: 44,
      child: ListView(scrollDirection: Axis.horizontal, children: [
        for (final c in currencies)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: InkWell(
              onTap: () => onSelect(c.code),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: code == c.code ? Pal.coral : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: code == c.code ? Pal.coral : p.border),
                ),
                child: Text(c.code,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: code == c.code ? FontWeight.w700 : FontWeight.w500,
                      color: code == c.code ? const Color(0xFF002463) : p.muted,
                    )),
              ),
            ),
          ),
      ]),
    );
  }
}

/// زر تبديل الاتجاه
class SwapButton extends StatelessWidget {
  final VoidCallback onTap;
  const SwapButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Semantics(
      button: true,
      label: 'تبديل الاتجاه',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Pal.gold,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.bg, width: 4),
          ),
          child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF002463)),
        ),
      ),
    );
  }
}