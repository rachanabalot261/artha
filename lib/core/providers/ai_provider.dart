import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String text;
  final bool isUser;  // true = right side bubble, false = Artha bubble
  final DateTime time;
  const ChatMessage(
      {required this.text,
      required this.isUser,
      required this.time});
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier()
      : super([
          // Welcome message shown on first open
          ChatMessage(
            text:
                "Namaste! I'm Artha — your private finance assistant.\n\nEverything stays on your phone. Ask me anything:\n• Where did I spend the most?\n• Can I afford ₹15,000 this week?\n• How was last month vs this month?",
            isUser: false,
            time: DateTime.now(),
          )
        ]);

  void add(ChatMessage m) => state = [...state, m];

  // Updates the last message — used for streaming AI response
  // As each token arrives we update the last bubble instead of adding a new one
  void updateLast(String text) {
    if (state.isEmpty) return;
    final updated = [...state];
    updated[updated.length - 1] =
        ChatMessage(text: text, isUser: false, time: DateTime.now());
    state = updated;
  }

  void clear() => state = [];
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
        (_) => ChatNotifier());

// True while AI is generating a response — disables the send button
final isThinkingProvider = StateProvider<bool>((_) => false);