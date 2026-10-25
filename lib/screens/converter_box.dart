import 'package:flutter/material.dart';
import '../widgets.dart';

/// بطاقة المبلغ أو النتيجة
class ConverterBox extends StatelessWidget {
  final String label, cur, value;
  final Color valueColor, muted, curColor;
  final String? footer;
  const ConverterBox(this.label, this.cur, this.value, this.valueColor, this.muted, this.curColor,
      {super.key, this.footer});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: TextStyle(fontSize: 13, color: muted)),
            Num(cur, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: curColor)),
          ]),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Num(value,
                  style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700, height: 1, color: valueColor)),
            ),
          ),
          if (footer != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Num(footer!, style: TextStyle(fontSize: 13, color: muted)),
            ),
        ],
      );
}