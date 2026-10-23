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

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final p = Pal.of(context);
          final st = widget.state;
          final rate = st.rate(code)?.value(st.source);
          final amount = double.tryParse(input) ?? 0;
          final result = rate == null ? null : (toSdg ? amount * rate : amount / rate);
          final srcLabel = st.source == RateSource.parallel ? 'السوق الموازي' : 'سعر البنك';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              ScreenHeader(title: 'المحوّل', subtitle: Text('$srcLabel · اضغط للتبديل')),
              const SizedBox(height: 18),
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
              Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                Column(children: [
                  Panel(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: _Box('المبلغ', toSdg ? code : 'SDG', input, p.ink, p.muted, p.ink),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    decoration: BoxDecoration(color: p.tile, borderRadius: BorderRadius.circular(24)),
                    child: _Box('النتيجة', toSdg ? 'SDG' : code,
                        result == null ? '—' : fmt(result, toSdg ? 0 : 2), p.tileText, p.muted, p.tileText,
                        footer: rate == null ? null : '1 $code = ${fmt(rate)} SDG'),
                  ),
                ]),
                PositionedDirectional(
                  top: 82,
                  child: InkWell(
                    onTap: () => setState(() => toSdg = !toSdg),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Pal.coral,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.bg, width: 4),
                      ),
                      child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF14102B)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Directionality(
                textDirection: TextDirection.ltr,
                child: GridView.count(
                  crossAxisCount: 3, shrinkWrap: true, mainAxisSpacing: 8, crossAxisSpacing: 8,
                  childAspectRatio: 2.1, physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'])
                      InkWell(
                        onTap: () => _key(k),
                        borderRadius: BorderRadius.circular(16),
                        child: Center(child: Text(k, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500))),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

class _Box extends StatelessWidget {
  final String label, cur, value;
  final Color valueColor, muted, curColor;
  final String? footer;
  const _Box(this.label, this.cur, this.value, this.valueColor, this.muted, this.curColor, {this.footer});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 13, color: muted)),
          Num(cur, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: curColor)),
        ]),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Num(value, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, height: 1, color: valueColor)),
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Num(footer!, style: TextStyle(fontSize: 13, color: muted)),
          ),
        ],
      ]);
}
