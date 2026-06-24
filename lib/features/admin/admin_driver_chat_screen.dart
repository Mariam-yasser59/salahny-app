import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/errors/app_error_handler.dart';
import '../../core/network/api_client.dart';
import '../../core/network/realtime_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/app_widgets.dart';

class AdminDriverChatScreen extends StatefulWidget {
  const AdminDriverChatScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  final String driverId;
  final String driverName;

  @override
  State<AdminDriverChatScreen> createState() => _AdminDriverChatScreenState();
}

class _AdminDriverChatScreenState extends State<AdminDriverChatScreen> {
  final _client = ApiClient();
  final _ctrl = TextEditingController();
  List<ChatMessage> _items = const [];
  Timer? _timer;
  StreamSubscription<RealtimeEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    RealtimeService.instance.connect();
    _subscription = RealtimeService.instance.events.listen((event) {
      if (event.type != 'direct_message') return;
      final message = _map(event.data);
      if (_items.any((item) => item.id == message.id)) return;
      if (mounted) setState(() => _items = [..._items, message]);
    });
    _load();
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
    final response = await AppErrorHandler.guard<Map<String, dynamic>>(
      context,
      () async =>
          await _client.get('/admin/drivers/${widget.driverId}/messages')
              as Map<String, dynamic>,
    );
    if (!mounted || response == null) return;
    final items = (response['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    setState(() {
      _items = items
          .map(
            (item) => ChatMessage(
              id: item['id']?.toString() ?? '',
              text: item['text']?.toString() ?? '',
              senderId: item['senderId']?.toString() ?? '',
              time:
                  DateTime.tryParse(item['time']?.toString() ?? '') ??
                  DateTime.now(),
              isMe: item['isMe'] == true,
            ),
          )
          .toList();
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    await AppErrorHandler.guard<void>(context, () async {
      await _client.post('/admin/drivers/${widget.driverId}/messages', {
        'text': text,
      });
    });
    await _load();
  }

  ChatMessage _map(Map<String, dynamic> item) => ChatMessage(
    id: item['id']?.toString() ?? '',
    text: item['text']?.toString() ?? '',
    senderId: item['senderId']?.toString() ?? '',
    time: DateTime.tryParse(item['time']?.toString() ?? '') ?? DateTime.now(),
    isMe: item['isMe'] == true,
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: SAppBar(title: widget.driverName),
    body: Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (_, i) => ListTile(
              title: Text(_items[i].text, style: const TextStyle(color: AC.t1)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: AppField(label: '', hint: 'Message driver', ctrl: _ctrl),
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
