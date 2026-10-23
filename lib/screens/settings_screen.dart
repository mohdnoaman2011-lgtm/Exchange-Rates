import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsScreen extends StatelessWidget {
  final AppState state;
  const SettingsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final p = Pal.of(context);
          Widget row(String label, Widget trailing, {bool first = false}) => Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: first ? Colors.transparent : p.divider)),
                ),
                child: Row(children: [
                  Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                  trailing,
                ]),
              );
          Widget seg<T>(T value, List<(T, String)> items, ValueChanged<T> on) => Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: p.tile, borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final (v, l) in items)
                    InkWell(
                      onTap: () => on(v),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: v == value ? Pal.coral : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(l,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                              color: v == value ? const Color(0xFF14102B) : p.muted,
                            )),
                      ),
                    ),
                ]),
              );
          Widget sw(bool v, ValueChanged<bool> on) =>
              Switch(value: v, onChanged: on, activeColor: Colors.white, activeTrackColor: Pal.coral);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              const ScreenHeader(title: 'الإعدادات', subtitle: Text('خصّص التطبيق')),
              const SizedBox(height: 22),
              Panel(
                child: Column(children: [
                  row(
                    'المظهر',
                    seg<ThemeMode>(
                      state.themeMode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark,
                      const [(ThemeMode.dark, 'داكن'), (ThemeMode.light, 'فاتح')],
                      state.setTheme,
                    ),
                    first: true,
                  ),
                  row(
                    'المصدر الافتراضي',
                    seg<RateSource>(
                      state.source,
                      const [(RateSource.parallel, 'موازي'), (RateSource.bank, 'بنك')],
                      state.setSource,
                    ),
                  ),
                  row('التحديث التلقائي', sw(state.autoRefresh, state.setAuto)),
                  row(
                    'تحديث الآن',
                    state.loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Pal.coral))
                        : IconButton(onPressed: state.refresh, icon: Icon(Icons.refresh_rounded, color: p.muted)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Panel(
                child: Column(children: [
                  row('المصدر', Text('status.sd', style: TextStyle(fontSize: 14, color: p.muted)), first: true),
                  row('الإصدار', Num('v1.0', style: TextStyle(fontSize: 14, color: p.muted))),
                ]),
              ),
            ],
          );
        },
      );
}
