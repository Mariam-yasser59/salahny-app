import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/errors/app_error_handler.dart';
import '../../../core/network/realtime_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../chat/services/chat_service.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final _service = ChatService();
  final _ctrl = TextEditingController();
  List<ChatMessage> _messages = const [];
  Timer? _timer;
  StreamSubscription<RealtimeEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
    RealtimeService.instance.connect();
    _subscription = RealtimeService.instance.events.listen((event) {
      if (event.type != 'direct_message') return;
      final message = _service.mapMessage(event.data);
      if (_messages.any((item) => item.id == message.id)) return;
      if (mounted) setState(() => _messages = [..._messages, message]);
    });
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await AppErrorHandler.guard(
      context,
      _service.getDriverAdminMessages,
    );
    if (mounted && items != null) setState(() => _messages = items);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final item = await AppErrorHandler.guard(
      context,
      () => _service.sendDriverAdminMessage(text),
    );
    if (mounted && item != null)
      setState(() => _messages = [..._messages, item]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: const SAppBar(title: 'Chat with Admin'),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final item = _messages[i];
              return Align(
                alignment: item.isMe
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.isMe ? AC.red : AC.s2,
                    borderRadius: Rd.mdA,
                  ),
                  child: Text(
                    item.text,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: AppField(label: '', hint: 'Message admin', ctrl: _ctrl),
              ),
              IconButton(
                onPressed: _send,
                icon: const Icon(Icons.send, color: AC.red),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
