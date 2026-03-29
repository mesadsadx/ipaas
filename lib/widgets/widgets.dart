import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// ── Macro Ring (CustomPainter) ─────────────────────────────────────────────
class MacroRing extends StatelessWidget {
  final double calories;
  final int caloriesGoal;
  final double protein;
  final double fat;
  final double carbs;
  final double size;

  const MacroRing({
    super.key,
    required this.calories,
    required this.caloriesGoal,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          protein: protein,
          fat: fat,
          carbs: carbs,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                calories.round().toString(),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: size * 0.17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'из $caloriesGoal ккал',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: size * 0.07,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double protein, fat, carbs;

  const _RingPainter({required this.protein, required this.fat, required this.carbs});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final strokeW = size.width * 0.07;
    final r = (size.width - strokeW * 2) / 2;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Background track
    canvas.drawArc(
      rect, 0, math.pi * 2,
      false,
      Paint()
        ..color = AppColors.bgElevated
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round,
    );

    final total = protein * 4 + fat * 9 + carbs * 4;
    if (total == 0) return;

    final pAngle = (protein * 4 / total) * math.pi * 2;
    final fAngle = (fat * 9 / total) * math.pi * 2;
    final cAngle = (carbs * 4 / total) * math.pi * 2;

    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    const start = -math.pi / 2;
    canvas.drawArc(rect, start, pAngle, false, arc(AppColors.protein));
    canvas.drawArc(rect, start + pAngle, fAngle, false, arc(AppColors.fat));
    canvas.drawArc(rect, start + pAngle + fAngle, cAngle, false, arc(AppColors.carbs));
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.protein != protein || old.fat != fat || old.carbs != carbs;
}

// ── Macro Bar ─────────────────────────────────────────────────────────────
class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final int goal;
  final Color color;
  final String unit;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
    this.unit = 'г',
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value / goal).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: value.round().toString(),
                      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: unit,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.bgElevated,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 3),
          Text('цель $goal$unit',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

// ── Nutrient Row ──────────────────────────────────────────────────────────
class NutrientRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double percent;
  final Color color;

  const NutrientRow({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.percent,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                Text('${value.toStringAsFixed(1)} $unit',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 4,
                backgroundColor: AppColors.bgElevated,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 38,
            child: Text(
              '${percent.round()}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: percent >= 100 ? AppColors.green : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Food List Tile ────────────────────────────────────────────────────────
class FoodListTile extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Widget? trailing;

  const FoodListTile({
    super.key,
    required this.food,
    required this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500)),
                  if (food.brand != null)
                    Text(food.brand!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: [
                      _MacroChip('${food.nutrition.calories.round()} ккал',
                          AppColors.coral),
                      const _Dot(),
                      _MacroChip('Б ${food.nutrition.protein.round()}г',
                          AppColors.protein),
                      const _Dot(),
                      _MacroChip('Ж ${food.nutrition.fat.round()}г', AppColors.fat),
                      const _Dot(),
                      _MacroChip('У ${food.nutrition.carbs.round()}г', AppColors.carbs),
                    ],
                  ),
                ],
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MacroChip(this.text, this.color);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500));
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) =>
      const Text('·', style: TextStyle(color: AppColors.textMuted, fontSize: 12));
}

// ── App Card ──────────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: child,
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────
class SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? action;
  final VoidCallback? onAction;

  const SectionLabel({
    super.key,
    required this.icon,
    required this.label,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6),
          ),
          const Spacer(),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!,
                  style: const TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.bgElevated,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(icon, size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Week Bar Chart ────────────────────────────────────────────────────────
class WeekBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final double goalValue;
  final Color color;

  const WeekBarChart({
    super.key,
    required this.values,
    required this.labels,
    required this.goalValue,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = [...values, goalValue].reduce(math.max);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final val = values[i];
          final barH = maxVal > 0 ? (val / maxVal) * 110 : 0.0;
          final isLast = i == values.length - 1;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    val > 0 ? val.round().toString() : '',
                    style: TextStyle(
                      color: isLast ? color : AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    child: Container(
                      height: barH.clamp(4, 110),
                      color: color.withOpacity(isLast ? 1.0 : 0.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: TextStyle(
                      color: isLast ? AppColors.textPrimary : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
