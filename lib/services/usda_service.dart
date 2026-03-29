import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

// Get your free key at: https://fdc.nal.usda.gov/api-key-signup.html
const _apiKey = 'DEMO_KEY';
const _base = 'https://api.nal.usda.gov/fdc/v1';

// USDA nutrient IDs
const _ids = {
  'calories': 1008,
  'protein': 1003,
  'fat': 1004,
  'carbs': 1005,
  'fiber': 1079,
  'sugar': 2000,
  // Vitamins
  'vitA': 1106,
  'vitC': 1162,
  'vitD': 1114,
  'vitE': 1109,
  'vitK': 1185,
  'vitB1': 1165,
  'vitB2': 1166,
  'vitB3': 1167,
  'vitB6': 1175,
  'vitB9': 1177,
  'vitB12': 1178,
  // Minerals
  'calcium': 1087,
  'iron': 1089,
  'magnesium': 1090,
  'phosphorus': 1091,
  'potassium': 1092,
  'sodium': 1093,
  'zinc': 1095,
  'copper': 1098,
  'manganese': 1101,
  'selenium': 1103,
};

// Daily values for % calculation
const dailyValues = {
  'calories': 2000.0,
  'protein': 50.0,
  'fat': 78.0,
  'carbs': 275.0,
  'fiber': 28.0,
  'sugar': 50.0,
  'vitA': 900.0,
  'vitC': 90.0,
  'vitD': 20.0,
  'vitE': 15.0,
  'vitK': 120.0,
  'vitB1': 1.2,
  'vitB2': 1.3,
  'vitB3': 16.0,
  'vitB6': 1.7,
  'vitB9': 400.0,
  'vitB12': 2.4,
  'calcium': 1300.0,
  'iron': 18.0,
  'magnesium': 420.0,
  'phosphorus': 1250.0,
  'potassium': 4700.0,
  'sodium': 2300.0,
  'zinc': 11.0,
  'copper': 0.9,
  'manganese': 2.3,
  'selenium': 55.0,
};

const _vitaminLabels = {
  'vitA': ('Витамин A', 'mcg'),
  'vitC': ('Витамин C', 'мг'),
  'vitD': ('Витамин D', 'mcg'),
  'vitE': ('Витамин E', 'мг'),
  'vitK': ('Витамин K', 'mcg'),
  'vitB1': ('B1 (тиамин)', 'мг'),
  'vitB2': ('B2 (рибофлавин)', 'мг'),
  'vitB3': ('B3 (ниацин)', 'мг'),
  'vitB6': ('B6', 'мг'),
  'vitB9': ('B9 (фолат)', 'mcg'),
  'vitB12': ('B12', 'mcg'),
};

const _mineralLabels = {
  'calcium': ('Кальций', 'мг'),
  'iron': ('Железо', 'мг'),
  'magnesium': ('Магний', 'мг'),
  'phosphorus': ('Фосфор', 'мг'),
  'potassium': ('Калий', 'мг'),
  'sodium': ('Натрий', 'мг'),
  'zinc': ('Цинк', 'мг'),
  'copper': ('Медь', 'мг'),
  'manganese': ('Марганец', 'мг'),
  'selenium': ('Селен', 'mcg'),
};

double _getNutrient(List nutrients, int id) {
  for (final n in nutrients) {
    final nId = n['nutrientId'] ?? n['nutrient']?['id'];
    if (nId == id) {
      return ((n['value'] ?? n['amount']) as num?)?.toDouble() ?? 0;
    }
  }
  return 0;
}

FoodItem _parseSimpleFood(Map<String, dynamic> food) {
  final nutrients = food['foodNutrients'] as List? ?? [];
  return FoodItem(
    fdcId: (food['fdcId'] as num).toInt(),
    name: food['description'] as String? ?? '',
    brand: food['brandOwner'] as String? ?? food['brandName'] as String?,
    category: food['foodCategory'] as String? ?? food['foodCategoryLabel'] as String?,
    nutrition: NutritionData(
      calories: _getNutrient(nutrients, 1008),
      protein: _getNutrient(nutrients, 1003),
      fat: _getNutrient(nutrients, 1004),
      carbs: _getNutrient(nutrients, 1005),
      fiber: _getNutrient(nutrients, 1079),
      sugar: _getNutrient(nutrients, 2000),
    ),
  );
}

FoodItem _parseFullFood(Map<String, dynamic> food) {
  final nutrients = food['foodNutrients'] as List? ?? [];

  double getV(String key) => _getNutrient(nutrients, _ids[key]!);

  final vitamins = <String, MicroNutrient>{};
  for (final entry in _vitaminLabels.entries) {
    final v = getV(entry.key);
    if (v > 0) {
      vitamins[entry.key] = MicroNutrient(
        label: entry.value.$1,
        value: v,
        unit: entry.value.$2,
      );
    }
  }

  final minerals = <String, MicroNutrient>{};
  for (final entry in _mineralLabels.entries) {
    final v = getV(entry.key);
    if (v > 0) {
      minerals[entry.key] = MicroNutrient(
        label: entry.value.$1,
        value: v,
        unit: entry.value.$2,
      );
    }
  }

  return FoodItem(
    fdcId: (food['fdcId'] as num).toInt(),
    name: food['description'] as String? ?? '',
    brand: food['brandOwner'] as String? ?? food['brandName'] as String?,
    category: (food['foodCategory'] as Map<String, dynamic>?)?['description'] as String? ??
        food['foodCategoryLabel'] as String?,
    nutrition: NutritionData(
      calories: getV('calories'),
      protein: getV('protein'),
      fat: getV('fat'),
      carbs: getV('carbs'),
      fiber: getV('fiber'),
      sugar: getV('sugar'),
    ),
    vitamins: vitamins,
    minerals: minerals,
    servingSize: (food['servingSize'] as num?)?.toDouble(),
  );
}

class UsdaService {
  static Future<List<FoodItem>> searchFoods(String query, {int pageSize = 25}) async {
    final uri = Uri.parse('$_base/foods/search?api_key=$_apiKey');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': query,
        'dataType': ['Foundation', 'SR Legacy', 'Branded'],
        'pageSize': pageSize,
        'pageNumber': 1,
      }),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final foods = data['foods'] as List? ?? [];
    return foods.map((f) => _parseSimpleFood(f as Map<String, dynamic>)).toList();
  }

  static Future<FoodItem?> getFoodDetails(int fdcId) async {
    final uri = Uri.parse('$_base/food/$fdcId?api_key=$_apiKey');
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return _parseFullFood(data);
  }

  static Future<List<FoodItem>> searchByBarcode(String barcode) async {
    final uri = Uri.parse('$_base/foods/search?api_key=$_apiKey');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': barcode,
        'dataType': ['Branded'],
        'pageSize': 5,
      }),
    );
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final foods = data['foods'] as List? ?? [];
    return foods.map((f) => _parseSimpleFood(f as Map<String, dynamic>)).toList();
  }
}

double getDVPercent(String key, double value) {
  final dv = dailyValues[key];
  if (dv == null || dv == 0) return 0;
  return (value / dv * 100).clamp(0, 999);
}
