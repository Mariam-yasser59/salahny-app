import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/network/realtime_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';
import '../chat/services/chat_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AdminWorkshopChatScreen extends StatefulWidget {
  const AdminWorkshopChatScreen({
    super.key,
    this.workshopId,
    this.workshopName = 'Admin',
    this.workshopMode = false,
  });

  final String? workshopId;
  final String workshopName;
  final bool workshopMode;

  @override
  State<AdminWorkshopChatScreen> createState() =>
      _AdminWorkshopChatScreenState();
}

class _AdminWorkshopChatScreenState extends State<AdminWorkshopChatScreen> {
  final _chat = ChatService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  StreamSubscription<RealtimeEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.joinWorkshopAdmin(workshopId: widget.workshopId);
    _subscription = RealtimeService.instance.events.listen((event) {
      if (event.type != 'workshop_admin_message') return;
      final message = _chat.mapMessage(event.data);
      if (_messages.any((item) => item.id == message.id)) return;
      if (mounted) {
        setState(() => _messages = [..._messages, message]);
        _scrollToBottom();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final messages = await AppErrorHandler.guard<List<ChatMessage>>(
      context,
      () => widget.workshopMode
          ? _chat.getWorkshopAdminMessages()
          : _chat.getAdminWorkshopMessages(widget.workshopId ?? ''),
      fallbackMessage: 'Could not load messages right now.',
    );
    if (!mounted) return;
    setState(() {
      _messages = messages ?? const [];
      _loading = false;
    });
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final message = await AppErrorHandler.guard<ChatMessage>(
      context,
      () => widget.workshopMode
          ? _chat.sendWorkshopAdminMessage(text)
          : _chat.sendAdminWorkshopMessage(
              workshopId: widget.workshopId ?? '',
              text: text,
            ),
      fallbackMessage: 'Could not send this message.',
    );
    if (!mounted || message == null) return;
    setState(() => _messages = [..._messages, message]);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(80.ms, () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: 240.ms,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.workshopMode ? 'Message Admin' : widget.workshopName;
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: title),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AC.red))
                : _messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No messages yet.',
                        style: TextStyle(color: AC.t3, fontSize: 14),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) =>
                        _Bubble(message: _messages[index]),
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AC.s1,
              border: Border(top: BorderSide(color: AC.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: AC.t1, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: AC.t3, fontSize: 14),
                      filled: true,
                      fillColor: AC.s2,
                      border: OutlineInputBorder(
                        borderRadius: Rd.fullA,
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: Rd.fullA,
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: Rd.fullA,
                        borderSide: const BorderSide(color: AC.red),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: AC.redGrad,
                      borderRadius: Rd.fullA,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
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
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMe = message.isMe;
    final time =
        '${message.time.hour.toString().padLeft(2, '0')}:${message.time.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? AC.redGrad : null,
                color: isMe ? null : AC.s2,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: AC.border),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : AC.t1,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white54 : AC.t3,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
