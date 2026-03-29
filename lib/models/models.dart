// ─── Nutrition per 100g ───────────────────────────────────────────────────────
class NutritionData {
  final double calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double sugar;

  const NutritionData({
    this.calories = 0,
    this.protein = 0,
    this.fat = 0,
    this.carbs = 0,
    this.fiber = 0,
    this.sugar = 0,
  });

  NutritionData scale(double grams) {
    final f = grams / 100;
    return NutritionData(
      calories: calories * f,
      protein: protein * f,
      fat: fat * f,
      carbs: carbs * f,
      fiber: fiber * f,
      sugar: sugar * f,
    );
  }

  NutritionData operator +(NutritionData other) => NutritionData(
        calories: calories + other.calories,
        protein: protein + other.protein,
        fat: fat + other.fat,
        carbs: carbs + other.carbs,
        fiber: fiber + other.fiber,
        sugar: sugar + other.sugar,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
        'sugar': sugar,
      };

  factory NutritionData.fromJson(Map<String, dynamic> j) => NutritionData(
        calories: (j['calories'] as num?)?.toDouble() ?? 0,
        protein: (j['protein'] as num?)?.toDouble() ?? 0,
        fat: (j['fat'] as num?)?.toDouble() ?? 0,
        carbs: (j['carbs'] as num?)?.toDouble() ?? 0,
        fiber: (j['fiber'] as num?)?.toDouble() ?? 0,
        sugar: (j['sugar'] as num?)?.toDouble() ?? 0,
      );
}

// ─── Micronutrient entry ──────────────────────────────────────────────────────
class MicroNutrient {
  final String label;
  final double value;
  final String unit;

  const MicroNutrient({
    required this.label,
    required this.value,
    required this.unit,
  });

  MicroNutrient scale(double grams) =>
      MicroNutrient(label: label, value: value * grams / 100, unit: unit);

  Map<String, dynamic> toJson() =>
      {'label': label, 'value': value, 'unit': unit};

  factory MicroNutrient.fromJson(Map<String, dynamic> j) => MicroNutrient(
        label: j['label'] as String? ?? '',
        value: (j['value'] as num?)?.toDouble() ?? 0,
        unit: j['unit'] as String? ?? '',
      );
}

// ─── Food item (from USDA) ────────────────────────────────────────────────────
class FoodItem {
  final int fdcId;
  final String name;
  final String? brand;
  final String? category;
  final NutritionData nutrition; // per 100g
  final Map<String, MicroNutrient> vitamins;
  final Map<String, MicroNutrient> minerals;
  final double? servingSize;

  const FoodItem({
    required this.fdcId,
    required this.name,
    this.brand,
    this.category,
    required this.nutrition,
    this.vitamins = const {},
    this.minerals = const {},
    this.servingSize,
  });

  Map<String, dynamic> toJson() => {
        'fdcId': fdcId,
        'name': name,
        'brand': brand,
        'category': category,
        'nutrition': nutrition.toJson(),
        'vitamins': vitamins.map((k, v) => MapEntry(k, v.toJson())),
        'minerals': minerals.map((k, v) => MapEntry(k, v.toJson())),
        'servingSize': servingSize,
      };

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        fdcId: (j['fdcId'] as num).toInt(),
        name: j['name'] as String,
        brand: j['brand'] as String?,
        category: j['category'] as String?,
        nutrition: NutritionData.fromJson(j['nutrition'] as Map<String, dynamic>? ?? {}),
        vitamins: (j['vitamins'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, MicroNutrient.fromJson(v as Map<String, dynamic>)),
        ),
        minerals: (j['minerals'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, MicroNutrient.fromJson(v as Map<String, dynamic>)),
        ),
        servingSize: (j['servingSize'] as num?)?.toDouble(),
      );
}

