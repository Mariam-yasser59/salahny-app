import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class WorkshopDetailScreen extends StatelessWidget {
  const WorkshopDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final w = AppData.i.workshops;
    final ws = w[0];

    return Scaffold(
      backgroundColor: AC.bg,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AC.redDark, AC.red],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        const _BackBtn(),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: Rd.fullA,
                          ),
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: Rd.lgA,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AC.goldGrad,
                            borderRadius: Rd.lgA,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ws.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                ws.specialty,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  RatingStars(rating: ws.rating, size: 13),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${ws.rating} (${ws.reviews} reviews)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (ws.isVerified)
                          const GoldBadge(
                            'Verified',
                            icon: Icons.verified_rounded,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      StatTile(
                        label: 'Jobs Done',
                        value: '${ws.jobsDone}',
                        icon: Icons.build_rounded,
                        color: AC.success,
                      ),
                      const SizedBox(width: 12),
                      StatTile(
                        label: 'Reviews',
                        value: '${ws.reviews}',
                        icon: Icons.star_rounded,
                        color: AC.gold,
                      ),
                      const SizedBox(width: 12),
                      StatTile(
                        label: 'Distance',
                        value: '${ws.distance}',
                        icon: Icons.location_on_rounded,
                        color: AC.info,
                        unit: 'mi',
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  ACard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AC.t1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Div(),
                        const SizedBox(height: 14),
                        _CRow(Icons.location_on_rounded, ws.address),
                        const SizedBox(height: 10),
                        _CRow(Icons.phone_rounded, ws.phone),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  const SecHeader(title: 'Services Offered'),
                  const SizedBox(height: 12),

                  ...AppData.i.services.take(4).map(
                        (s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AC.s2,
                          borderRadius: Rd.mdA,
                          border: Border.all(color: AC.border),
                        ),
                        child: Row(
                          children: [
                            Text(
                              s.emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AC.t1,
                                    ),
                                  ),
                                  Text(
                                    '${s.durationMins} min',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AC.t3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${s.price.toInt()}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AC.gold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ),

                  const SizedBox(height: 20),
                  AppBtn(
                    label: 'Book at This Workshop',
                    onTap: () => Navigator.pushNamed(context, R.bookService),
                    icon: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn();

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        color: Colors.white,
        size: 18,
      ),
    ),
  );
}

class _CRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _CRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AC.t3),
      const SizedBox(width: 10),
      Text(
        text,
        style: const TextStyle(fontSize: 13, color: AC.t2),
      ),
    ],
  );
}