import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class AlertsScreen extends StatelessWidget {
  final AppState state;
  const AlertsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final p = Pal.of(context);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              const ScreenHeader(title: 'التنبيهات', subtitle: Text('أبلغني عند وصول السعر لهدفك')),
              const SizedBox(height: 22),
              Panel(
                child: Column(children: [
                  _MoveRow(
                    icon: Icons.trending_up_rounded,
                    title: 'عند ارتفاع السعر',
                    sub: 'أي عملة يرتفع سعرها عن آخر تحديث',
                    value: state.notifyRise,
                    onChanged: state.setRise,
                    first: true,
                  ),
                  _MoveRow(
                    icon: Icons.trending_down_rounded,
                    title: 'عند نزول السعر',
                    sub: 'أي عملة ينزل سعرها عن آخر تحديث',
                    value: state.notifyFall,
                    onChanged: state.setFall,
                  ),
                ]),
              ),
              const SizedBox(height: 18),
              Text('تنبيهات بسعر محدد', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.muted)),
              const SizedBox(height: 10),
              if (state.alerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('لا توجد تنبيهات بعد', style: TextStyle(color: p.muted))),
                ),
              for (final a in state.alerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Dismissible(
                    key: ValueKey(a.id),
                    onDismissed: (_) => state.removeAlert(a.id),
                    background: Container(
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                      alignment: AlignmentDirectional.centerStart,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: p.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(children: [
                        CodeTile(a.code),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${nameOf(a.code)} · ${a.source == RateSource.parallel ? 'موازي' : 'بنك'}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            Num('${a.above ? '≥' : '≤'} ${fmt(a.target)}',
                                style: TextStyle(fontSize: 13, color: p.muted)),
                          ]),
                        ),
                        Switch(
                          value: a.enabled,
                          activeColor: Colors.white,
                          activeTrackColor: Pal.coral,
                          onChanged: (v) => state.toggleAlert(a, v),
                        ),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => showAlertDialogFor(context, state),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.border, width: 2),
                  ),
                  child: Text('+ تنبيه جديد',
                      style: TextStyle(color: p.tileText, fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              Text('تظهر التنبيهات داخل التطبيق عند تحديث الأسعار (كل دقيقة أثناء فتح التطبيق).',
                  style: TextStyle(fontSize: 12, color: p.muted)),
            ],
          );
        },
      );
}

Future<void> showAlertDialogFor(BuildContext context, AppState state, {String code = 'USD'}) {
  var c = code;
  var src = state.source;
  var above = true;
  final ctrl = TextEditingController(text: state.rate(code)?.value(state.source).toStringAsFixed(0) ?? '');
  return showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('تنبيه جديد'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: c,
            decoration: const InputDecoration(labelText: 'العملة'),
            items: [for (final x in currencies) DropdownMenuItem(value: x.code, child: Text('${x.nameAr} (${x.code})'))],
            onChanged: (v) => setS(() => c = v!),
          ),
          const SizedBox(height: 12),
          SegmentedButton<RateSource>(
            segments: const [
              ButtonSegment(value: RateSource.parallel, label: Text('موازي')),
              ButtonSegment(value: RateSource.bank, label: Text('بنك')),
            ],
            selected: {src},
            onSelectionChanged: (v) => setS(() => src = v.first),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('عند الارتفاع إلى')),
              ButtonSegment(value: false, label: Text('عند النزول إلى')),
            ],
            selected: {above},
            onSelectionChanged: (v) => setS(() => above = v.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'السعر المستهدف (ج.س)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final t = double.tryParse(ctrl.text.replaceAll(',', ''));
              if (t == null || t <= 0) return;
              state.addAlert(AlertRule(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                code: c, source: src, above: above, target: t,
              ));
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    ),
  );
}

class _MoveRow extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final bool value, first;
  final ValueChanged<bool> onChanged;
  const _MoveRow({
    required this.icon, required this.title, required this.sub,
    required this.value, required this.onChanged, this.first = false,
  });
  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: first ? Colors.transparent : p.divider)),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: p.tile, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: p.tileText),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(sub, style: TextStyle(fontSize: 12, color: p.muted)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: Colors.white, activeTrackColor: Pal.coral),
      ]),
    );
  }
}
