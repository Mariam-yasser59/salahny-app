import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/mock_data.dart';
import '../../../shared/widgets/app_widgets.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _cats = [
    'All',
    'Maintenance',
    'Tires',
    'Inspection',
    'Cleaning',
    'Brakes',
    'HVAC',
    'Electrical'
  ];

  String _sel = 'All';

  List<ServiceModel> get _filtered =>
      _sel == 'All'
          ? AppData.i.services
          : AppData.i.services.where((s) => s.category == _sel).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'All Services', showBack: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => setState(() => _sel = _cats[i]),
                  child: AnimatedContainer(
                    duration: 250.ms,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: _sel == _cats[i] ? AC.redGrad : null,
                      color: _sel != _cats[i] ? AC.s2 : null,
                      borderRadius: Rd.fullA,
                      border: Border.all(
                        color: _sel == _cats[i] ? AC.red : AC.border,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      _cats[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _sel == _cats[i] ? Colors.white : AC.t3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.86,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final s = _filtered[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    R.bookService,
                    arguments: s.id,
                  ),
                  child: ACard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: AC.redGrad,
                                borderRadius: Rd.mdA,
                              ),
                              child: Center(
                                child: Text(
                                  s.emoji,
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            if (s.isPopular) const GoldBadge('Hot'),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AC.t1,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          s.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AC.t3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${s.price.toInt()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AC.gold,
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}