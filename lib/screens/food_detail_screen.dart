import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/usda_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class FoodDetailScreen extends StatefulWidget {
  final FoodItem? food;
  final int? fdcId;
  final String mealType;
  final DateTime date;
  final String? entryId;

  const FoodDetailScreen({
    super.key,
    this.food,
    this.fdcId,
    required this.mealType,
    required this.date,
    this.entryId,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> with SingleTickerProviderStateMixin {
  FoodItem? _food;
  bool _loading = false;
  final _gramsCtrl = TextEditingController(text: '100');
  late String _selectedMeal;
  late TabController _tabCtrl;

  double get _grams => double.tryParse(_gramsCtrl.text) ?? 100;

  @override
  void initState() {
    super.initState();
    _selectedMeal = widget.mealType;
    _tabCtrl = TabController(length: 3, vsync: this);
    if (widget.food != null) {
      _food = widget.food;
      if (widget.food!.servingSize != null) {
        _gramsCtrl.text = widget.food!.servingSize!.round().toString();
      }
    } else if (widget.fdcId != null) {
      _loadFood();
    }
  }

  @override
  void dispose() {
    _gramsCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFood() async {
    setState(() => _loading = true);
    final detail = await UsdaService.getFoodDetails(widget.fdcId!);
    if (!mounted) return;
    setState(() {
      _food = detail;
      _loading = false;
      if (detail?.servingSize != null) {
        _gramsCtrl.text = detail!.servingSize!.round().toString();
      }
    });
  }

  Future<void> _handleAdd() async {
    if (_food == null) return;
    final prov = context.read<AppProvider>();
    final g = _grams;

    if (widget.entryId != null) {
      await prov.updateEntryGrams(widget.date, widget.entryId!, g);
    } else {
      final entry = DiaryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fdcId: _food!.fdcId,
        name: _food!.name,
        brand: _food!.brand,
        grams: g,
        mealType: _selectedMeal,
        nutrition: _food!.nutrition,
        vitamins: _food!.vitamins,
        minerals: _food!.minerals,
      );
      await prov.addEntry(entry);
    }
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final isFav = _food != null && prov.isFavorite(_food!.fdcId);
    final scaledCal = ((_food?.nutrition.calories ?? 0) * _grams / 100).round();
    final mealInfo = getMealInfo(_selectedMeal);

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_food == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(),
        body: const Center(child: Text('Продукт не найден', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final n = _food!.nutrition;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_food!.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            if (_food!.brand != null)
              Text(_food!.brand!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.star : Icons.star_outline,
              color: isFav ? AppColors.amber : AppColors.textMuted,
            ),
            onPressed: () => prov.toggleFavorite(_food!),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Calorie hero
                AppCard(
                  child: Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          scaledCal.toString(),
                          style: const TextStyle(
                              color: AppColors.coral, fontSize: 68, fontWeight: FontWeight.w800, height: 1),
                        ),
                        const Text('ккал', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                        const SizedBox(height: 4),
                        Text('${n.calories.round()} ккал / 100г',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Quick macros
                Row(
                  children: [
                    _MacroChip('Белки', (n.protein * _grams / 100).toStringAsFixed(1) + 'г', AppColors.protein),
                    const SizedBox(width: 8),
                    _MacroChip('Жиры', (n.fat * _grams / 100).toStringAsFixed(1) + 'г', AppColors.fat),
                    const SizedBox(width: 8),
                    _MacroChip('Углеводы', (n.carbs * _grams / 100).toStringAsFixed(1) + 'г', AppColors.carbs),
                  ],
                ),

                const SizedBox(height: 10),

                // Grams selector
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Порция', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [50, 100, 150, 200, 300].map((p) {
                          final sel = _gramsCtrl.text == p.toString();
                          return GestureDetector(
                            onTap: () => setState(() => _gramsCtrl.text = p.toString()),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? AppColors.primaryMuted : AppColors.bgElevated,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: sel ? AppColors.primary : AppColors.border, width: 0.5),
                              ),
                              child: Text('${p}г',
                                  style: TextStyle(
                                      color: sel ? AppColors.primary : AppColors.textSecondary,
                                      fontSize: 13)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _gramsCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textAlign: TextAlign.center,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('граммов', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Meal selector
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Добавить в:', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 10),
                      Row(
                        children: meals.map((m) {
                          final active = _selectedMeal == m.key;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMeal = m.key),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: active ? m.color.withOpacity(0.12) : AppColors.bgElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: active ? m.color : AppColors.border, width: 0.5),
                                ),
                                child: Column(
                                  children: [
                                    Icon(m.icon, size: 16, color: active ? m.color : AppColors.textMuted),
                                    const SizedBox(height: 3),
                                    Text(m.label,
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: active ? m.color : AppColors.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: TabBar(
                    controller: _tabCtrl,
                    indicator: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    padding: const EdgeInsets.all(4),
                    tabs: const [
                      Tab(text: 'Питательность'),
                      Tab(text: 'Витамины'),
                      Tab(text: 'Минералы'),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      // Nutrition
                      AppCard(
                        child: Column(
                          children: [
                            MacroBar(label: 'Белки', value: n.protein * _grams / 100, goal: prov.goals.protein, color: AppColors.protein),
                            MacroBar(label: 'Жиры', value: n.fat * _grams / 100, goal: prov.goals.fat, color: AppColors.fat),
                            MacroBar(label: 'Углеводы', value: n.carbs * _grams / 100, goal: prov.goals.carbs, color: AppColors.carbs),
                            if (n.fiber > 0) MacroBar(label: 'Клетчатка', value: n.fiber * _grams / 100, goal: prov.goals.fiber, color: AppColors.blue),
                            if (n.sugar > 0) MacroBar(label: 'Сахар', value: n.sugar * _grams / 100, goal: 50, color: AppColors.amber),
                          ],
                        ),
                      ),
                      // Vitamins
                      AppCard(
                        child: _food!.vitamins.isEmpty
                            ? const EmptyState(icon: Icons.science_outlined, title: 'Нет данных')
                            : Column(
                                children: _food!.vitamins.entries.map((e) {
                                  final scaled = e.value.value * _grams / 100;
                                  final pct = getDVPercent(e.key, scaled);
                                  return NutrientRow(
                                    label: e.value.label,
                                    value: scaled,
                                    unit: e.value.unit,
                                    percent: pct,
                                    color: AppColors.primary,
                                  );
                                }).toList(),
                              ),
                      ),
                      // Minerals
                      AppCard(
                        child: _food!.minerals.isEmpty
                            ? const EmptyState(icon: Icons.diamond_outlined, title: 'Нет данных')
                            : Column(
                                children: _food!.minerals.entries.map((e) {
                                  final scaled = e.value.value * _grams / 100;
                                  final pct = getDVPercent(e.key, scaled);
                                  return NutrientRow(
                                    label: e.value.label,
                                    value: scaled,
                                    unit: e.value.unit,
                                    percent: pct,
                                    color: AppColors.green,
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GestureDetector(
            onTap: _handleAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(widget.entryId != null ? Icons.check : Icons.add, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.entryId != null
                        ? 'Сохранить'
                        : 'Добавить $scaledCal ккал → ${mealInfo.label}',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
