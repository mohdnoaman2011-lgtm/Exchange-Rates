import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models.dart';
import '../notifications.dart';
import '../theme.dart';
import '../widgets.dart';
import 'settings_parts.dart';

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

          return ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
            children: [
              const ScreenHeader(title: 'الإعدادات', subtitle: Text('خصّص التطبيق')),
              const SizedBox(height: 16),
              Text('تنبيهات الأسعار',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: p.muted)),
              const SizedBox(height: 8),
              Panel(
                child: Column(children: [
                  SettingsRow('تنبيه عند ارتفاع السعر', AppSwitch(state.notifyRise, state.setRise),
                      first: true, sub: 'إشعار عند ارتفاع أي عملة'),
                  SettingsRow('تنبيه عند نزول السعر', AppSwitch(state.notifyFall, state.setFall),
                      sub: 'إشعار عند نزول أي عملة'),
                  SettingsRow(
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
                  SettingsRow(
                    'المظهر',
                    SegControl<ThemeMode>(
                      value: state.themeMode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark,
                      items: const [(ThemeMode.dark, 'داكن'), (ThemeMode.light, 'فاتح')],
                      onChanged: state.setTheme,
                    ),
                    first: true,
                  ),
                  SettingsRow(
                    'المصدر الافتراضي',
                    SegControl<RateSource>(
                      value: state.source,
                      items: const [(RateSource.parallel, 'موازي'), (RateSource.bank, 'بنك')],
                      onChanged: state.setSource,
                    ),
                  ),
                  SettingsRow(
                    'التحديث التلقائي',
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      state.loading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Pal.accent),
                              ),
                            )
                          : IconButton(
                              tooltip: 'تحديث الآن',
                              onPressed: state.refresh,
                              icon: Icon(Icons.refresh_rounded, color: p.muted),
                            ),
                      AppSwitch(state.autoRefresh, state.setAuto),
                    ]),
                    sub: 'كل دقيقة أثناء فتح التطبيق',
                  ),
                  const SettingsRow('الإصدار', VersionText()),
                ]),
              ),
            ],
          );
        },
      );
}