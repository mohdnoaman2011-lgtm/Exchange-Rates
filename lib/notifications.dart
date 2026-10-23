import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show DartPluginRegistrant;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'models.dart';
import 'rates_service.dart';

const _task = 'ratesCheck';
const _uniqueName = 'rates-check';

/// الإشعارات الفعلية (تظهر في شريط الإشعارات حتى لو التطبيق مغلق)
class Notifier {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ));
    _ready = true;
  }

  static Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  static Future<void> show(String title, String body) async {
    await init();
    await _plugin.show(
      1,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'price_moves',
          'حركة الأسعار',
          channelDescription: 'إشعارات ارتفاع ونزول الأسعار',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  /// يشغّل/يوقف الفحص الدوري في الخلفية (أندرويد، كل 15 دقيقة كحد أدنى)
  static Future<void> syncSchedule({required bool enabled}) async {
    if (kIsWeb || !Platform.isAndroid) return;
    if (enabled) {
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _task,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } else {
      await Workmanager().cancelByUniqueName(_uniqueName);
    }
  }
}

/// يقارن اللقطتين ويرجع سطراً لكل عملة ارتفعت أو نزلت
List<String> detectMoves(RatesSnapshot? old, RatesSnapshot now, RateSource s,
    {required bool rise, required bool fall}) {
  if (old == null) return const [];
  final lines = <String>[];
  for (final r in now.rates.values) {
    final o = old.rates[r.code];
    if (o == null) continue;
    final a = o.value(s), b = r.value(s);
    if (b > a && rise) lines.add('▲ ${nameOf(r.code)} ارتفع من ${fmt(a)} إلى ${fmt(b)}');
    if (b < a && fall) lines.add('▼ ${nameOf(r.code)} نزل من ${fmt(a)} إلى ${fmt(b)}');
  }
  return lines;
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      DartPluginRegistrant.ensureInitialized();
      final p = await SharedPreferences.getInstance();
      await p.reload();
      final rise = p.getBool('rise') ?? false;
      final fall = p.getBool('fall') ?? false;
      if (!rise && !fall) return true;
      final src = RateSource.values.byName(p.getString('source') ?? 'parallel');
      final raw = p.getString('snapshot');
      final old = raw == null ? null : RatesSnapshot.fromJson(jsonDecode(raw));
      final now = await RatesService().fetch();
      final lines = detectMoves(old, now, src, rise: rise, fall: fall);
      await p.setString('snapshot', jsonEncode(now.toJson()));
      if (lines.isNotEmpty) await Notifier.show('تغيّر في الأسعار', lines.take(5).join('\n'));
    } catch (_) {/* نحاول في الدورة القادمة */}
    return true;
  });
}
