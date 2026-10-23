import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class DetailScreen extends StatelessWidget {
  final AppState state;
  final String code;
  const DetailScreen({super.key, required this.state, required this.code});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final p = Pal.of(context);
          final r = state.rate(code);
          return Scaffold(
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  ScreenHeader(
                    title: nameOf(code),
                    subtitle: Text('$code · مقابل الجنيه السوداني'),
                    leading: SquareButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      label: 'رجوع',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  if (r == null)
                    const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('لا توجد بيانات')))
                  else ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      for (final s in RateSource.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () => state.setSource(s),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: state.source == s ? Pal.coral : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: state.source == s ? Pal.coral : p.border),
                                ),
                                child: Text(s == RateSource.parallel ? 'موازي' : 'بنك',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: state.source == s ? FontWeight.w700 : FontWeight.w500,
                                      color: state.source == s ? const Color(0xFF14102B) : p.muted,
                                    )),
                              ),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 20),
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Num(fmt(r.value(state.source)),
                          style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, height: 1)),
                      const SizedBox(width: 8),
                      Text('ج.س', style: TextStyle(fontSize: 16, color: p.muted)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      CoralChip(
                        '${r.deltaPct(state.source) >= 0 ? '+' : ''}${r.deltaPct(state.source).toStringAsFixed(1)}% '
                        'عن ${state.source == RateSource.parallel ? 'البنك' : 'الموازي'}',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Spark(state.series(code), height: 160),
                    Center(
                      child: Text('يتراكم الرسم مع كل تحديث للأسعار على جهازك',
                          style: TextStyle(fontSize: 12, color: p.muted)),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _Stat('السوق الموازي', fmt(r.parallel))),
                      const SizedBox(width: 10),
                      Expanded(child: _Stat('سعر البنك', fmt(r.bank))),
                    ]),
                  ],
                ],
              ),
            ),
          );
        },
      );
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: Pal.of(context).muted)),
          const SizedBox(height: 4),
          Num(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ]),
      );
}
