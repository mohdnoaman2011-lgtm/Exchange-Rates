import 'package:flutter/material.dart';
import '../app_state.dart';
import '../widgets.dart';
import 'alerts_screen.dart';
import 'converter_screen.dart';
import 'prices_screen.dart';
import 'settings_screen.dart';

class Shell extends StatefulWidget {
  final AppState state;
  const Shell({super.key, required this.state});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: tab, children: [
          PricesScreen(state: s, onOpenConverter: () => setState(() => tab = 1)),
          ConverterScreen(state: s),
          AlertsScreen(state: s),
          SettingsScreen(state: s),
        ]),
      ),
      bottomNavigationBar: PillNav(index: tab, onTap: (i) => setState(() => tab = i)),
    );
  }
}
