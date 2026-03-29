import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

// Get your key at: https://openrouter.ai/keys
const _apiKey = 'YOUR_OPENROUTER_API_KEY';
const _base = 'https://openrouter.ai/api/v1/chat/completions';




// Vision model — supports image input, used ONLY for photo analysis
// 100% free — qwen2.5-vl-72b, specialised vision-language model
const _visionModel = 'qwen/qwen2.5-vl-72b-instruct:free';
// Text model — FREE, used for smart search and AI insights
// nvidia/nemotron-3-nano-30b-a3b:free = $0/M tokens
const _textModel   = 'nvidia/nemotron-3-nano-30b-a3b:free';

const _headers = {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $_apiKey',
  'HTTP-Referer': 'nutritrack-app',
  'X-Title': 'NutriTrack',
};

Future<String?> _chat(String model, List<Map<String, dynamic>> messages, {int maxTokens = 500}) async {
  final res = await http.post(
    Uri.parse(_base),
    headers: _headers,
    body: jsonEncode({
      'model': model,
      'max_tokens': maxTokens,
      'messages': messages,
    }),
  );
  if (res.statusCode != 200) return null;
  final data = jsonDecode(res.body) as Map<String, dynamic>;
  return (data['choices'] as List?)?.firstOrNull?['message']?['content'] as String?;
}

String _cleanJson(String raw) => raw.replaceAll(RegExp(r'```json|```'), '').trim();

class AiService {
  /// Analyze food photo — returns detected items with estimated grams
  static Future<({List<DetectedFood> items, String notes})> analyzeFoodPhoto(
      String base64Image) async {
    const prompt = '''Ты — эксперт по питанию. Проанализируй фото еды и верни JSON.

Определи все блюда/продукты. Для каждого:
- name: название на русском
- nameEn: название на английском (для USDA)
- estimatedGrams: примерный вес в граммах
- confidence: уверенность 0..1

Отвечай ТОЛЬКО валидным JSON без markdown:
{"items":[{"name":"...","nameEn":"...","estimatedGrams":150,"confidence":0.9}],"notes":"..."}''';

    final text = await _chat(
      _visionModel,
      [
        {
          'role': 'user',
          'content': [
            {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}},
            {'type': 'text', 'text': prompt},
          ],
        }
      ],
      maxTokens: 1000,
    );

    if (text == null) return (items: <DetectedFood>[], notes: 'Ошибка API');

    try {
      final j = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
      final items = (j['items'] as List? ?? [])
          .map((e) => DetectedFood.fromJson(e as Map<String, dynamic>))
          .toList();
      return (items: items, notes: j['notes'] as String? ?? '');
    } catch (_) {
      return (items: <DetectedFood>[], notes: 'Не удалось распознать');
    }
  }

  /// Smart natural language search
  static Future<List<({String nameEn, String nameRu, int estimatedGrams})>> smartSearch(
      String input) async {
    final prompt = '''Пользователь описал что съел: "$input"
Разбей на продукты для поиска в USDA. Ответь ТОЛЬКО JSON:
{"foods":[{"nameEn":"chicken breast grilled","nameRu":"Куриная грудка","estimatedGrams":150}]}''';

    final text = await _chat(_textModel, [
      {'role': 'user', 'content': prompt}
    ]);

    if (text == null) return [];
    try {
      final j = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
      return (j['foods'] as List? ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return (
          nameEn: m['nameEn'] as String? ?? '',
          nameRu: m['nameRu'] as String? ?? '',
          estimatedGrams: (m['estimatedGrams'] as num?)?.toInt() ?? 100,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Get personalized nutrition insight for the day
  static Future<String> getDayInsight({
    required double calories,
    required double protein,
    required double fat,
    required double carbs,
    required int calGoal,
    required int proteinGoal,
  }) async {
    final prompt = '''Дай краткий совет по питанию за день. Данные:
Съедено: ${calories.round()} ккал (цель $calGoal)
Белок: ${protein.round()}г (цель ${proteinGoal}г)
Жиры: ${fat.round()}г  Углеводы: ${carbs.round()}г
Напиши 2-3 предложения на русском. Только текст, без заголовков.''';

    return await _chat(_textModel, [
          {'role': 'user', 'content': prompt}
        ], maxTokens: 200) ??
        '';
  }
}
