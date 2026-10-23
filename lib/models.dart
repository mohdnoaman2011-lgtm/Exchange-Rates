enum RateSource { parallel, bank }

class Currency {
  final String code, nameAr;
  const Currency(this.code, this.nameAr);
}

const currencies = [
  Currency('USD', 'الدولار الأمريكي'),
  Currency('AED', 'الدرهم الإماراتي'),
  Currency('EGP', 'الجنيه المصري'),
  Currency('EUR', 'اليورو'),
  Currency('SAR', 'الريال السعودي'),
  Currency('QAR', 'الريال القطري'),
];

String nameOf(String code) => currencies.firstWhere((c) => c.code == code).nameAr;

class Rate {
  final String code;
  final double parallel, bank;
  const Rate(this.code, this.parallel, this.bank);

  double value(RateSource s) => s == RateSource.parallel ? parallel : bank;

  /// الموازي: الفرق عن البنك، والبنك: الفرق عن الموازي
  double deltaPct(RateSource s) => s == RateSource.parallel
      ? (parallel - bank) / bank * 100
      : (bank - parallel) / parallel * 100;

  Map<String, dynamic> toJson() => {'code': code, 'parallel': parallel, 'bank': bank};
  factory Rate.fromJson(Map<String, dynamic> j) =>
      Rate(j['code'], (j['parallel'] as num).toDouble(), (j['bank'] as num).toDouble());
}

class RatesSnapshot {
  final Map<String, Rate> rates;
  final DateTime fetchedAt;
  const RatesSnapshot(this.rates, this.fetchedAt);

  Map<String, dynamic> toJson() => {
        'at': fetchedAt.toIso8601String(),
        'rates': rates.values.map((r) => r.toJson()).toList(),
      };
  factory RatesSnapshot.fromJson(Map<String, dynamic> j) => RatesSnapshot({
        for (final r in (j['rates'] as List)) (r['code'] as String): Rate.fromJson(Map<String, dynamic>.from(r))
      }, DateTime.parse(j['at']));
}

class AlertRule {
  final String id, code;
  final RateSource source;
  final bool above;
  final double target;
  bool enabled, fired;
  AlertRule({
    required this.id,
    required this.code,
    required this.source,
    required this.above,
    required this.target,
    this.enabled = true,
    this.fired = false,
  });

  bool matches(double v) => above ? v >= target : v <= target;

  Map<String, dynamic> toJson() => {
        'id': id, 'code': code, 'source': source.name, 'above': above,
        'target': target, 'enabled': enabled, 'fired': fired,
      };
  factory AlertRule.fromJson(Map<String, dynamic> j) => AlertRule(
        id: j['id'], code: j['code'],
        source: RateSource.values.byName(j['source']),
        above: j['above'], target: (j['target'] as num).toDouble(),
        enabled: j['enabled'] ?? true, fired: j['fired'] ?? false,
      );
}

String fmt(double v, [int? d]) {
  final dec = d ?? (v == v.roundToDouble() ? 0 : 2);
  final parts = v.toStringAsFixed(dec).split('.');
  final i = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return dec > 0 ? '$i.${parts[1]}' : i;
}
