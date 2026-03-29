import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/usda_service.dart';
import '../services/ai_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class PhotoAnalysisScreen extends StatefulWidget {
  final String imagePath;
  final String mealType;
  final DateTime date;

  const PhotoAnalysisScreen({
    super.key,
    required this.imagePath,
    required this.mealType,
    required this.date,
  });

  @override
  State<PhotoAnalysisScreen> createState() => _PhotoAnalysisScreenState();
}

enum _Step { analyzing, matching, confirming, done }

class _PhotoAnalysisScreenState extends State<PhotoAnalysisScreen> {
  _Step _step = _Step.analyzing;
  List<DetectedFood> _items = [];
  List<List<FoodItem>> _matches = [];
  String _aiNotes = '';
  final Set<int> _addingIdx = {};

  late MealInfo _mealInfo;

  @override
  void initState() {
    super.initState();
    _mealInfo = getMealInfo(widget.mealType);
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    try {
      // Read image as base64
      final bytes = await File(widget.imagePath).readAsBytes();
      final base64 = base64Encode(bytes);

      setState(() => _step = _Step.analyzing);
      final result = await AiService.analyzeFoodPhoto(base64);

      setState(() {
        _items = result.items;
        _aiNotes = result.notes;
        _step = _Step.matching;
      });

      // Match each item with USDA
      final searches = await Future.wait(
        result.items.take(6).map((item) =>
            UsdaService.searchFoods(item.nameEn.isNotEmpty ? item.nameEn : item.name, pageSize: 3)
                .catchError((_) => <FoodItem>[])),
      );

      setState(() {
        _matches = searches;
        _step = _Step.confirming;
      });
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: const Text('Ошибка', style: TextStyle(color: AppColors.textPrimary)),
          content: Text('Не удалось проанализировать фото: $e',
              style: const TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _addItem(int idx) async {
    if (idx >= _items.length || idx >= _matches.length) return;
    final item = _items[idx];
    final bestMatch = _matches[idx].firstOrNull;
    if (bestMatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Не найдено: ${item.name}'),
        backgroundColor: AppColors.coral,
      ));
      return;
    }

    setState(() => _addingIdx.add(idx));

    try {
      final detail = await UsdaService.getFoodDetails(bestMatch.fdcId) ?? bestMatch;
      final prov = context.read<AppProvider>();
      await prov.addEntry(DiaryEntry(
        id: '${DateTime.now().millisecondsSinceEpoch}_$idx',
        fdcId: detail.fdcId,
        name: item.name.isNotEmpty ? item.name : detail.name,
        brand: detail.brand,
        grams: item.grams,
        mealType: widget.mealType,
        nutrition: detail.nutrition,
        vitamins: detail.vitamins,
        minerals: detail.minerals,
      ));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка добавления'), backgroundColor: AppColors.coral),
      );
    } finally {
      if (mounted) setState(() => _addingIdx.remove(idx));
    }
  }

  Future<void> _addAll() async {
    for (int i = 0; i < _items.length; i++) await _addItem(i);
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _Step.analyzing || _step == _Step.matching) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            Image.file(File(widget.imagePath), height: 300, width: double.infinity, fit: BoxFit.cover),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryMuted,
                        borderRadius: BorderRadius.circular(36),
                      ),
                      child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _step == _Step.analyzing ? 'ИИ распознаёт блюда...' : 'Ищу в базе данных...',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == _Step.analyzing
                          ? 'Claude анализирует фото и оценивает вес'
                          : 'Сопоставляю с USDA FoodData Central',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Распознанные блюда',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.done_all, color: AppColors.primary, size: 16),
            label: const Text('Добавить всё', style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
            onPressed: _addAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(File(widget.imagePath), height: 200, fit: BoxFit.cover),
          ),

          if (_aiNotes.isNotEmpty) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_aiNotes,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Icon(_mealInfo.icon, size: 15, color: _mealInfo.color),
              const SizedBox(width: 6),
              Text('Добавить в: ',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              Text(_mealInfo.label,
                  style: TextStyle(color: _mealInfo.color, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),

          if (_items.isEmpty)
            Column(
              children: [
                const EmptyState(icon: Icons.camera_alt_outlined, title: 'ИИ не смог распознать блюда',
                    subtitle: 'Попробуйте при лучшем освещении'),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Попробовать снова', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            ..._items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final best = i < _matches.length ? _matches[i].firstOrNull : null;
              final adding = _addingIdx.contains(i);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                                if (best != null)
                                  Text('→ ${best.name}', maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                            onPressed: () => setState(() { _items.removeAt(i); _matches.removeAt(i); }),
                          ),
                        ],
                      ),

                      // Confidence
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.analytics_outlined, size: 13, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          const Text('Уверенность',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: item.confidence,
                                minHeight: 4,
                                backgroundColor: AppColors.bgElevated,
                                valueColor: AlwaysStoppedAnimation(
                                    item.confidence > 0.7 ? AppColors.green : AppColors.amber),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(item.confidence * 100).round()}%',
                              style: TextStyle(
                                  color: item.confidence > 0.7 ? AppColors.green : AppColors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),

                      // Grams input
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.scale_outlined, size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          const Text('Вес:', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 76,
                            child: TextField(
                              controller: TextEditingController(text: item.grams.round().toString())
                                ..selection = TextSelection.collapsed(offset: item.grams.round().toString().length),
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textAlign: TextAlign.center,
                              onChanged: (v) => item.grams = double.tryParse(v) ?? item.grams,
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('г', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        ],
                      ),

                      // Macro preview
                      if (best != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _MicroChip('${(best.nutrition.calories * item.grams / 100).round()} ккал', AppColors.coral),
                            const SizedBox(width: 6),
                            _MicroChip('Б ${(best.nutrition.protein * item.grams / 100).toStringAsFixed(1)}г', AppColors.protein),
                            const SizedBox(width: 6),
                            _MicroChip('Ж ${(best.nutrition.fat * item.grams / 100).toStringAsFixed(1)}г', AppColors.fat),
                            const SizedBox(width: 6),
                            _MicroChip('У ${(best.nutrition.carbs * item.grams / 100).toStringAsFixed(1)}г', AppColors.carbs),
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: adding ? null : () => _addItem(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: adding
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add, color: Colors.white, size: 18),
                                      const SizedBox(width: 6),
                                      Text('Добавить в ${_mealInfo.label}',
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _MicroChip extends StatelessWidget {
  final String text;
  final Color color;
  const _MicroChip(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
