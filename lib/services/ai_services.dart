import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/database/database_helper.dart';

class AiService {
  static final AiService instance = AiService._();
  AiService._();

  // !! CHANGE THIS to your laptop's local WiFi IP !!
  // Mac/Linux: run `ifconfig | grep "inet "` in terminal
  // Windows:   run `ipconfig` → look for IPv4 Address
  static const _base = 'http://10.88.46.234:11434';
  static const _model = 'phi3:mini';

  // Instructions sent to the AI before every conversation
  static const _system = '''
You are Artha, a private personal finance assistant for an Indian user.
You ONLY know what the transaction data tells you. Never invent numbers.
Rules:
- Use ₹ for amounts. Be specific with actual numbers from the data.
- Keep answers under 120 words unless a detailed breakdown is needed.
- For affordability questions: look at income, current spend, and savings trend.
- If data is insufficient to answer, say so directly.
- Be honest. If spending is high, say so clearly but kindly.
''';

  Future<void> askStreaming(
    String question,
    void Function(String token) onToken, // called for each word
    void Function() onDone,              // called when finished
  ) async {
    // Build context from database — this is what the AI "sees"
    final context = await DatabaseHelper.instance.buildContext();
    final prompt = '$context\n\nUser Question: $question';

    try {
      final req = http.Request('POST', Uri.parse('$_base/api/generate'));
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode({
        'model': _model,
        'system': _system,
        'prompt': prompt,
        'stream': true, // get tokens as they generate, not all at once
        'options': {
          'temperature': 0.3, // lower = more factual, less creative
          'num_predict': 250  // max tokens to generate
        },
      });

      final client = http.Client();
      final res = await client.send(req)
          .timeout(const Duration(seconds: 15));

      // Process streaming response line by line
      await for (final chunk
          in res.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          if (line.trim().isEmpty) continue;
          try {
            final j = jsonDecode(line);
            final token = j['response'] as String? ?? '';
            if (token.isNotEmpty) onToken(token);
            if (j['done'] == true) {
              onDone();
              client.close();
              return;
            }
          } catch (_) {}
        }
      }
      onDone();
      client.close();
    } catch (e) {
      onToken(
          '⚠️ Could not reach Artha AI.\n\nMake sure:\n1. Ollama is running on your laptop\n2. Both devices are on same WiFi\n3. IP in ai_service.dart is correct');
      onDone();
    }
  }
}