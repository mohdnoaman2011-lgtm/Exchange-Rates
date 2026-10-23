import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'detail_screen.dart';

class PricesScreen extends StatelessWidget {
  final AppState state;
  final VoidCallback onOpenConverter;
  const PricesScreen({super.key, required this.state, required this.onOpenConverter});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final p = Pal.of(context);
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final usd = state.rate('USD');
          final others = currencies.where((c) => c.code != 'USD' && state.rate(c.code) != null).toList();
          final series = state.series('USD');
          final showSpark = series.length >= 2 && series.any((v) => v != series.first);
          final bottom = MediaQuery.of(context).padding.bottom + 96;

          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ScreenHeader(
                  title: 'الأسعار',
                  subtitle: Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: state.error != null
                            ? Colors.redAccent
                            : state.loading ? Colors.amber : const Color(0xFF34D399),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(state.error != null ? 'غير متصل' : 'مباشر · مقابل الجنيه السوداني'),
                  ]),
                  trailing: SquareButton(
                    icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    label: 'تبديل المظهر',
                    onTap: () => state.toggleTheme(isDark),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  for (final s in RateSource.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 24),
                      child: InkWell(
                        onTap: () => state.setSource(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 3,
                                color: state.source == s ? Pal.coral : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Text(s == RateSource.parallel ? 'موازي' : 'بنك',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: state.source == s ? FontWeight.w700 : FontWeight.w500,
                                color: state.source == s ? p.ink : p.muted,
                              )),
                        ),
                      ),
                    ),
                ]),
                if (usd == null)
                  Expanded(
                    child: Center(
                      child: state.error != null
                          ? TextButton(onPressed: state.refresh, child: const Text('إعادة المحاولة'))
                          : const CircularProgressIndicator(color: Pal.coral),
                    ),
                  )
                else ...[
                  InkWell(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DetailScreen(state: state, code: 'USD'))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('الدولار الأمريكي · USD · عرض التفاصيل ‹',
                            style: TextStyle(fontSize: 14, color: p.muted)),
                        const SizedBox(height: 2),
                        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          Num(fmt(usd.value(state.source)),
                              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, height: 1.1)),
                          const SizedBox(width: 8),
                          Text('ج.س', style: TextStyle(fontSize: 16, color: p.muted)),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [_DeltaChip(usd, state.source)]),
                      ]),
                    ),
                  ),
                  if (showSpark) Spark(series, height: 48),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Panel(
                      child: Column(children: [
                        for (var i = 0; i < others.length; i++)
                          Expanded(
                            child: _Row(others[i], state.rate(others[i].code)!, state.source,
                                isLast: i == others.length - 1, onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => DetailScreen(state: state, code: others[i].code)));
                            }),
                          ),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'قد تختلف الأسعار الفعلية من صراف لآخر.\nتجمع الأسعار من مصادر مختلفة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, height: 1.5, color: p.muted),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

class _DeltaChip extends StatelessWidget {
  final Rate r;
  final RateSource s;
  const _DeltaChip(this.r, this.s);
  @override
  Widget build(BuildContext context) {
    final d = r.deltaPct(s);
    return CoralChip('${d >= 0 ? '+' : ''}${d.toStringAsFixed(1)}% عن ${s == RateSource.parallel ? 'البنك' : 'الموازي'}');
  }
}

class _Row extends StatelessWidget {
  final Currency c;
  final Rate r;
  final RateSource s;
  final bool isLast;
  final VoidCallback onTap;
  const _Row(this.c, this.r, this.s, {required this.isLast, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : p.divider)),
        ),
        child: Row(children: [
          CodeTile(c.code),
          const SizedBox(width: 12),
          Expanded(child: Text(c.nameAr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          Num(fmt(r.value(s)), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}
