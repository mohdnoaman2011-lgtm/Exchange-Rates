import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

/// يجلب الأسعار من status.sd
///
/// 1) الـ API الرسمي (الأساسي): GET /api/open/v1/currency مع الهيدر X-API-Key
///    يمرَّر المفتاح عند البناء ولا يُكتب داخل الكود:
///    flutter build apk --dart-define=STATUS_API_KEY=sk_live_xxx
/// 2) احتياطي: قراءة الأسعار من الصفحة الرئيسية https://status.sd
class RatesService {
  static const pageUrl = 'https://status.sd';
  static const apiUrl = 'https://status.sd/api/open/v1/currency';
  static const apiKey = String.fromEnvironment('STATUS_API_KEY');

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
    if (apiKey.isNotEmpty) {
      try {
        return await _fromApi();
      } catch (_) {/* نرجع للصفحة */}
    }
    final res = await http
        .get(Uri.parse(pageUrl), headers: _headers)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('تعذر الاتصال (${res.statusCode})');
    return parseHtml(utf8.decode(res.bodyBytes));
  }

  Future<RatesSnapshot> _fromApi() async {
    final res = await http.get(Uri.parse(apiUrl), headers: {
      'X-API-Key': apiKey,
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return parseApi(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  static const _codeKeys = ['code', 'currency', 'currency_code', 'symbol', 'iso'];
  static const _parallelKeys = ['parallel', 'parallel_rate', 'market', 'black_market', 'sell'];
  static const _bankKeys = ['bank', 'bank_rate', 'official', 'official_rate'];

  /// يقبل عدة أشكال للـ JSON: قائمة، أو {"data":[...]}، أو {"USD":{...}}
  static RatesSnapshot parseApi(dynamic data) {
    dynamic root = data;
    if (root is Map) {
      for (final k in ['data', 'rates', 'currencies', 'result']) {
        if (root[k] != null) {
          root = root[k];
          break;
        }
      }
    }
    final items = <String, Map>{};
    if (root is List) {
      for (final e in root) {
        if (e is Map) {
          final c = _pick(e, _codeKeys);
          if (c != null) items[c.toString().toUpperCase()] = e;
        }
      }
    } else if (root is Map) {
      root.forEach((k, v) {
        if (v is Map) items[k.toString().toUpperCase()] = v;
      });
    }
    final rates = <String, Rate>{};
    for (final c in currencies) {
      final e = items[c.code];
      if (e == null) continue;
      final p = _toDouble(_pick(e, _parallelKeys));
      final b = _toDouble(_pick(e, _bankKeys));
      if (p != null && b != null) rates[c.code] = Rate(c.code, p, b);
    }
    if (rates.isEmpty) throw const FormatException('تعذر قراءة استجابة الـ API');
    return RatesSnapshot(rates, DateTime.now());
  }

  static dynamic _pick(Map m, List<String> keys) {
    for (final k in keys) {
      if (m[k] != null) return m[k];
    }
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', ''));
    return null;
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
