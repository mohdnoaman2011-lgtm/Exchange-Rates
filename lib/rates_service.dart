import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

/// يجلب الأسعار من status.sd
///
/// 1) إن وُجد رابط JSON يمرَّر عند التشغيل:
///    flutter run --dart-define=RATES_JSON_URL=https://...
///    بالشكل {"USD":{"parallel":10386,"bank":4886.38}, ...}
///    (أو داخل مفتاح "rates")
/// 2) وإلا تُقرأ الأسعار من الصفحة الرئيسية https://status.sd
class RatesService {
  static const pageUrl = 'https://status.sd';
  static const jsonUrl = String.fromEnvironment('RATES_JSON_URL');

  // أسماء العملات كما تظهر في status.sd (بعد توحيد الهمزات)
  static const _names = {
    'USD': 'الدولار الامريكي',
    'AED': 'الدرهم الاماراتي',
    'EGP': 'الجنيه المصري',
    'EUR': 'اليورو',
    'SAR': 'الريال السعودي',
    'QAR': 'الريال القطري',
  };

  static const _headers = {
    'Accept-Language': 'ar',
    'User-Agent': 'Mozilla/5.0 (Flutter) SudanRates/1.0',
  };

  Future<RatesSnapshot> fetch() async {
    if (jsonUrl.isNotEmpty) {
      try {
        return await _fromJson();
      } catch (_) {/* نرجع للصفحة */}
    }
    final res = await http
        .get(Uri.parse(pageUrl), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('تعذر الاتصال (${res.statusCode})');
    return parseHtml(utf8.decode(res.bodyBytes));
  }

  Future<RatesSnapshot> _fromJson() async {
    final res = await http
        .get(Uri.parse(jsonUrl), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final root = (data['rates'] ?? data) as Map<String, dynamic>;
    final rates = <String, Rate>{};
    for (final c in currencies) {
      final r = root[c.code];
      if (r is Map) {
        rates[c.code] = Rate(c.code, (r['parallel'] as num).toDouble(), (r['bank'] as num).toDouble());
      }
    }
    if (rates.isEmpty) throw const FormatException('JSON فارغ');
    return RatesSnapshot(rates, DateTime.now());
  }

  /// يستخرج الأسعار من نص الصفحة: «الدولار الامريكي $ · موازي 10,386 · بنك 4,886.38»
  static RatesSnapshot parseHtml(String html) {
    var t = html
        .replaceAll(RegExp(r'<(script|style)[\s\S]*?</\1>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&middot;', '·');
    t = _norm(t).replaceAll(RegExp(r'\s+'), ' ');

    final rates = <String, Rate>{};
    _names.forEach((code, name) {
      final m = RegExp(RegExp.escape(_norm(name)) +
              r'[^\d]{0,40}?موازي[^\d]{0,10}([\d,.]+)[^\d]{0,20}?بنك[^\d]{0,10}([\d,.]+)')
          .firstMatch(t);
      if (m != null) rates[code] = Rate(code, _num(m[1]!), _num(m[2]!));
    });
    if (rates.isEmpty) throw const FormatException('تعذر قراءة الأسعار من الصفحة');
    return RatesSnapshot(rates, DateTime.now());
  }

  static String _norm(String s) => s.replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ى', 'ي');
  static double _num(String s) => double.parse(s.replaceAll(RegExp(r'[^\d.]'), ''));
}
