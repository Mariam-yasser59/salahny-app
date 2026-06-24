import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/errors/app_error_handler.dart';
import '../../../core/network/realtime_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/app_cache.dart';
import '../../chat/services/chat_service.dart';

class MechanicChatScreen extends StatefulWidget {
  final String? bookingId;

  const MechanicChatScreen({super.key, this.bookingId});

  @override
  State<MechanicChatScreen> createState() => _MechanicChatScreenState();
}

class _MechanicChatScreenState extends State<MechanicChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _chatService = ChatService();
  StreamSubscription<RealtimeEvent>? _subscription;
  Timer? _refreshTimer;
  List<ChatMessage> _messages = const [];
  bool _loading = true;
  String _peerPhone = '';
  String _peerName = '';

  BookingModel? get _bookingOrNull {
    final bookings = AppData.i.bookings;
    if (bookings.isEmpty) return null;
    final matches = bookings.where((item) => item.id == widget.bookingId);
    return matches.isNotEmpty ? matches.first : bookings.first;
  }

  @override
  void initState() {
    super.initState();
    final booking = _bookingOrNull;
    if (booking == null) {
      _loading = false;
      return;
    }
    RealtimeService.instance.joinBooking(booking.id);
    _subscription = RealtimeService.instance.events.listen((event) {
      if (event.type != 'booking_message') return;
      final message = _chatService.mapMessage(event.data);
      if (_messages.any((item) => item.id == message.id)) return;
      if (mounted) {
        setState(() => _messages = [..._messages, message]);
        _scrollDown();
      }
    });
    _loadContext();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) => _load());
  }

  Future<void> _loadContext() async {
    final booking = _bookingOrNull;
    if (booking == null) return;
    final contextData = await AppErrorHandler.guard<BookingChatContext>(
      context,
      () => _chatService.getBookingContext(booking.id),
      fallbackMessage: 'Could not load contact details.',
    );
    if (!mounted || contextData == null) return;
    setState(() {
      _peerPhone = contextData.peerPhone;
      _peerName = contextData.peerName;
    });
  }

  Future<void> _load() async {
    final booking = _bookingOrNull;
    if (booking == null) return;
    final messages = await AppErrorHandler.guard<List<ChatMessage>>(
      context,
      () => _chatService.getBookingMessages(booking.id),
      fallbackMessage: 'Could not load workshop chat right now.',
    );
    if (!mounted) return;
    setState(() {
      _messages = messages ?? const [];
      _loading = false;
    });
    _scrollDown();
  }

  Future<void> _send() async {
    final booking = _bookingOrNull;
    if (booking == null) return;
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    final message = await AppErrorHandler.guard<ChatMessage>(
      context,
      () => _chatService.sendBookingMessage(booking.id, text),
      fallbackMessage: 'Could not send your message.',
    );
    if (!mounted || message == null) return;
    setState(() => _messages = [..._messages, message]);
    _scrollDown();
  }

  Future<void> _callPeer() async {
    final phone = _peerPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.length < 7) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available.')),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await canLaunchUrl(uri)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This device cannot start phone calls.')),
      );
      return;
    }
    await launchUrl(uri);
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _subscription?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _bookingOrNull;
    if (booking == null) {
      return const Scaffold(
        backgroundColor: AC.bg,
        body: Center(
          child: Text(
            'No booking chat is available.',
            style: TextStyle(color: AC.t3),
          ),
        ),
      );
    }
    final workshopInitial = booking.workshopName.isEmpty
        ? '?'
        : booking.workshopName[0];
    final displayName = _peerName.isNotEmpty ? _peerName : booking.workshopName;
    return Scaffold(
      backgroundColor: AC.bg,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 14,
              left: 16,
              right: 16,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AC.border, width: 0.5)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AC.s2,
                      borderRadius: Rd.mdA,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AC.t1,
                      size: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    gradient: AC.redGrad,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      workshopInitial,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AC.t1,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AC.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Live booking chat',
                            style: TextStyle(fontSize: 11, color: AC.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _callPeer,
                  icon: const Icon(Icons.call_rounded, color: AC.red, size: 24),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AC.red))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final message = _messages[i];
                      return _B(message.text, message.isMe);
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AC.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AC.t1,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(
                        color: AC.t4,
                        fontFamily: 'Poppins',
                      ),
                      filled: true,
                      fillColor: AC.s2,
                      border: OutlineInputBorder(
                        borderRadius: Rd.fullA,
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
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
                    decoration: const BoxDecoration(
                      gradient: AC.redGrad,
                      shape: BoxShape.circle,
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

class _B extends StatelessWidget {
  final String text;
  final bool isMe;

  const _B(this.text, this.isMe);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              gradient: isMe ? AC.redGrad : null,
              color: isMe ? null : AC.s2,
              borderRadius: Rd.lgA,
              border: isMe ? null : Border.all(color: AC.border, width: 0.8),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AC.t1,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
