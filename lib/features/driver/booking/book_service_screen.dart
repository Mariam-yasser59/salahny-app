import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/app_widgets.dart';

class BookServiceScreen extends StatefulWidget {
  const BookServiceScreen({super.key});

  @override
  State<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends State<BookServiceScreen> {
  int _step = 0;
  String? _vehicleId, _workshopId, _date, _time;

  final _dates = [
    'Today',
    'Tomorrow',
    'Dec 21',
    'Dec 22',
    'Dec 23',
    'Dec 24',
  ];

  final _times = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  final _labels = [
    'Select Vehicle',
    'Choose Workshop',
    'Pick a Date',
    'Pick a Time',
  ];

  bool get _canNext =>
      [_vehicleId != null, _workshopId != null, _date != null, _time != null][_step];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'Book a Service'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            child: Row(
              children: List.generate(
                4,
                    (i) => Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: 250.ms,
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: i <= _step ? AC.redGrad : null,
                            color: i > _step ? AC.border : null,
                            borderRadius: Rd.fullA,
                            boxShadow: i <= _step
                                ? [
                              BoxShadow(
                                color: AC.red.withOpacity(0.4),
                                blurRadius: 8,
                              )
                            ]
                                : null,
                          ),
                        ),
                      ),
                      if (i < 3) const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _labels[_step],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AC.t1,
                  ),
                ),
                Text(
                  '${_step + 1}/4',
                  style: const TextStyle(fontSize: 13, color: AC.t3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: [
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      ...VehicleModel.mockList.map(
                            (v) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: VehicleCard(
                            make: v.make,
                            model: v.model,
                            year: v.year,
                            plate: v.plate,
                            health: v.health.toDouble(),
                            selected: _vehicleId == v.id,
                            onTap: () => setState(() => _vehicleId = v.id),
                          ),
                        ),
                      ),
                    ],
                  ),

                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      ...WorkshopModel.mockList.map(
                            (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _workshopId = w.id),
                            child: AnimatedContainer(
                              duration: 250.ms,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
                                ),
                                borderRadius: Rd.lgA,
                                border: Border.all(
                                  color: _workshopId == w.id ? AC.red : AC.border,
                                  width: _workshopId == w.id ? 1.5 : 0.8,
                                ),
                                boxShadow: _workshopId == w.id
                                    ? [
                                  BoxShadow(
                                    color: AC.red.withOpacity(0.2),
                                    blurRadius: 18,
                                  )
                                ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: AC.redGrad,
                                      borderRadius: Rd.mdA,
                                    ),
                                    child: const Icon(
                                      Icons.garage_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                w.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: AC.t1,
                                                ),
                                              ),
                                            ),
                                            if (w.isVerified)
                                              const GoldBadge('Verified'),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          w.specialty,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AC.t3,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            RatingStars(rating: w.rating),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${w.distance} mi away',
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
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _dates
                          .map(
                            (d) => GestureDetector(
                          onTap: () => setState(() => _date = d),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: _date == d ? AC.redGrad : null,
                              color: _date != d ? AC.s2 : null,
                              borderRadius: Rd.mdA,
                              border: Border.all(
                                color: _date == d ? AC.red : AC.border,
                              ),
                              boxShadow: _date == d
                                  ? [
                                BoxShadow(
                                  color: AC.red.withOpacity(0.3),
                                  blurRadius: 12,
                                )
                              ]
                                  : null,
                            ),
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _date == d ? Colors.white : AC.t2,
                              ),
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _times
                          .map(
                            (t) => GestureDetector(
                          onTap: () => setState(() => _time = t),
                          child: AnimatedContainer(
                            duration: 200.ms,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: _time == t ? AC.redGrad : null,
                              color: _time != t ? AC.s2 : null,
                              borderRadius: Rd.mdA,
                              border: Border.all(
                                color: _time == t ? AC.red : AC.border,
                              ),
                              boxShadow: _time == t
                                  ? [
                                BoxShadow(
                                  color: AC.red.withOpacity(0.3),
                                  blurRadius: 12,
                                )
                              ]
                                  : null,
                            ),
                            child: Text(
                              t,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _time == t ? Colors.white : AC.t2,
                              ),
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ][_step],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Row(
              children: [
                if (_step > 0) ...[
                  GestureDetector(
                    onTap: () => setState(() => _step--),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AC.s2,
                        borderRadius: Rd.mdA,
                        border: Border.all(color: AC.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AC.t2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _canNext ? 1 : 0.5,
                    duration: 200.ms,
                    child: AppBtn(
                      label: _step < 3 ? 'Next' : 'Confirm Booking',
                      onTap: _canNext
                          ? () {
                        if (_step < 3) {
                          setState(() => _step++);
                        } else {
                          Navigator.pushReplacementNamed(
                            context,
                            R.bookingConfirm,
                          );
                        }
                      }
                          : null,
                      icon: Icon(
                        _step < 3
                            ? Icons.arrow_forward_rounded
                            : Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
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