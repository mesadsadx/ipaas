import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/app_provider.dart';
import '../services/usda_service.dart';
import '../services/ai_service.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'food_detail_screen.dart';
import 'barcode_scanner_screen.dart';
import 'photo_analysis_screen.dart';

enum SearchMode { text, ai, barcode, photo }

class SearchScreen extends StatefulWidget {
  final String mealType;
  final DateTime date;

  const SearchScreen({super.key, required this.mealType, required this.date});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  SearchMode _mode = SearchMode.text;
  final _ctrl = TextEditingController();
  List<FoodItem> _results = [];
  bool _loading = false;
  int? _aiGramsHint;

  late MealInfo _mealInfo;

  @override
  void initState() {
    super.initState();
    _mealInfo = getMealInfo(widget.mealType);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _doTextSearch() async {
    if (_ctrl.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _results = []; });
    try {
      final results = await UsdaService.searchFoods(_ctrl.text.trim());
      setState(() => _results = results);
    } catch (_) {
      _showError('Ошибка поиска. Проверьте интернет-соединение.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _doAiSearch() async {
    if (_ctrl.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _results = []; });
    try {
      final parsed = await AiService.smartSearch(_ctrl.text.trim());
      if (parsed.isEmpty) { _showError('ИИ не понял. Опишите подробнее.'); return; }

      final searches = await Future.wait(
        parsed.map((p) => UsdaService.searchFoods(p.nameEn, pageSize: 5)),
      );
      final merged = searches.expand((l) => l).toList();
      setState(() => _results = merged);
    } catch (_) {
      _showError('Ошибка ИИ. Проверьте ключ OpenRouter.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickPhoto({required bool fromCamera}) async {
    final picker = ImagePicker();
    final picked = fromCamera
        ? await picker.pickImage(source: ImageSource.camera, imageQuality: 80)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoAnalysisScreen(
          imagePath: picked.path,
          mealType: widget.mealType,
          date: widget.date,
        ),
      ),
    );
  }

  void _openBarcode() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BarcodeScannerScreen(mealType: widget.mealType, date: widget.date),
        ),
      );

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.coral,
    ));
  }

  void _selectFood(FoodItem food) {
    context.read<AppProvider>().addToRecent(food);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailScreen(
          food: food,
          mealType: widget.mealType,
          date: widget.date,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Добавить еду',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            Row(
              children: [
                Icon(_mealInfo.icon, size: 12, color: _mealInfo.color),
                const SizedBox(width: 4),
                Text(_mealInfo.label,
                    style: TextStyle(color: _mealInfo.color, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ── mode tabs ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _ModeTab(icon: Icons.search, label: 'Поиск', active: _mode == SearchMode.text,
                    onTap: () => setState(() { _mode = SearchMode.text; _results = []; })),
                const SizedBox(width: 8),
                _ModeTab(icon: Icons.auto_awesome, label: 'ИИ', active: _mode == SearchMode.ai,
                    onTap: () => setState(() { _mode = SearchMode.ai; _results = []; })),
                const SizedBox(width: 8),
                _ModeTab(icon: Icons.barcode_reader, label: 'Штрихкод', active: _mode == SearchMode.barcode,
                    onTap: () { setState(() { _mode = SearchMode.barcode; _results = []; }); }),
                const SizedBox(width: 8),
                _ModeTab(icon: Icons.camera_alt_outlined, label: 'Фото', active: _mode == SearchMode.photo,
                    onTap: () => setState(() { _mode = SearchMode.photo; _results = []; })),
              ],
            ),
          ),

          // ── input ──
          if (_mode == SearchMode.text || _mode == SearchMode.ai)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: _mode == SearchMode.ai
                            ? 'Съел тарелку борща...'
                            : 'Куриная грудка, гречка...',
                        prefixIcon: Icon(
                          _mode == SearchMode.ai ? Icons.auto_awesome : Icons.search,
                          color: AppColors.textMuted,
                        ),
                        suffixIcon: _ctrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 18),
                                onPressed: () => setState(() => _ctrl.clear()),
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) =>
                          _mode == SearchMode.text ? _doTextSearch() : _doAiSearch(),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _mode == SearchMode.text ? _doTextSearch : _doAiSearch,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          // ── content ──
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_mode == SearchMode.barcode) _BarcodeCard(onTap: _openBarcode),
                  if (_mode == SearchMode.photo) _PhotoCard(onCamera: () => _pickPhoto(fromCamera: true), onGallery: () => _pickPhoto(fromCamera: false)),

                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._results.map((f) => FoodListTile(food: f, onTap: () => _selectFood(f))),
                  ] else if (_mode == SearchMode.text || _mode == SearchMode.ai) ...[
                    if (prov.favorites.isNotEmpty) ...[
                      const SectionLabel(icon: Icons.star_outline, label: 'Избранное'),
                      ...prov.favorites.take(5).map((f) => FoodListTile(food: f, onTap: () => _selectFood(f))),
                    ],
                    if (prov.recent.isNotEmpty) ...[
                      const SectionLabel(icon: Icons.access_time_outlined, label: 'Недавние'),
                      ...prov.recent.take(10).map((f) => FoodListTile(food: f, onTap: () => _selectFood(f))),
                    ],
                    if (prov.favorites.isEmpty && prov.recent.isEmpty)
                      const EmptyState(
                        icon: Icons.search,
                        title: 'Найдите продукт',
                        subtitle: 'Введите название на русском или английском',
                      ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryMuted : AppColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.border,
              width: 0.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: active ? AppColors.primary : AppColors.textMuted),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: active ? AppColors.primary : AppColors.textMuted,
                      fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarcodeCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BarcodeCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderStrong, width: 1),
        ),
        child: Column(
          children: [
            const Icon(Icons.barcode_reader, size: 56, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('Открыть сканер',
                style: TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Наведите камеру на штрихкод продукта',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PhotoCard({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryMuted,
                  borderRadius: BorderRadius.circular(36),
                ),
                child: const Icon(Icons.camera_alt, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              const Text('Распознавание по фото',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('ИИ определит блюда и примерный вес каждого',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onCamera,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.camera_alt, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('Сфотографировать',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onGallery,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, color: AppColors.textPrimary, size: 20),
                SizedBox(width: 10),
                Text('Выбрать из галереи',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Для лучшей точности',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6)),
              SizedBox(height: 10),
              _TipRow(icon: Icons.radio_button_unchecked, text: 'Положите монету рядом — ИИ определит масштаб'),
              _TipRow(icon: Icons.phone_android_outlined, text: 'Снимите сверху и сбоку для оценки объёма'),
              _TipRow(icon: Icons.wb_sunny_outlined, text: 'Хорошее освещение улучшает распознавание'),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        ],
      ),
    );
  }
}
