// lib/features/workshop/ws_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/models.dart';

class WsChatScreen extends StatefulWidget {
  final String bookingId, customerName;
  const WsChatScreen({super.key, required this.bookingId, required this.customerName});
  @override
  State<WsChatScreen> createState() => _WsChatScreenState();
}

class _WsChatScreenState extends State<WsChatScreen> {
  final _ctrl   = TextEditingController();
  final _scroll = ScrollController();

  late final WsBookingData _booking;
  late final List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _booking = AppData.i.workshopBookings.firstWhere(
      (b) => b.id == widget.bookingId,
      orElse: () => AppData.i.workshopBookings.first,
    );
    _messages = [
      ChatMessage(id: 'm1', text: 'Hello! I booked ${_booking.serviceName} for ${_booking.date} at ${_booking.time}. Just wanted to confirm it is all good.', senderId: 'driver', time: DateTime.now().subtract(const Duration(minutes: 22)), isMe: false),
      ChatMessage(id: 'm2', text: 'Hi ${_booking.customerName.split(' ').first}! Yes, everything is confirmed. Please bring ${_booking.vehicleInfo} in 15 mins early for check-in.', senderId: 'ws', time: DateTime.now().subtract(const Duration(minutes: 20)), isMe: true),
    ];
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(id: 'm${_messages.length + 1}', text: text, senderId: 'ws', time: DateTime.now(), isMe: true));
      _ctrl.clear();
    });
    Future.delayed(100.ms, () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: 300.ms, curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose(); _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: WsBar(
      title: widget.customerName,
      showBack: true,
      actions: [
        Container(
          width: 36, height: 36,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(color: AC.success.withOpacity(0.12), borderRadius: Rd.fullA, border: Border.all(color: AC.success.withOpacity(0.35))),
          child: const Icon(Icons.call_rounded, color: AC.success, size: 18),
        ),
      ],
    ),
    body: Column(children: [
      // â”€â”€ Context Banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(color: AC.s1, border: Border(bottom: BorderSide(color: AC.border, width: 0.5))),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.smA),
            child: const Icon(Icons.build_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Request #${_booking.id} • ${_booking.serviceName}',
            style: const TextStyle(fontSize: 12, color: AC.t3),
            overflow: TextOverflow.ellipsis,
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AC.warning.withOpacity(0.12), borderRadius: Rd.fullA, border: Border.all(color: AC.warning.withOpacity(0.3))),
            child: Text(RequestStatus.label(_booking.status), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AC.warning)),
          ),
        ]),
      ),

      // â”€â”€ Messages â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      Expanded(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          itemCount: _messages.length,
          itemBuilder: (_, i) => _Bubble(msg: _messages[i])
              .animate().fadeIn(duration: 300.ms, delay: (i * 40).ms),
        ),
      ),

      // â”€â”€ Input Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: AC.s1,
          border: Border(top: BorderSide(color: AC.border, width: 0.5)),
        ),
        child: Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: AC.s2, borderRadius: Rd.fullA, border: Border.all(color: AC.border)),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(fontSize: 14, color: AC.t1),
                decoration: const InputDecoration(
                  hintText: 'Type a messageâ€¦',
                  hintStyle: TextStyle(color: AC.t3, fontSize: 14),
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.fullA,
                  boxShadow: [BoxShadow(color: AC.red.withOpacity(0.4), blurRadius: 14)]),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]),
  );
}

// â”€â”€â”€ BUBBLE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;
    final time = '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: AC.s3, borderRadius: Rd.fullA),
              child: const Icon(Icons.person_rounded, size: 16, color: AC.t2),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? AC.redGrad : null,
                color: isMe ? null : AC.s2,
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(18),
                  topRight:    const Radius.circular(18),
                  bottomLeft:  Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4  : 18),
                ),
                boxShadow: isMe ? [BoxShadow(color: AC.red.withOpacity(0.25), blurRadius: 12)] : null,
                border: isMe ? null : Border.all(color: AC.border),
              ),
              child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                Text(msg.text, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AC.t1, height: 1.4)),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 10, color: isMe ? Colors.white54 : AC.t3)),
              ]),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.fullA),
              child: const Icon(Icons.car_repair_rounded, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}
