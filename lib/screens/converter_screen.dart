import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class ConverterScreen extends StatefulWidget {
  final AppState state;
  const ConverterScreen({super.key, required this.state});
  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String code = 'USD';
  bool toSdg = true; // المبلغ بعملة أجنبية ← جنيه سوداني
  String input = '100';

  static const _amountH = 112.0;
  static const _resultH = 136.0;

  void _key(String k) {
    setState(() {
      if (k == '⌫') {
        input = input.length <= 1 ? '0' : input.substring(0, input.length - 1);
      } else if (k == '.') {
        if (!input.contains('.')) input += '.';
      } else if (input.length < 12) {
        input = input == '0' ? k : input + k;
      }
    });
  }

  /// يفصل آلاف الجزء الصحيح مع الإبقاء على ما يكتبه المستخدم بعد الفاصلة
  String _shown(String s) {
    final parts = s.split('.');
    final i = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return parts.length > 1 ? '$i.${parts[1]}' : i;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final p = Pal.of(context);
          final st = widget.state;
          final rate = st.rate(code)?.value(st.source);
          final amount = double.tryParse(input) ?? 0;
          final result = rate == null ? null : (toSdg ? amount * rate : amount / rate);
          // padding.bottom يشمل أصلاً ارتفاع شريط التنقل (extendBody)
          final bottom = MediaQuery.of(context).padding.bottom + 12;

          return LayoutBuilder(builder: (context, box) {
            // ارتفاع العناصر الثابتة: الترويسة + الشرائح + البطاقتان + الفراغات
            const fixedTop = 40 + 16 + 44 + 16 + _amountH + 8 + _resultH + 12;
            final avail = box.maxHeight - 20 - bottom;
            final double keyH = ((avail - fixedTop) / 4).clamp(52.0, 84.0).toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                ScreenHeader(title: 'المحوّل', subtitle: const SizedBox.shrink()),
                const SizedBox(height: 16),
                SizedBox(
                  height: 44,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final c in currencies)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: InkWell(
                          onTap: () => setState(() => code = c.code),
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
                                  color: code == c.code ? const Color(0xFF14102B) : p.muted,
                                )),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: _amountH + 8 + _resultH,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Column(children: [
                      SizedBox(
                        height: _amountH,
                        child: Panel(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: _Box('المبلغ', toSdg ? code : 'SDG', _shown(input), p.ink, p.muted, p.ink),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: _resultH,
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        decoration: BoxDecoration(color: p.tile, borderRadius: BorderRadius.circular(24)),
                        child: _Box(
                          'النتيجة',
                          toSdg ? 'SDG' : code,
                          result == null ? '—' : fmt(result, toSdg ? 0 : 2),
                          p.tileText, p.muted, p.tileText,
                          footer: rate == null ? null : '1 $code = ${fmt(rate)} SDG',
                        ),
                      ),
                    ]),
                    Positioned(
                      top: _amountH + 4 - 22,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Semantics(
                          button: true,
                          label: '