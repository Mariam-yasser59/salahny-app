import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/services/mock_data.dart';
import '_admin_shared.dart';

class ActivityLogsScreen extends StatelessWidget {
  const ActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = MockData.activityLogs;

    return AdminShell(
      title: 'Activity Logs',
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemBuilder: (_, index) {
          final log = logs[index];
          return AdminSectionCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AC.info.withOpacity(0.12),
                    borderRadius: Rd.mdA,
                  ),
                  child: const Icon(
                    Icons.track_changes_rounded,
                    color: AC.info,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.actor} • ${log.action}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AC.t1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log.target,
                        style: const TextStyle(fontSize: 12, color: AC.gold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        log.details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AC.t3,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${log.timestamp.day}/${log.timestamp.month}',
                      style: const TextStyle(fontSize: 11, color: AC.t4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 11, color: AC.t4),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: logs.length,
      ),
    );
  }
}
