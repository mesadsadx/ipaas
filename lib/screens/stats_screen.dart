import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _insight = '';
  bool _insightLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInsight());
  }

  Future<void> _loadInsight() async {
    final prov = context.read<AppProvider>();
    final totals = prov.getDayTotals(prov.selectedDate);
    final goals = prov.goals;
    setState(() => _insightLoading = true);
    try {
      final text = await AiService.getDayInsight(
        calories: totals.calories,
        protein: totals.protein,
        fat: totals.fat,
        carbs: totals.carbs,
        calGoal: goals.calories,
        proteinGoal: goals.protein,
      );
      if (mounted) setState(() => _insight = text);
    } catch (_) {
      if (mounted) setState(() => _insight = '');
    } finally {
      if (mounted) setState(() => _insightLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final today = prov.getDayTotals(prov.selectedDate);
    final goals = prov.goals;
    final weekData = prov.getWeekData();

    final calValues = weekData.map((d) => d.totals.calories).toList();
    final protValues = weekData.map((d) => d.totals.protein).toList();
    final labels = weekData.map((d) => d.label).toList();

    final totalE = today.protein * 4 + today.fat * 9 + today.carbs * 4;
    final protPct = totalE > 0 ? (today.protein * 4 / totalE * 100).round() : 0;
    final fatPct  = totalE > 0 ? (today.fat     * 9 / totalE * 100).round() : 0;
    final carbPct = totalE > 0 ? (today.carbs   * 4 / totalE * 100).round() : 0;

    // Weekly average
    final wLen = weekData.length.toDouble();
    final avgCal  = weekData.fold(0.0, (a, d) => a + d.totals.calories) / wLen;
    final avgProt = weekData.fold(0.0, (a, d) => a + d.totals.protein)  / wLen;
    final avgFat  = weekData.fold(0.0, (a, d) => a + d.totals.fat)      / wLen;
    final avgCarb = weekData.fold(0.0, (a, d) => a + d.totals.carbs)    / wLen;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            Row(
              children: [
                const Text('Статистика',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text('7 дней', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),

            // Today stat cards
            const SectionLabel(icon: Icons.today_outlined, label: 'Сегодня'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.3,
              children: [
                _StatCard(icon: Icons.local_fire_department_outlined, label: 'Калории', value: today.calories.round(), goal: goals.calories, unit: 'ккал', color: AppColors.coral),
                _StatCard(icon: Icons.fitness_center_outlined, label: 'Белки',   value: today.protein.round(), goal: goals.protein, unit: 'г', color: AppColors.protein),
                _StatCard(icon: Icons.water_drop_outlined,    label: 'Жиры',    value: today.fat.round(),     goal: goals.fat,     unit: 'г', color: AppColors.fat),
                _StatCard(icon: Icons.grass_outlined,         label: 'Углеводы',value: today.carbs.round(),   goal: goals.carbs,   unit: 'г', color: AppColors.carbs),
              ],
            ),

            // Macro split
            const SectionLabel(icon: Icons.pie_chart_outline, label: 'Соотношение БЖУ'),
            AppCard(
              child: Column(
                children: [
                  if (totalE > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        height: 10,
                        child: Row(
                          children: [
                            Flexible(flex: protPct, child: Container(color: AppColors.protein)),
                            const SizedBox(width: 2),
                            Flexible(flex: fatPct,  child: Container(color: AppColors.fat)),
                            const SizedBox(width: 2),
                            Flexible(flex: carbPct, child: Container(color: AppColors.carbs)),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(height: 10, decoration: BoxDecoration(color: AppColors.bgElevated, borderRadius: BorderRadius.circular(99))),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SplitLabel('Белки $protPct%', AppColors.protein),
                      const SizedBox(width: 20),
                      _SplitLabel('Жиры $fatPct%',   AppColors.fat),
                      const SizedBox(width: 20),
                      _SplitLabel('Углев $carbPct%', AppColors.carbs),
                    ],
                  ),
                ],
              ),
            ),

            // Calorie chart
            const SectionLabel(icon: Icons.bar_chart, label: 'Калории за неделю'),
            AppCard(child: WeekBarChart(values: calValues, labels: labels, goalValue: goals.calories.toDouble(), color: AppColors.coral)),

            // Protein chart
            const SectionLabel(icon: Icons.fitness_center_outlined, label: 'Белки за неделю'),
            AppCard(child: WeekBarChart(values: protValues, labels: labels, goalValue: goals.protein.toDouble(), color: AppColors.protein)),

            // AI insight
            Row(
              children: [
                const Expanded(child: SectionLabel(icon: Icons.auto_awesome, label: 'Совет от ИИ')),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 14, color: AppColors.primary),
                  label: const Text('Обновить', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                  onPressed: _loadInsight,
                ),
              ],
            ),
            AppCard(
              color: const Color(0xFF0F0F1F),
              child: _insightLoading
                  ? const Row(
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('Анализирую рацион...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    )
                  : _insight.isNotEmpty
                      ? Text(_insight, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6))
                      : const Text('Добавьте блюда, чтобы получить персональный совет',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontStyle: FontStyle.italic)),
            ),

            // Weekly averages
            const SectionLabel(icon: Icons.show_chart, label: 'Средние за 7 дней'),
            AppCard(
              child: Column(
                children: [
                  MacroBar(label: 'Калории',  value: avgCal,  goal: goals.calories, color: AppColors.coral,   unit: 'ккал'),
                  MacroBar(label: 'Белки',    value: avgProt, goal: goals.protein,  color: AppColors.protein),
                  MacroBar(label: 'Жиры',     value: avgFat,  goal: goals.fat,      color: AppColors.fat),
                  MacroBar(label: 'Углеводы', value: avgCarb, goal: goals.carbs,    color: AppColors.carbs),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int goal;
  final String unit;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.goal, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = (value / goal).clamp(0.0, 1.0);
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text('$value', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800, height: 1)),
          Text(unit, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: pct, minHeight: 3, backgroundColor: AppColors.bgElevated, valueColor: AlwaysStoppedAnimation(color)),
          ),
          const SizedBox(height: 2),
          Text('цель $goal', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }
}

class _SplitLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SplitLabel(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
    ]);
  }
}
