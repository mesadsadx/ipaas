import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'diary_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;

  final _screens = const [
    DiaryScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                _TabItem(icon: Icons.book_outlined, filledIcon: Icons.book, label: 'Дневник', selected: _tab == 0, onTap: () => setState(() => _tab = 0)),
                _TabItem(icon: Icons.bar_chart_outlined, filledIcon: Icons.bar_chart, label: 'Статистика', selected: _tab == 1, onTap: () => setState(() => _tab = 1)),
                _TabItem(icon: Icons.settings_outlined, filledIcon: Icons.settings, label: 'Настройки', selected: _tab == 2, onTap: () => setState(() => _tab = 2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final IconData filledIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryMuted : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                selected ? filledIcon : icon,
                color: selected ? AppColors.primary : AppColors.textMuted,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
