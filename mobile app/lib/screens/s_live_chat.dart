import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../widgets/common.dart';

/// Live chat screen with a mock chat interface.
class LiveChatScreen extends StatefulWidget {
  const LiveChatScreen({super.key});

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  const _ChatMessage(this.text, {required this.isUser, required this.time});
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      'Hi there! Welcome to RESIVYN support. How can I help you today?',
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text, isUser: true, time: DateTime.now()));
    });
    _controller.clear();
    _scrollToBottom();

    // Simulate agent typing then reply
    Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          _autoReply(text),
          isUser: false,
          time: DateTime.now(),
        ));
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _autoReply(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (lower.contains('hello') || lower.contains('hi')) {
      return 'Hello! How can I assist you with your RESIVYN account?';
    }
    if (lower.contains('property') || lower.contains('listing')) {
      return 'I can help with property inquiries. Are you looking to buy, rent, or sell?';
    }
    if (lower.contains('payment') || lower.contains('rent')) {
      return 'For payment or rent queries, I can connect you with our billing team. Could you share more details?';
    }
    if (lower.contains('maintenance') || lower.contains('repair')) {
      return 'I can help you log a maintenance request. Which property is this regarding?';
    }
    if (lower.contains('thank')) {
      return "You're welcome! Is there anything else I can help with?";
    }
    return 'Thanks for your message! Let me look into that for you. Could you provide a bit more detail?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: RC.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, matchTextDirection: true,
              size: 18, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: RC.teal,
              child: Icon(Icons.support_agent_rounded,
                  size: 18, color: Colors.white),
            ),
            SizedBox(width: RS.x10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('resivyn_support'.tr(),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  SizedBox(height: 1),
                  Text('online_reply_minutes'.tr(),
                      style: TextStyle(
                          color: Colors.white70, fontSize: 10.5)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded,
                size: 20, color: Colors.white70),
            onPressed: () {
              toast(context, 'Chat options', icon: Icons.more_vert_rounded);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Messages ----
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(RS.x16, RS.x16, RS.x16, RS.x8),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return _MessageBubble(message: msg);
              },
            ),
          ),

          // ---- Input bar ----
          Container(
            padding: EdgeInsets.fromLTRB(
              RS.x12,
              RS.x8,
              RS.x12,
              RS.x8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              color: RC.surface,
              border: Border(top: BorderSide(color: RC.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: RR.inner,
                      border: Border.all(color: RC.border),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: RT.bodyStrong,
                      cursorColor: RC.teal,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: RT.body.copyWith(color: RC.textTertiary),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: RS.x14,
                          vertical: RS.x12,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: RS.x8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: RC.teal,
                      borderRadius: RR.button,
                      boxShadow: RShadow.teal,
                    ),
                    child: const Icon(Icons.send_rounded,
                        size: 20, color: Colors.white),
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

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeStr =
        '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: RS.x10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: RC.teal,
              child:
                  Icon(Icons.support_agent_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: RS.x8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(RS.x14, RS.x10, RS.x14, RS.x8),
              decoration: BoxDecoration(
                color: isUser ? RC.teal : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: RShadow.soft,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: RT.body.copyWith(
                      color: isUser ? Colors.white : RC.navy,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: RS.x4),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white60 : RC.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: RS.x8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: RC.navy,
              child: Icon(Icons.person_rounded, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
