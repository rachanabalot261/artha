import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_services.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  static const _suggestions = [
    'Where did I spend the most?',
    'Can I afford ₹10,000 this week?',
    'How is this month vs last?',
    'What are my subscriptions?',
    'Am I saving enough?',
    'Top 3 expenses this month?',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    text = text.trim();
    if (text.isEmpty || ref.read(isThinkingProvider)) return;
    _ctrl.clear();

    // Add user message
    ref.read(chatProvider.notifier).add(
        ChatMessage(text: text, isUser: true, time: DateTime.now()));
    ref.read(isThinkingProvider.notifier).state = true;

    // Add placeholder AI message (shows "…" while loading)
    ref.read(chatProvider.notifier).add(
        ChatMessage(text: '…', isUser: false, time: DateTime.now()));
    _scrollDown();

    // Stream tokens into the placeholder message
    String streamed = '';
    await AiService.instance.askStreaming(
      text,
      (token) {
        streamed += token;
        ref.read(chatProvider.notifier).updateLast(streamed);
        _scrollDown();
      },
      () {
        ref.read(isThinkingProvider.notifier).state = false;
        _scrollDown();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(chatProvider);
    final thinking = ref.watch(isThinkingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C6FCD), Color(0xFF5A4FB0)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('₹',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ask Artha',
                    style: TextStyle(fontSize: 16)),
                Text('Private • On-device',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined, size: 20),
            onPressed: () =>
                ref.read(chatProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Message bubbles
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: msgs.length,
              itemBuilder: (_, i) => _Bubble(msg: msgs[i]),
            ),
          ),

          // Quick suggestion chips — shown only at start
          if (msgs.length <= 2 && !thinking)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 8),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(_suggestions[i],
                      style: const TextStyle(fontSize: 12)),
                  onPressed: () => _send(_suggestions[i]),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                  top: BorderSide(
                      color: AppColors.card, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    onSubmitted: _send,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your finances...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: thinking
                        ? AppColors.purple.withValues(alpha: 0.5)
                        : AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: thinking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                    onPressed: thinking
                        ? null
                        : () => _send(_ctrl.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C6FCD),
                    Color(0xFF5A4FB0)
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('₹',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.purple
                    : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft:
                      Radius.circular(isUser ? 16 : 4),
                  bottomRight:
                      Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Text(msg.text,
                  style: const TextStyle(
                      fontSize: 14, height: 1.45)),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.card,
              child: Icon(Icons.person_outline,
                  size: 15, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}