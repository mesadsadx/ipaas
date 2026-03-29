import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'search_screen.dart';
import 'food_detail_screen.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final _expanded = {'breakfast': true, 'lunch': true, 'dinner': true, 'snacks': true};

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final date = prov.selectedDate;
    final totals = prov.getDayTotals(date);
    final goals = prov.goals;
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── date navigator ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: AppColors.textSecondary),
                    onPressed: () => prov.setDate(date.subtract(const Duration(days: 1))),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: prov.goToday,
                      child: Column(
                        children: [
                          Text(
                            isToday ? 'Сегодня' : DateFormat('d MMMM', 'ru').format(date),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700),
                          ),
                          Text(
                            DateFormat('EEEE', 'ru').format(date),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: isToday ? AppColors.textMuted.withOpacity(0.3) : AppColors.textSecondary,
                    ),
                    onPressed: isToday
                        ? null
                        : () => prov.setDate(date.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),

            // ── scrollable body ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Ring
                  AppCard(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        MacroRing(
                          calories: totals.calories,
                          caloriesGoal: goals.calories,
                          protein: totals.protein,
                          fat: totals.fat,
                          carbs: totals.carbs,
                          size: 180,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _Legend('Белки', totals.protein, goals.protein, AppColors.protein),
                            const SizedBox(width: 20),
                            _Legend('Жиры', totals.fat, goals.fat, AppColors.fat),
                            const SizedBox(width: 20),
                            _Legend('Углеводы', totals.carbs, goals.carbs, AppColors.carbs),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Macro bars
                  AppCard(
                    child: Column(
                      children: [
                        MacroBar(label: 'Белки', value: totals.protein, goal: goals.protein, color: AppColors.protein),
                        MacroBar(label: 'Жиры', value: totals.fat, goal: goals.fat, color: AppColors.fat),
                        MacroBar(label: 'Углеводы', value: totals.carbs, goal: goals.carbs, color: AppColors.carbs),
                        MacroBar(label: 'Клетчатка', value: totals.fiber, goal: goals.fiber, color: AppColors.blue),
                      ],
                    ),
                  ),

                  // Meal sections
                  ...meals.map((meal) => _MealSection(
                        meal: meal,
                        date: date,
                        expanded: _expanded[meal.key] ?? true,
                        onToggle: () => setState(() =>
                            _expanded[meal.key] = !(_expanded[meal.key] ?? true)),
                        onAddTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchScreen(mealType: meal.key, date: date),
                          ),
                        ),
                      )),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final double value;
  final int goal;
  final Color color;

  const _Legend(this.label, this.value, this.goal, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${value.round()}',
                style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const TextSpan(text: 'г', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
            ],
          ),
        ),
        Text('/$goal', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}

class _MealSection extends StatelessWidget {
  final MealInfo meal;
  final DateTime date;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onAddTap;

  const _MealSection({
    required this.meal,
    required this.date,
    required this.expanded,
    required this.onToggle,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final entries = prov.getEntries(date, meal.key);
    final mealCal = entries.fold(0.0, (s, e) => s + e.scaledNutrition.calories);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: meal.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(meal.icon, color: meal.color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(meal.label,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ),
                if (entries.isNotEmpty)
                  Text('${mealCal.round()} ккал',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(width: 8),
                Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ),
        ),

        if (expanded)
          AppCard(
            child: Column(
              children: [
                if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(meal.icon, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 8),
                        const Text('Пусто', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  )
                else
                  ...entries.map((entry) => Dismissible(
                        key: Key(entry.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: AppColors.coral.withOpacity(0.2),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete_outline, color: AppColors.coral),
                        ),
                        onDismissed: (_) => prov.removeEntry(date, entry.id),
                        child: FoodListTile(
                          food: FoodItem(
                            fdcId: entry.fdcId,
                            name: entry.name,
                            brand: entry.brand,
                            nutrition: entry.scaledNutrition,
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FoodDetailScreen(
                                fdcId: entry.fdcId,
                                mealType: meal.key,
                                date: date,
                                entryId: entry.id,
                              ),
                            ),
                          ),
                          trailing: Text(
                            '${entry.grams.round()} г',
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      )),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onAddTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.borderStrong,
                          width: 1,
                          style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: AppColors.primary, size: 18),
                        const SizedBox(width: 6),
                        Text('Добавить',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
