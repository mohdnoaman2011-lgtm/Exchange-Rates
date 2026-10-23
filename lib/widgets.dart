import 'dart:math';
import 'package:flutter/material.dart';
import 'theme.dart';

class Num extends StatelessWidget {
  final String text;
  final TextStyle? style;
  const Num(this.text, {super.key, this.style});
  @override
  Widget build(BuildContext context) => Text(
        text,
        textDirection: TextDirection.ltr,
        style: (style ?? const TextStyle()).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      );
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const Panel({super.key, required this.child, this.padding = EdgeInsets.zero});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }
}

class CodeTile extends StatelessWidget {
  final String code;
  const CodeTile(this.code, {super.key});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      width: 40, height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.tile, borderRadius: BorderRadius.circular(12)),
      child: Text(code, style: TextStyle(color: p.tileText, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

class CoralChip extends StatelessWidget {
  final String text;
  const CoralChip(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: Pal.coral, borderRadius: BorderRadius.circular(99)),
        child: Text(text,
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Color(0xFF14102B), fontSize: 13, fontWeight: FontWeight.w700)),
      );
}

class ScreenHeader extends StatelessWidget {
  final String title;
  final Widget subtitle;
  final Widget? leading, trailing;
  const ScreenHeader({super.key, required this.title, required this.subtitle, this.leading, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      if (leading != null) ...[leading!, const SizedBox(width: 12)],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          DefaultTextStyle(
            style: TextStyle(fontSize: 13, color: Pal.of(context).muted),
            child: subtitle,
          ),
        ]),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

class SquareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const SquareButton({super.key, required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Semantics(
      button: true, label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.border),
          ),
          child: Icon(icon, size: 20, color: p.ink),
        ),
      ),
    );
  }
}

class PillNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const PillNav({super.key, required this.index, required this.onTap});
  static const labels = ['الأسعار', 'المحوّل', 'الإعدادات'];
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 16),
      child: Center(
        heightFactor: 1,
        child: Container(
          width: 350, height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: p.navBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.navBg == p.card ? p.border : Colors.transparent),
          ),
          child: Row(children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => onTap(i),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i == index ? Pal.coral : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(labels[i],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                            color: i == index ? p.navInk : p.navInactive,
                          )),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class Spark extends StatelessWidget {
  final List<double> values;
  final double height;
  const Spark(this.values, {super.key, this.height = 96});
  @override
  Widget build(BuildContext context) => SizedBox(
        height: height, width: double.infinity,
        child: CustomPaint(painter: _SparkPainter(values)),
      );
}

class _SparkPainter extends CustomPainter {
  final List<double> v;
  _SparkPainter(this.v);
  @override
  void paint(Canvas canvas, Size size) {
    final data = v.length >= 2 ? v : [v.isEmpty ? 0.0 : v.first, v.isEmpty ? 0.0 : v.first];
    final mn = data.reduce(min), mx = data.reduce(max);
    final flat = mx == mn;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      final y = flat ? size.height / 2 : size.height - 6 - (data[i] - mn) / (mx - mn) * (size.height - 12);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fill, Paint()..color = Pal.coral.withAlpha(40));
    canvas.drawPath(
      path,
      Paint()
        ..color = Pal.coral
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter o) => o.v != v;
}
