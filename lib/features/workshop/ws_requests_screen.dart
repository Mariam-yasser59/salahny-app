// lib/features/workshop/ws_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '_ws_shared.dart';
import 'ws_req_detail_screen.dart';
import '../../core/theme/app_theme.dart';

class WsRequestsScreen extends StatefulWidget {
  const WsRequestsScreen({super.key});
  @override
  State<WsRequestsScreen> createState() => _WsRequestsScreenState();
}

class _WsRequestsScreenState extends State<WsRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pending  = AppData.i.workshopBookings.where((b) => b.status == RequestStatus.pending).toList();
    final accepted = AppData.i.workshopBookings.where((b) => b.status == RequestStatus.accepted).toList();
    final done     = AppData.i.workshopBookings.where((b) => b.status == RequestStatus.completed).toList();

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: WsBar(
        title: 'Requests',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AC.red.withOpacity(0.12),
                borderRadius: Rd.fullA,
                border: Border.all(color: AC.red.withOpacity(0.35)),
              ),
              child: Text('${pending.length} new',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AC.red)),
            )),
          ),
        ],
      ),
      body: Column(children: [
        // ── Tab selector ───────────────────────────────────────────────────
        Container(
          color: AC.s1,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: AC.bg, borderRadius: Rd.mdA),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(gradient: AC.redGrad, borderRadius: Rd.mdA,
                  boxShadow: [BoxShadow(color: AC.red.withOpacity(0.35), blurRadius: 8)]),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AC.t3,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'Pending (${pending.length})'),
                Tab(text: 'Accepted (${accepted.length})'),
                Tab(text: 'Done (${done.length})'),
              ],
            ),
          ),
        ),
        // ── Tab views ─────────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _BookingList(bookings: pending,  emptyMsg: 'No pending requests', showActions: true),
              _BookingList(bookings: accepted, emptyMsg: 'No accepted requests', showActions: false),
              _BookingList(bookings: done,     emptyMsg: 'No completed requests', showActions: false),
            ],
          ),
        ),
      ]),
    );
  }
}

class _BookingList extends StatelessWidget {
  final List<WsBookingData> bookings;
  final String emptyMsg;
  final bool showActions;
  const _BookingList({required this.bookings, required this.emptyMsg, required this.showActions});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AC.s2, borderRadius: Rd.lgA, border: Border.all(color: AC.border)),
          child: const Icon(Icons.inbox_outlined, size: 32, color: AC.t3),
        ),
        const SizedBox(height: 14),
        Text(emptyMsg, style: const TextStyle(fontSize: 14, color: AC.t3)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ReqCard(booking: bookings[i], showActions: showActions)
          .animate()
          .fadeIn(duration: 300.ms, delay: (i * 50).ms),
    );
  }
}

class _ReqCard extends StatelessWidget {
  final WsBookingData booking;
  final bool showActions;
  const _ReqCard({required this.booking, required this.showActions});

  @override
  Widget build(BuildContext context) => WsCard(
    padding: const EdgeInsets.all(16),
    onTap: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => WsReqDetailScreen(booking: booking))),
    child: Column(children: [
      Row(children: [
        const WsIconBox(Icons.person_rounded, size: 44),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.serviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AC.t1)),
          const SizedBox(height: 3),
          Text('${booking.customerName} • ${booking.time}',
              style: const TextStyle(fontSize: 12, color: AC.t3)),
        ])),
        WsChip(booking.status),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        const Icon(Icons.directions_car_rounded, size: 13, color: AC.t3),
        const SizedBox(width: 4),
        Expanded(child: Text(booking.vehicleInfo, style: const TextStyle(fontSize: 12, color: AC.t3))),
        Text('\$${booking.price.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AC.gold)),
      ]),
      if (showActions) ...[
        const SizedBox(height: 12),
        const WsDiv(),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: WsBtn(label: 'Accept',  small: true, gold: true,    onTap: () {})),
          const SizedBox(width: 10),
          Expanded(child: WsBtn(label: 'Decline', small: true, outline: true, onTap: () {})),
        ]),
      ],
    ]),
  );
}