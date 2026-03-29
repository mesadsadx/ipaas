import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

const _diaryKey = 'diary_v2';
const _goalsKey = 'goals_v1';
const _favKey = 'favorites_v1';
const _recentKey = 'recent_v1';

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class AppProvider extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  NutritionGoals _goals = const NutritionGoals();
  NutritionGoals get goals => _goals;

  // { 'yyyy-MM-dd': [DiaryEntry, ...] }
  final Map<String, List<DiaryEntry>> _diary = {};

  List<FoodItem> _favorites = [];
  List<FoodItem> get favorites => _favorites;

  List<FoodItem> _recent = [];
  List<FoodItem> get recent => _recent;

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Goals
    final goalsRaw = prefs.getString(_goalsKey);
    if (goalsRaw != null) {
      _goals = NutritionGoals.fromJson(jsonDecode(goalsRaw) as Map<String, dynamic>);
    }

    // Diary
    final diaryRaw = prefs.getString(_diaryKey);
    if (diaryRaw != null) {
      final map = jsonDecode(diaryRaw) as Map<String, dynamic>;
      for (final entry in map.entries) {
        _diary[entry.key] = (entry.value as List)
            .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    // Favorites
    final favRaw = prefs.getString(_favKey);
    if (favRaw != null) {
      _favorites = (jsonDecode(favRaw) as List)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Recent
    final recentRaw = prefs.getString(_recentKey);
    if (recentRaw != null) {
      _recent = (jsonDecode(recentRaw) as List)
          .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    notifyListeners();
  }

  // ── Date navigation ────────────────────────────────────────────────────────
  void setDate(DateTime d) {
    _selectedDate = d;
    notifyListeners();
  }

  void goToday() {
    _selectedDate = DateTime.now();
    notifyListeners();
  }

  // ── Diary access ───────────────────────────────────────────────────────────
  List<DiaryEntry> getEntries(DateTime date, String mealType) {
    final key = _dateKey(date);
    return (_diary[key] ?? []).where((e) => e.mealType == mealType).toList();
  }

  List<DiaryEntry> getAllEntries(DateTime date) {
    return _diary[_dateKey(date)] ?? [];
  }

  NutritionData getDayTotals(DateTime date) {
    return getAllEntries(date).fold(
      const NutritionData(),
      (acc, e) => acc + e.scaledNutrition,
    );
  }

  // ── Diary mutations ────────────────────────────────────────────────────────
  Future<void> addEntry(DiaryEntry entry) async {
    final key = _dateKey(DateTime.now());
    _diary.putIfAbsent(key, () => []);
    _diary[key]!.add(entry);
    await _saveDiary();
    notifyListeners();
  }

  Future<void> removeEntry(DateTime date, String entryId) async {
    final key = _dateKey(date);
    _diary[key]?.removeWhere((e) => e.id == entryId);
    await _saveDiary();
    notifyListeners();
  }

  Future<void> updateEntryGrams(DateTime date, String entryId, double grams) async {
    final key = _dateKey(date);
    final idx = _diary[key]?.indexWhere((e) => e.id == entryId) ?? -1;
    if (idx >= 0) {
      _diary[key]![idx] = _diary[key]![idx].copyWith(grams: grams);
      await _saveDiary();
      notifyListeners();
    }
  }

  Future<void> _saveDiary() async {
    final prefs = await SharedPreferences.getInstance();
    final map = _diary.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()));
    await prefs.setString(_diaryKey, jsonEncode(map));
  }

  // ── Goals ──────────────────────────────────────────────────────────────────
  Future<void> setGoals(NutritionGoals goals) async {
    _goals = goals;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalsKey, jsonEncode(goals.toJson()));
    notifyListeners();
  }

  // ── Favorites ──────────────────────────────────────────────────────────────
  bool isFavorite(int fdcId) => _favorites.any((f) => f.fdcId == fdcId);

  Future<void> toggleFavorite(FoodItem food) async {
    if (isFavorite(food.fdcId)) {
      _favorites.removeWhere((f) => f.fdcId == food.fdcId);
    } else {
      _favorites.insert(0, food);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favKey, jsonEncode(_favorites.map((f) => f.toJson()).toList()));
    notifyListeners();
  }

  // ── Recent ─────────────────────────────────────────────────────────────────
  Future<void> addToRecent(FoodItem food) async {
    _recent.removeWhere((f) => f.fdcId == food.fdcId);
    _recent.insert(0, food);
    if (_recent.length > 20) _recent = _recent.take(20).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recentKey, jsonEncode(_recent.map((f) => f.toJson()).toList()));
    notifyListeners();
  }

  // ── Weekly data ────────────────────────────────────────────────────────────
  List<({DateTime date, String label, NutritionData totals})> getWeekData() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      final labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return (
        date: d,
        label: labels[d.weekday - 1],
        totals: getDayTotals(d),
      );
    });
  }
}
