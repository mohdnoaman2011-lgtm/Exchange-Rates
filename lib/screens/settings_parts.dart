import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../theme.dart';
import '../widgets.dart';

/// صف في قائمة الإعدادات
class SettingsRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final bool first;
  final String? sub;
  const SettingsRow(this.label, this.trailing, {super.key, this.first = false, this.sub});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: first ? Colors.transparent : p.divider)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            if (sub != null) Text(sub!, style: TextStyle(fontSize: 12, color: p.muted)),
          ]),
        ),
        trailing,
      ]),
    );
  }
}

/// محدّد من خيارين أو أكثر (داكن/فاتح، موازي/بنك)
class SegControl<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;
  const SegControl({super.key, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.tile, borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final (v, l) in items)
          InkWell(
            onTap: () => onChanged(v),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: v == value ? Pal.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(l,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: v == value ? FontWeight.w700 : FontWeight.w500,
                    color: v == value ? Pal.navy : p.muted,
                  )),
            ),
          ),
      ]),
    );
  }
}

/// مفتاح التفعيل
class AppSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const AppSwitch(this.value, this.onChanged, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = Pal.of(context);
    return Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      activeColor: Colors.white,
      activeTrackColor: Pal.accent,
      inactiveThumbColor: p.muted,
      inactiveTrackColor: p.tile,
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );
  }
}

/// رقم الإصدار الحقيقي من إعدادات البناء، مثل v2.0.15 (15)
class VersionText extends StatelessWidget {
  const VersionText({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snap) => Num(
          snap.hasData ? 'v${snap.data!.version} (${snap.data!.buildNumber})' : '',
          style: TextStyle(fontSize: 14, color: Pal.of(context).muted),
        ),
      );
}