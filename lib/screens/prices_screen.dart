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
          final others = currencies.where((c) => c.code != 'USD');
          return RefreshIndicator(
            onRefresh: state.refresh,
            color: Pal.coral,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              physics: const AlwaysScrollableScrollPhysics(),
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
                const SizedBox(height: 16),
                Row(children: [
                  for (final s in RateSource.values)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 24),
                      child: InkWell(
                        onTap: () => state.setSource(s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
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
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Panel(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Expanded(child: Text(state.error!, style: TextStyle(color: p.muted))),
                        TextButton(onPressed: state.refresh, child: const Text('إعادة المحاولة')),
                      ]),
                    ),
                  ),
                if (usd == null && state.error == null)
                  const Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(child: CircularProgressIndicator(color: Pal.coral)),
                  ),
                if (usd != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DetailScreen(state: state, code: 'USD'))),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('الدولار الأمريكي · USD · عرض التفاصيل ‹',
                            style: TextStyle(fontSize: 14, color: p.muted)),
                        const SizedBox(height: 4),
                        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                          Num(fmt(usd.value(state.source)),
                              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w700, height: 1)),
                          const SizedBox(width: 8),
                          Text('ج.س', style: TextStyle(fontSize: 16, color: p.muted)),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [_DeltaChip(usd, state.source)]),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Spark(state.series('USD')),
                  const SizedBox(height: 12),
                  Panel(
                    child: Column(children: [
                      for (final c in others)
                        if (state.rate(c.code) != null)
                          _Row(c, state.rate(c.code)!, state.source, isLast: c == others.last, onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) => DetailScreen(state: state, code: c.code)));
                          }),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      state.snapshot == null ? '' : 'آخر تحديث ${_ago(state.snapshot!.fetchedAt)} · المصدر status.sd',
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'الآن';
  if (d.inMinutes < 60) return 'منذ ${d.inMinutes} دقيقة';
  return 'منذ ${d.inHours} ساعة';
}

class _DeltaChip extends StatelessWidget {
  final Rate r;
  final RateSource s;
  const _DeltaChip(this.r, this.s);
  @override
  Widget build(BuildContext context) {
    final d = r.deltaPct(s);
    final txt = '${d >= 0 ? '+' : ''}${d.toStringAsFixed(1)}% عن ${s == RateSource.parallel ? 'البنك' : 'الموازي'}';
    return CoralChip(txt);
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
        height: 64,
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
