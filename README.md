# 🥗 NutriTrack — Flutter

Кросс-платформенное приложение (iOS + Android) для трекинга питания.
Написано на **Dart / Flutter** — компилируется в нативный код.

---

## 🚀 Быстрый старт

### 1. Создать Flutter-проект и подставить код

```bash
# Создаём новый проект
flutter create nutritrack --org com.yourname

# Переходим в папку
cd nutritrack

# Удаляем стандартный lib/
rm -rf lib/

# Копируем наш lib/ из архива
cp -r /path/to/downloaded/lib .

# Подставляем наш pubspec.yaml
cp /path/to/downloaded/pubspec.yaml .
```

### 2. Установить зависимости

```bash
flutter pub get
```

### 3. Вставить API ключи

#### USDA FoodData Central (бесплатно)
1. https://fdc.nal.usda.gov/api-key-signup.html
2. Открой `lib/services/usda_service.dart`
3. Замени `DEMO_KEY` на свой ключ

#### OpenRouter (для фото и ИИ)
1. https://openrouter.ai/keys
2. Открой `lib/services/ai_service.dart`
3. Замени `YOUR_OPENROUTER_API_KEY` на свой ключ

### 4. Запустить

```bash
# Посмотреть доступные устройства
flutter devices

# Запустить на устройстве/эмуляторе
flutter run

# Собрать APK для Android
flutter build apk --release

# Собрать для iOS (только на macOS)
flutter build ios --release
```

---

## 📱 Функции

| Экран       | Функции |
|-------------|---------|
| 📓 Дневник  | Кольцо калорий, макро-бары, приёмы пищи, навигация по дням |
| 🔍 Поиск    | Текст / ИИ фраза / Штрихкод / **Фото еды** |
| 🍽️ Продукт | Калории, БЖУ, витамины, минералы, выбор порции |
| 📊 Статистика | Графики за 7 дней, соотношение БЖУ, ИИ-совет |
| ⚙️ Настройки | Цели КБЖУ, TDEE-калькулятор |

---

## 📦 Структура проекта

```
lib/
├── main.dart                          # Точка входа
├── theme/
│   └── app_theme.dart                 # Цвета, темы, MEAL_INFO
├── models/
│   └── models.dart                    # FoodItem, DiaryEntry, NutritionData
├── services/
│   ├── usda_service.dart              # USDA FoodData Central API
│   └── ai_service.dart               # OpenRouter / Claude Vision
├── providers/
│   └── app_provider.dart             # Состояние (ChangeNotifier)
├── widgets/
│   └── widgets.dart                   # MacroRing, MacroBar, FoodListTile...
└── screens/
    ├── main_screen.dart               # Bottom navigation
    ├── diary_screen.dart              # Дневник питания
    ├── search_screen.dart             # Поиск (4 режима)
    ├── food_detail_screen.dart        # Карточка продукта
    ├── photo_analysis_screen.dart     # Анализ фото ИИ
    ├── barcode_scanner_screen.dart    # Сканер штрихкода
    ├── stats_screen.dart              # Статистика
    └── settings_screen.dart          # Настройки + TDEE
```

---

## ⚙️ Разрешения

### Android — добавить в `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS — добавить в `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>NutriTrack использует камеру для фото еды и сканирования штрихкодов</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>NutriTrack читает фото из галереи для анализа блюд</string>
```

---

## 💰 Стоимость API

| API | Цена |
|-----|------|
| USDA FoodData Central | Бесплатно |
| Claude 3.5 Sonnet (фото) | ~$0.003 за анализ |
| Claude 3.5 Haiku (поиск/советы) | ~$0.0001 за запрос |

---

## 🛠️ Зависимости

```yaml
provider: ^6.1.2          # State management
http: ^1.2.1               # HTTP запросы
shared_preferences: ^2.3.2 # Локальное хранение
image_picker: ^1.1.2       # Выбор фото
mobile_scanner: ^5.2.3     # Сканер штрихкода
intl: ^0.19.0              # Форматирование дат (ru)
```
