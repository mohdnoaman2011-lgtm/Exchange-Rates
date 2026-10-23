import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../notifications.dart';
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
          // padding.bottom يشمل أصلاً ارتفاع شريط التنقل (extendBody)
          final bottom = MediaQuery.of(context).padding.bottom + 12;

          Widget row(String label, Widget trailing, {bool first = false, String? sub}) => Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: first ? Colors.transparent : p.divider)),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      if (sub != null) Text(sub, style: TextStyle(fontSize: 12, color: p.muted)),
                    ]),
                  ),
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
                        height: 32,
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

          Widget sw(bool v, ValueChanged<bool> on) => Switch(
                value: v,
                onChanged: on,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeColor: Colors.white,
                activeTrackColor: Pal.coral,
                inactiveThumbColor: p.muted,
                inactiveTrackColor: p.tile,
                trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
              );

          return ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
            children: [
              const ScreenHeader(title: 'الإعدادات', subtitle: Text('خصّص التطبيق')),
              const SizedBox(height: 16),
              Text('تنبيهات الأسعار', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.muted)),
              const SizedBox(height: 8),
              Panel(
                child: Column(children: [
                  row('تنبيه عند ارتفاع السعر', sw(state.notifyRise, state.setRise),
                      first: true, sub: 'إشعار عند ارتفاع أي عملة'),
                  row('تنبيه عند نزول السعر', sw(state.notifyFall, state.setFall),
                      sub: 'إشعار عند نزول أي عملة'),
                  row(
                    'تجربة الإشعار',
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () async {
                        await Notifier.requestPermission();
                        await Notifier.show('تجربة الإشعار', 'هكذا ستظهر تنبيهات الأسعار');
                      },
                      child: Text('إرسال', style: TextStyle(color: p.tileText, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text(
                  'تصلك الإشعارات والتطبيق مغلق (فحص كل 15 دقيقة تقريباً على أندرويد)، وتُقارن بحسب المصدر الافتراضي.',
                  style: TextStyle(fontSize: 12, height: 1.5, color: p.muted),
                ),
              ),
              const SizedBox(height: 16),
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
                  row(
                    'التحديث التلقائي',
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      state.loading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Pal.coral),
                              ),
                            )
                          : IconButton(
                              tooltip: 'تحديث الآن',
                              onPressed: state.refresh,
                              icon: Icon(Icons.refresh_rounded, color: p.muted),
                            ),
                      sw(state.autoRefresh, state.setAuto),
                    ]),
                    sub: 'كل دقيقة أثناء فتح التطبيق',
                  ),
                  row('الإصدار', Num('v1.0', style: TextStyle(fontSize: 14, color: p.muted))),
                ]),
              ),
            ],
          );
        },
      );
}