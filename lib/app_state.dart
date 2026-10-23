import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'notifications.dart';
import 'rates_service.dart';

class AppState extends ChangeNotifier {
  final _service = RatesService();
  late SharedPreferences _p;
  Timer? _timer;

  RatesSnapshot? snapshot;
  bool loading = false;
  String? error;
  RateSource source = RateSource.parallel;
  ThemeMode themeMode = ThemeMode.dark;
  bool autoRefresh = true;
  bool notifyRise = false;
  bool notifyFall = false;
  Map<String, List<double>> history = {};

  Rate? rate(String code) => snapshot?.rates[code];
  List<double> series(String code) => history['$code-${source.name}'] ?? const [];

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    source = RateSource.values.byName(_p.getString('source') ?? 'parallel');
    themeMode = ThemeMode.values.byName(_p.getString('theme') ?? 'dark');
    autoRefresh = _p.getBool('auto') ?? true;
    notifyRise = _p.getBool('rise') ?? false;
    notifyFall = _p.getBool('fall') ?? false;
    final s = _p.getString('snapshot');
    if (s != null) snapshot = RatesSnapshot.fromJson(jsonDecode(s));
    final h = _p.getString('history');
    if (h != null) {
      history = (jsonDecode(h) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as List).map((e) => (e as num).toDouble()).toList()));
    }
    Notifier.syncSchedule(enabled: notifyRise || notifyFall);
    refresh();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (autoRefresh) _timer = Timer.periodic(const Duration(seconds: 60), (_) => refresh());
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    notifyListeners();
    try {
      await _p.reload(); // قد تكون المهمة الخلفية حدّثت اللقطة
      final raw = _p.getString('snapshot');
      final old = raw == null ? snapshot : RatesSnapshot.fromJson(jsonDecode(raw));
      snapshot = await _service.fetch();
      error = null;
      _record();
      await _p.setString('snapshot', jsonEncode(snapshot!.toJson()));
      final lines = detectMoves(old, snapshot!, source, rise: notifyRise, fall: notifyFall);
      if (lines.isNotEmpty) Notifier.show('تغيّر في الأسعار', lines.take(5).join('\n'));
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }
    loading = false;
    notifyListeners();
  }

  void _record() {
    for (final r in snapshot!.rates.values) {
      for (final s in RateSource.values) {
        final l = history.putIfAbsent('${r.code}-${s.name}', () => []);
        final v = r.value(s);
        if (l.isEmpty || l.last != v) l.add(v);
        if (l.length > 60) l.removeAt(0);
      }
    }
    _p.setString('history', jsonEncode(history));
  }

  void setSource(RateSource s) { source = s; _p.setString('source', s.name); notifyListeners(); }
  void setTheme(ThemeMode m) { themeMode = m; _p.setString('theme', m.name); notifyListeners(); }
  void toggleTheme(bool isDark) => setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  void setAuto(bool v) { autoRefresh = v; _p.setBool('auto', v); _schedule(); notifyListeners(); }

  Future<void> setRise(bool v) async {
    if (v) await Notifier.requestPermission();
    notifyRise = v;
    await _p.setBool('rise', v);
    await Notifier.syncSchedule(enabled: notifyRise || notifyFall);
    notifyListeners();
  }

  Future<void> setFall(bool v) async {
    if (v) await Notifier.requestPermission();
    notifyFall = v;
    await _p.setBool('fall', v);
    await Notifier.syncSchedule(enabled: notifyRise || notifyFall);
    notifyListeners();
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}
