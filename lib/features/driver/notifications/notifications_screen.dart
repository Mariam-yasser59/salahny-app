import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/errors/app_error_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_widgets.dart';
import 'services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  List<NotificationModel> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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
    final ok = await AppErrorHandler.guard<bool>(
      context,
      () async {
        await _notificationService.markRead(item.id);
        return true;
      },
      fallbackMessage: 'Could not update this notification.',
    );
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
                  )
                : entry,
          )
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AC.bg,
        appBar: SAppBar(title: 'Notifications'),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AC.red))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
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
                    'system': Icons.notifications_outlined,
                  };
                  final colorMap = {
                    'booking': AC.info,
                    'reminder': AC.warning,
                    'promo': AC.gold,
                    'chat': AC.red,
                    'diagnostic': AC.purple,
                    'system': AC.info,
                  };
                  final col = colorMap[n.type] ?? AC.info;
                  return GestureDetector(
                    onTap: () => _markRead(n),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: n.isRead ? AC.s2 : AC.red.withOpacity(0.05),
                        borderRadius: Rd.lgA,
                        border: Border.all(
                          color: n.isRead
                              ? AC.border
                              : AC.red.withOpacity(0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: col.withOpacity(0.12),
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
}
