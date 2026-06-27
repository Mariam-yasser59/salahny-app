// lib/features/workshop/ws_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';
import 'ws_earnings_screen.dart';
import 'ws_emergency_screen.dart';
import '_ws_shared.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/services/app_cache.dart';
import '../../shared/services/location_service.dart';
import '../../shared/widgets/salahny_map.dart';
import 'services/workshop_portal_service.dart';

class WsProfileScreen extends StatefulWidget {
  const WsProfileScreen({super.key});

  @override
  State<WsProfileScreen> createState() => _WsProfileScreenState();
}

class _WsProfileScreenState extends State<WsProfileScreen> {
  final _service = WorkshopPortalService();
  final _locationService = const LocationService();
  bool _savingLocation = false;

  @override
  void initState() {
    super.initState();
    _service
        .syncDashboard()
        .then((_) {
          if (mounted) setState(() {});
        })
        .catchError((_) {});
  }

  Future<void> _editLocation() async {
    final profile = AppCache.workshopProfile;
    if (profile.id.isEmpty) return;
    final addressCtrl = TextEditingController(text: profile.address);
    LatLng selected = LatLng(
      profile.latitude ?? 30.0444,
      profile.longitude ?? 31.2357,
    );
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AC.s1,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Workshop Location',
                style: TextStyle(
                  color: AC.t1,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(color: AC.t1),
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Street, district, landmark — editable like Uber',
                ),
                onSubmitted: (_) async {
                  final point = await _locationService.geocodeAddress(
                    addressCtrl.text.trim(),
                  );
                  if (point == null) return;
                  setSheetState(() => selected = point);
                },
              ),
              const SizedBox(height: 12),
              WsBtn(
                label: 'Search Typed Address',
                outline: true,
                icon: Icons.search_rounded,
                onTap: () async {
                  final point = await _locationService.geocodeAddress(
                    addressCtrl.text.trim(),
                  );
                  if (point == null) return;
                  setSheetState(() => selected = point);
                },
              ),
              const SizedBox(height: 12),
              SalahnyMap(
                height: 220,
                currentLocation: selected,
                markers: [
                  SalahnyMapMarker(
                    id: 'workshop',
                    latitude: selected.latitude,
                    longitude: selected.longitude,
                    title: profile.name,
                    snippet: addressCtrl.text,
                  ),
                ],
                onTap: (point) {
                  setSheetState(() => selected = point);
                  _locationService
                      .reverseGeocode(point.latitude, point.longitude)
                      .then((address) {
                        if (address == null) return;
                        setSheetState(() => addressCtrl.text = address);
                      });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: WsBtn(
                      label: 'Use Current Location',
                      outline: true,
                      icon: Icons.my_location_rounded,
                      onTap: () async {
                        final result = await _locationService.currentPosition(
                          withAddress: true,
                        );
                        if (!result.hasLocation) return;
                        setSheetState(() {
                          selected = LatLng(
                            result.position!.latitude,
                            result.position!.longitude,
                          );
                          if ((result.address ?? '').isNotEmpty) {
                            addressCtrl.text = result.address!;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WsBtn(
                      label: 'Save',
                      icon: Icons.save_rounded,
                      onTap: () async {
                        if (addressCtrl.text.trim().isEmpty) return;
                        setState(() => _savingLocation = true);
                        await _service.updateProfileLocation(
                          workshopId: profile.id,
                          address: addressCtrl.text.trim(),
                          latitude: selected.latitude,
                          longitude: selected.longitude,
                        );
                        if (context.mounted) Navigator.pop(context, true);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    addressCtrl.dispose();
    if (!mounted) return;
    setState(() => _savingLocation = false);
    if (saved == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppData.i.workshopProfile;
    final services = AppData.i.workshopServices;

    return Scaffold(
      backgroundColor: AC.bg,
      appBar: const WsBar(title: 'Workshop Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
        children: [
          // ── Identity Card ─────────────────────────────────────────────────
          WsCard(
            glowColor: AC.red,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: AC.redGrad,
                        borderRadius: Rd.lgA,
                      ),
                      child: Center(
                        child: Text(
                          profile.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AC.t1,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.specialty,
                            style: const TextStyle(fontSize: 12, color: AC.t3),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: profile.isVerified ? AC.goldGrad : null,
                              color: profile.isVerified ? null : AC.s3,
                              borderRadius: Rd.fullA,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  profile.isVerified
                                      ? Icons.verified_rounded
                                      : Icons.schedule_rounded,
                                  color: profile.isVerified
                                      ? const Color(0xFF1A0A00)
                                      : AC.t2,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  profile.isVerified
                                      ? 'Verified Partner'
                                      : profile.accountStatus,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: profile.isVerified
                                        ? const Color(0xFF1A0A00)
                                        : AC.t2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const WsDiv(),
                const SizedBox(height: 14),
                WsInfoRow(label: 'Status', value: profile.accountStatus),
                const SizedBox(height: 8),
                WsInfoRow(
                  label: 'Address',
                  value: profile.address.isEmpty
                      ? 'No address saved'
                      : profile.address,
                ),
                const SizedBox(height: 8),
                WsInfoRow(
                  label: 'Rating',
                  value: profile.rating.toStringAsFixed(1),
                  bold: true,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms),

          const SizedBox(height: 18),

          // ── Performance Stats ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  '${profile.completedServices}',
                  'Completed',
                  Icons.done_all_rounded,
                  AC.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  '${profile.reviewCount}',
                  'Reviews',
                  Icons.star_rounded,
                  AC.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  '8 min',
                  'Avg Response',
                  Icons.speed_rounded,
                  AC.warning,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms, delay: 80.ms),

          const SizedBox(height: 24),

          const _SecLabel('Location'),
          const SizedBox(height: 12),
          WsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SalahnyMap(
                  height: 180,
                  currentLocation:
                      profile.latitude != null && profile.longitude != null
                      ? LatLng(profile.latitude!, profile.longitude!)
                      : null,
                  markers: profile.latitude != null && profile.longitude != null
                      ? [
                          SalahnyMapMarker(
                            id: profile.id,
                            latitude: profile.latitude!,
                            longitude: profile.longitude!,
                            title: profile.name,
                            snippet: profile.address,
                          ),
                        ]
                      : const [],
                ),
                const SizedBox(height: 12),
                WsBtn(
                  label: _savingLocation ? 'Saving...' : 'Update Location',
                  outline: true,
                  icon: Icons.map_rounded,
                  onTap: _savingLocation ? () {} : _editLocation,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Services ──────────────────────────────────────────────────────
          const _SecLabel('Services Offered'),
          const SizedBox(height: 12),
          WsCard(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: services.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No services added yet.',
                      style: TextStyle(fontSize: 12, color: AC.t3),
                    ),
                  )
                : Column(
                    children: services.asMap().entries.map((e) {
                      final s = e.value;
                      final last = e.key == services.length - 1;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  s.emoji,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontSize: 13,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AC.gold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!last)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: WsDiv(),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
          ).animate().fadeIn(duration: 350.ms, delay: 140.ms),

          const SizedBox(height: 22),

          // ── Quick Action Tiles ────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  Icons.payments_rounded,
                  'Earnings',
                  AC.gold,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WsEarningsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  Icons.emergency_share_rounded,
                  'Emergency',
                  AC.warning,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WsEmergencyScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  Icons.admin_panel_settings_rounded,
                  'Admin',
                  AC.info,
                  () => Navigator.pushNamed(context, R.wsAdminChat),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 350.ms, delay: 200.ms),

          const SizedBox(height: 24),

          // ── Actions ───────────────────────────────────────────────────────
          WsBtn(
            label: 'Edit Profile',
            outline: true,
            icon: Icons.edit_rounded,
            onTap: _editLocation,
          ).animate().fadeIn(duration: 350.ms, delay: 260.ms),
          const SizedBox(height: 12),
          WsBtn(
            label: 'Manage Availability',
            outline: true,
            icon: Icons.schedule_rounded,
            onTap: () => Navigator.pushNamed(context, R.wsSchedule),
          ),
          const SizedBox(height: 12),
          WsBtn(
            label: 'Verification Documents',
            outline: true,
            icon: Icons.verified_user_rounded,
            onTap: () => Navigator.pushNamed(context, R.documents),
          ),
          const SizedBox(height: 12),
          WsBtn(
            label: 'Sign Out',
            outline: true,
            icon: Icons.logout_rounded,
            onTap: () async {
              await AppCache.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  R.roleSelect,
                  (_) => false,
                );
              }
            },
          ).animate().fadeIn(duration: 350.ms, delay: 300.ms),
        ],
      ),
    );
  }
}

class _SecLabel extends StatelessWidget {
  final String t;
  const _SecLabel(this.t);
  @override
  Widget build(BuildContext context) => Text(
    t,
    style: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AC.t1,
      letterSpacing: -0.2,
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _MiniStat(this.value, this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: Rd.lgA,
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AC.t3),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: Rd.lgA,
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}
