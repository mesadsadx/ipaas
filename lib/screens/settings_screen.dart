import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, TextEditingController> _ctrls;
  bool _saved = false;
  bool _showCalc = false;

  // BMR calculator
  final _weight = TextEditingController(text: '70');
  final _height = TextEditingController(text: '175');
  final _age = TextEditingController(text: '30');
  String _gender = 'male';
  String _activity = 'moderate';

  static const _activityMult = {
    'sedentary': (label: 'Малоподвижный', value: 1.2),
    'light': (label: 'Лёгкая активность', value: 1.375),
    'moderate': (label: 'Умеренная', value: 1.55),
    'active': (label: 'Высокая активность', value: 1.725),
    'veryActive': (label: 'Очень высокая', value: 1.9),
  };

  @override
  void initState() {
    super.initState();
    final goals = context.read<AppProvider>().goals;
    _ctrls = {
      'calories': TextEditingController(text: goals.calories.toString()),
      'protein': TextEditingController(text: goals.protein.toString()),
      'fat': TextEditingController(text: goals.fat.toString()),
      'carbs': TextEditingController(text: goals.carbs.toString()),
      'fiber': TextEditingController(text: goals.fiber.toString()),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    _weight.dispose(); _height.dispose(); _age.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final goals = NutritionGoals(
      calories: int.tryParse(_ctrls['calories']!.text) ?? 2000,
      protein: int.tryParse(_ctrls['protein']!.text) ?? 150,
      fat: int.tryParse(_ctrls['fat']!.text) ?? 65,
      carbs: int.tryParse(_ctrls['carbs']!.text) ?? 200,
      fiber: int.tryParse(_ctrls['fiber']!.text) ?? 25,
    );
    await context.read<AppProvider>().setGoals(goals);
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _saved = false);
  }

  void _applyTDEE() {
    final w = double.tryParse(_weight.text) ?? 70;
    final h = double.tryParse(_height.text) ?? 175;
    final a = int.tryParse(_age.text) ?? 30;
    final base = 10 * w + 6.25 * h - 5 * a;
    final bmr = _gender == 'male' ? base + 5 : base - 161;
    final mult = _activityMult[_activity]?.value ?? 1.55;
    final tdee = (bmr * mult).round();
    final prot = (w * 1.8).round();
    final fat = (tdee * 0.25 / 9).round();
    final carbs = (tdee * 0.45 / 4).round();

    setState(() {
      _ctrls['calories']!.text = tdee.toString();
      _ctrls['protein']!.text = prot.toString();
      _ctrls['fat']!.text = fat.toString();
      _ctrls['carbs']!.text = carbs.toString();
      _showCalc = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('TDEE: $tdee ккал  |  Белки: ${prot}г'),
      backgroundColor: AppColors.green,
    ));
  }

  static const _goalFields = [
    (key: 'calories', label: 'Калории',   unit: 'ккал', icon: Icons.local_fire_department_outlined, color: AppColors.coral),
    (key: 'protein',  label: 'Белки',     unit: 'г',    icon: Icons.fitness_center_outlined,         color: AppColors.protein),
    (key: 'fat',      label: 'Жиры',      unit: 'г',    icon: Icons.water_drop_outlined,             color: AppColors.fat),
    (key: 'carbs',    label: 'Углеводы',  unit: 'г',    icon: Icons.grass_outlined,                  color: AppColors.carbs),
    (key: 'fiber',    label: 'Клетчатка', unit: 'г',    icon: Icons.eco_outlined,                    color: AppColors.blue),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Настройки',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),

                  const SectionLabel(icon: Icons.emoji_events_outlined, label: 'Суточные цели'),
                  AppCard(
                    child: Column(
                      children: _goalFields.map((f) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                color: f.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(f.icon, color: f.color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(f.label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15))),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _ctrls[f.key],
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
                                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(width: 28, child: Text(f.unit, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),

                  // TDEE calculator toggle
                  GestureDetector(
                    onTap: () => setState(() => _showCalc = !_showCalc),
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calculate_outlined, color: AppColors.primary, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(child: Text('Рассчитать по параметрам тела',
                              style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600))),
                          Icon(_showCalc ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),

                  if (_showCalc) ...[
                    const SizedBox(height: 10),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Параметры тела', style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _CalcField(label: 'Вес (кг)', ctrl: _weight),
                              const SizedBox(width: 10),
                              _CalcField(label: 'Рост (см)', ctrl: _height),
                              const SizedBox(width: 10),
                              _CalcField(label: 'Возраст', ctrl: _age),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text('Пол', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: _GenderBtn(icon: Icons.male, label: 'Мужской', selected: _gender == 'male',
                                  onTap: () => setState(() => _gender = 'male'))),
                              const SizedBox(width: 10),
                              Expanded(child: _GenderBtn(icon: Icons.female, label: 'Женский', selected: _gender == 'female',
                                  onTap: () => setState(() => _gender = 'female'))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text('Активность', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 8),
                          ..._activityMult.entries.map((e) => GestureDetector(
                            onTap: () => setState(() => _activity = e.key),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: _activity == e.key ? AppColors.primaryMuted : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 16, height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.border, width: 1.5),
                                    ),
                                    child: _activity == e.key
                                        ? const Center(child: CircleAvatar(radius: 4, backgroundColor: AppColors.primary))
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(e.value.label, style: TextStyle(
                                      color: _activity == e.key ? AppColors.textPrimary : AppColors.textSecondary,
                                      fontSize: 14))),
                                  Text('×${e.value.value}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                          )),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _applyTDEE,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Рассчитать и применить',
                                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // About
                  const SectionLabel(icon: Icons.info_outline, label: 'О приложении'),
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow(icon: Icons.eco_outlined, label: 'База данных', value: 'USDA FoodData Central'),
                        _InfoRow(icon: Icons.auto_awesome_outlined, label: 'ИИ модель', value: 'Claude 3.5 Sonnet'),
                        _InfoRow(icon: Icons.code, label: 'Технология', value: 'Flutter + Dart'),
                        _InfoRow(icon: Icons.tag, label: 'Версия', value: '1.0.0', last: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),

            // Save bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.bg,
                border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: _save,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _saved ? AppColors.green : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_saved ? Icons.check : Icons.save_outlined, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(_saved ? 'Сохранено!' : 'Сохранить цели',
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  const _CalcField({required this.label, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
          ),
        ],
      ),
    );
  }
}

class _GenderBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _GenderBtn({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryMuted : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted, size: 18),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool last;
  const _InfoRow({required this.icon, required this.label, required this.value, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: last ? null : const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5))),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14))),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
