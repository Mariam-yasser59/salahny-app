import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/errors/app_error_handler.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/network/realtime_service.dart';
import '../diagnostics/services/diagnostics_service.dart';
import 'services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  final _diagnosticsService = DiagnosticsService();
  List<NotificationModel> _items = const [];
  bool _loading = true;
  StreamSubscription<RealtimeEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
    RealtimeService.instance.connect();
    _subscription = RealtimeService.instance.events.listen((event) {
      if (event.type != 'notification_created') return;
      final item = _notificationService.mapNotification(event.data);
      if (!mounted) return;
      setState(() => _items = [item, ..._items.where((n) => n.id != item.id)]);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final notifications = await AppErrorHandler.guard<List<NotificationModel>>(
      context,
      _notificationService.getNotifications,
      fallbackMessage: 'Could not load notifications right now.',
    );
    if (!mounted) return;
    setState(() {
      _items = notifications ?? const [];
      _loading = false;
    });
  }

  Future<void> _markRead(NotificationModel item) async {
    if (item.isRead) return;
    final ok = await AppErrorHandler.guard<bool>(context, () async {
      await _notificationService.markRead(item.id);
      return true;
    }, fallbackMessage: 'Could not update this notification.');
    if (!mounted || ok != true) return;
    setState(() {
      _items = _items
          .map(
            (entry) => entry.id == item.id
                ? NotificationModel(
                    id: entry.id,
                    title: entry.title,
                    body: entry.body,
                    type: entry.type,
                    time: entry.time,
                    isRead: true,
                    data: entry.data,
                  )
                : entry,
          )
          .toList(growable: false);
    });
  }

  Future<void> _markAllRead() async {
    if (!_items.any((item) => !item.isRead)) return;
    final ok = await AppErrorHandler.guard<bool>(context, () async {
      await _notificationService.markAllRead();
      return true;
    }, fallbackMessage: 'Could not mark notifications as read.');
    if (!mounted || ok != true) return;
    setState(() {
      _items = _items
          .map(
            (entry) => NotificationModel(
              id: entry.id,
              title: entry.title,
              body: entry.body,
              type: entry.type,
              time: entry.time,
              isRead: true,
              data: entry.data,
            ),
          )
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    appBar: SAppBar(
      title: 'Notifications',
      actions: [
        IconButton(
          tooltip: 'Mark all read',
          onPressed: _items.any((item) => !item.isRead) ? _markAllRead : null,
          icon: const Icon(Icons.done_all_rounded, color: AC.t1),
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: AC.red))
        : _items.isEmpty
        ? const Center(
            child: Text(
              'No notifications yet.',
              style: TextStyle(color: AC.t3, fontSize: 14),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final n = _items[i];
              final iconMap = {
                'booking': Icons.calendar_today_rounded,
                'reminder': Icons.notifications_active_outlined,
                'promo': Icons.local_offer_outlined,
                'chat': Icons.chat_bubble_outline_rounded,
                'diagnostic': Icons.analytics_outlined,
                'ai_report': Icons.car_repair_rounded,
                'system': Icons.notifications_outlined,
              };
              final colorMap = {
                'booking': AC.info,
                'reminder': AC.warning,
                'promo': AC.gold,
                'chat': AC.red,
                'diagnostic': AC.purple,
                'ai_report': AC.purple,
                'system': AC.info,
              };
              final col = colorMap[n.type] ?? AC.info;
              return GestureDetector(
                onTap: () async {
                  await _markRead(n);
                  await _openRelatedScreen(n);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.isRead ? AC.s2 : AC.red.withValues(alpha: 0.05),
                    borderRadius: Rd.lgA,
                    border: Border.all(
                      color: n.isRead
                          ? AC.border
                          : AC.red.withValues(alpha: 0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: col.withValues(alpha: 0.12),
                          borderRadius: Rd.mdA,
                        ),
                        child: Icon(
                          iconMap[n.type] ?? Icons.notifications_outlined,
                          color: col,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AC.t1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              n.body,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AC.t3,
                                height: 1.4,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AC.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ).animate().fadeIn(delay: (i * 80).ms),
              );
            },
          ),
  );

  Future<void> _openRelatedScreen(NotificationModel item) async {
    if (item.type == 'ai_report') {
      final reportId =
          item.data['reportId']?.toString() ??
          item.data['diagnosticId']?.toString() ??
          '';
      if (reportId.isEmpty) {
        Navigator.pushNamed(context, R.diagHistory);
        return;
      }
      final report = await AppErrorHandler.guard(
        context,
        () => _diagnosticsService.getAiReportById(reportId),
        fallbackMessage: 'Could not open this AI report right now.',
      );
      if (!mounted || report == null) return;
      Navigator.pushNamed(context, R.diagResult);
      return;
    }

    final bookingId = item.data['bookingId']?.toString() ?? '';
    final workshopId = item.data['workshopId']?.toString() ?? '';
    if (bookingId.isNotEmpty) {
      Navigator.pushNamed(context, R.bookingTrack, arguments: bookingId);
      return;
    }
    if (workshopId.isNotEmpty) {
      Navigator.pushNamed(context, R.workshopDetail, arguments: workshopId);
      return;
    }
    if (item.type == 'emergency') {
      Navigator.pushNamed(context, R.emergency);
      return;
    }
    if (item.type == 'chat') {
      Navigator.pushNamed(context, R.mechanicChat);
    }
  }
}
