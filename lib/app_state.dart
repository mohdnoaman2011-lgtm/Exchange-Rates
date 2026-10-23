import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'rates_service.dart';

class AppState extends ChangeNotifier {
  final messenger = GlobalKey<ScaffoldMessengerState>();
  final _service = RatesService();
  late SharedPreferences _p;
  Timer? _timer;

  RatesSnapshot? snapshot;
  bool loading = false;
  String? error;
  RateSource source = RateSource.parallel;
  ThemeMode themeMode = ThemeMode.dark;
  bool autoRefresh = true;
  bool notifyRise = true;
  bool notifyFall = true;
  List<AlertRule> alerts = [];
  Map<String, List<double>> history = {};

  Rate? rate(String code) => snapshot?.rates[code];
  List<double> series(String code) => history['$code-${source.name}'] ?? const [];

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    source = RateSource.values.byName(_p.getString('source') ?? 'parallel');
    themeMode = ThemeMode.values.byName(_p.getString('theme') ?? 'dark');
    autoRefresh = _p.getBool('auto') ?? true;
    notifyRise = _p.getBool('rise') ?? true;
    notifyFall = _p.getBool('fall') ?? true;
    final s = _p.getString('snapshot');
    if (s != null) snapshot = RatesSnapshot.fromJson(jsonDecode(s));
    final a = _p.getString('alerts');
    if (a != null) alerts = (jsonDecode(a) as List).map((e) => AlertRule.fromJson(e)).toList();
    final h = _p.getString('history');
    if (h != null) {
      history = (jsonDecode(h) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as List).map((e) => (e as num).toDouble()).toList()));
    }
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
      final old = snapshot;
      snapshot = await _service.fetch();
      error = null;
      _record();
      _checkMoves(old, snapshot!);
      _checkAlerts();
      _p.setString('snapshot', jsonEncode(snapshot!.toJson()));
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

  /// تنبيه عند ارتفاع أو نزول أي عملة مقارنةً بآخر تحديث
  void _checkMoves(RatesSnapshot? old, RatesSnapshot now) {
    if (old == null || (!notifyRise && !notifyFall)) return;
    final lines = <String>[];
    for (final r in now.rates.values) {
      final o = old.rates[r.code];
      if (o == null) continue;
      final a = o.value(source), b = r.value(source);
      if (b > a && notifyRise) lines.add('▲ ${nameOf(r.code)} ارتفع من ${fmt(a)} إلى ${fmt(b)}');
      if (b < a && notifyFall) lines.add('▼ ${nameOf(r.code)} نزل من ${fmt(a)} إلى ${fmt(b)}');
    }
    if (lines.isEmpty) return;
    messenger.currentState?.showSnackBar(SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(lines.take(4).join('\n')),
    ));
  }

  void _checkAlerts() {
    for (final a in alerts.where((a) => a.enabled)) {
      final r = rate(a.code);
      if (r == null) continue;
      final v = r.value(a.source);
      if (a.matches(v) && !a.fired) {
        a.fired = true;
        final src = a.source == RateSource.parallel ? 'الموازي' : 'البنك';
        messenger.currentState?.showSnackBar(SnackBar(
          content: Text('${nameOf(a.code)} ($src) وصل إلى ${fmt(v)} ج.س'),
        ));
      } else if (!a.matches(v)) {
        a.fired = false;
      }
    }
    _saveAlerts();
  }

  void _saveAlerts() => _p.setString('alerts', jsonEncode(alerts.map((e) => e.toJson()).toList()));

  void setSource(RateSource s) { source = s; _p.setString('source', s.name); notifyListeners(); }
  void setTheme(ThemeMode m) { themeMode = m; _p.setString('theme', m.name); notifyListeners(); }
  void toggleTheme(bool isDark) => setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
  void setRise(bool v) { notifyRise = v; _p.setBool('rise', v); notifyListeners(); }
  void setFall(bool v) { notifyFall = v; _p.setBool('fall', v); notifyListeners(); }
  void setAuto(bool v) { autoRefresh = v; _p.setBool('auto', v); _schedule(); notifyListeners(); }

  void addAlert(AlertRule a) { alerts.add(a); _saveAlerts(); notifyListeners(); }
  void removeAlert(String id) { alerts.removeWhere((a) => a.id == id); _saveAlerts(); notifyListeners(); }
  void toggleAlert(AlertRule a, bool v) { a.enabled = v; a.fired = false; _saveAlerts(); notifyListeners(); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
}