// ─── Diary entry ──────────────────────────────────────────────────────────────
class DiaryEntry {
  final String id;
  final int fdcId;
  final String name;
  final String? brand;
  final double grams;
  final String mealType;
  final NutritionData nutrition; // per 100g
  final Map<String, MicroNutrient> vitamins;
  final Map<String, MicroNutrient> minerals;
  final DateTime addedAt;

  DiaryEntry({
    required this.id,
    required this.fdcId,
    required this.name,
    this.brand,
    required this.grams,
    required this.mealType,
    required this.nutrition,
    this.vitamins = const {},
    this.minerals = const {},
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  NutritionData get scaledNutrition => nutrition.scale(grams);

  Map<String, dynamic> toJson() => {
        'id': id,
        'fdcId': fdcId,
        'name': name,
        'brand': brand,
        'grams': grams,
        'mealType': mealType,
        'nutrition': nutrition.toJson(),
        'vitamins': vitamins.map((k, v) => MapEntry(k, v.toJson())),
        'minerals': minerals.map((k, v) => MapEntry(k, v.toJson())),
        'addedAt': addedAt.toIso8601String(),
      };

  factory DiaryEntry.fromJson(Map<String, dynamic> j) => DiaryEntry(
        id: j['id'] as String,
        fdcId: (j['fdcId'] as num).toInt(),
        name: j['name'] as String,
        brand: j['brand'] as String?,
        grams: (j['grams'] as num).toDouble(),
        mealType: j['mealType'] as String,
        nutrition: NutritionData.fromJson(j['nutrition'] as Map<String, dynamic>? ?? {}),
        vitamins: (j['vitamins'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, MicroNutrient.fromJson(v as Map<String, dynamic>)),
        ),
        minerals: (j['minerals'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, MicroNutrient.fromJson(v as Map<String, dynamic>)),
        ),
        addedAt: DateTime.tryParse(j['addedAt'] as String? ?? '') ?? DateTime.now(),
      );

  DiaryEntry copyWith({double? grams}) => DiaryEntry(
        id: id,
        fdcId: fdcId,
        name: name,
        brand: brand,
        grams: grams ?? this.grams,
        mealType: mealType,
        nutrition: nutrition,
        vitamins: vitamins,
        minerals: minerals,
        addedAt: addedAt,
      );
}

// ─── Nutrition goals ──────────────────────────────────────────────────────────
class NutritionGoals {
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final int fiber;

  const NutritionGoals({
    this.calories = 2000,
    this.protein = 150,
    this.fat = 65,
    this.carbs = 200,
    this.fiber = 25,
  });

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'fat': fat,
        'carbs': carbs,
        'fiber': fiber,
      };

  factory NutritionGoals.fromJson(Map<String, dynamic> j) => NutritionGoals(
        calories: (j['calories'] as num?)?.toInt() ?? 2000,
        protein: (j['protein'] as num?)?.toInt() ?? 150,
        fat: (j['fat'] as num?)?.toInt() ?? 65,
        carbs: (j['carbs'] as num?)?.toInt() ?? 200,
        fiber: (j['fiber'] as num?)?.toInt() ?? 25,
      );

  NutritionGoals copyWith({int? calories, int? protein, int? fat, int? carbs, int? fiber}) =>
      NutritionGoals(
        calories: calories ?? this.calories,
        protein: protein ?? this.protein,
        fat: fat ?? this.fat,
        carbs: carbs ?? this.carbs,
        fiber: fiber ?? this.fiber,
      );
}

// ─── AI detected food ─────────────────────────────────────────────────────────
class DetectedFood {
  final String name;
  final String nameEn;
  double grams;
  final double confidence;

  DetectedFood({
    required this.name,
    required this.nameEn,
    required this.grams,
    required this.confidence,
  });

  factory DetectedFood.fromJson(Map<String, dynamic> j) => DetectedFood(
        name: j['name'] as String? ?? '',
        nameEn: j['nameEn'] as String? ?? '',
        grams: (j['estimatedGrams'] as num?)?.toDouble() ?? 100,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0.5,
      );
}
