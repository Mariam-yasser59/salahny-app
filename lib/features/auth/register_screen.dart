import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/errors/app_error_handler.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../documents/services/document_service.dart';
import '../workshops/services/workshop_service.dart';
import 'services/auth_service.dart';
import '../../shared/services/app_cache.dart';
import '../../shared/services/location_service.dart';
import '../../shared/widgets/app_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fk = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _workshopName = TextEditingController();
  final _workshopLocation = TextEditingController();
  final _auth = AuthService();
  final _documents = DocumentService();
  final _workshops = WorkshopService();
  final _locationService = const LocationService();
  bool _loading = false;
  String _role = 'driver';
  PlatformFile? _verificationFile;
  String? _validateName(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Enter your name';
    if (value.length < 2) return 'Name is too short';
    return null;
  }

  String? _validateEmail(String? v) {
    final value = v?.trim() ?? '';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    if (value.isEmpty) return 'Enter email';
    if (!ok) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Enter phone';
    if (digits.length != 11) return 'Phone must be 11 numbers';
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Add one uppercase letter';
    if (!RegExp(r'\d').hasMatch(value)) return 'Add one number';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AppCache.getRole();
    if (mounted) setState(() => _role = role ?? 'driver');
  }

  Future<void> _pickVerificationFile() async {
    final picked = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg'],
    );
    final file = picked?.files.isEmpty == true ? null : picked?.files.first;
    if (file != null && mounted) {
      setState(() => _verificationFile = file);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pass.dispose();
    _workshopName.dispose();
    _workshopLocation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AC.bg,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _fk,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AC.s2,
                    borderRadius: Rd.mdA,
                    border: Border.all(color: AC.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AC.t1,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AC.t1,
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              const Text(
                'Join 50,000+ satisfied drivers',
                style: TextStyle(fontSize: 14, color: AC.t3),
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 36),
              ...[
                AppField(
                  label: 'Full Name',
                  hint: 'John Smith',
                  ctrl: _name,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),
                AppField(
                  label: 'Email Address',
                  hint: 'you@example.com',
                  ctrl: _email,
                  keyboard: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                AppField(
                  label: 'Phone Number',
                  hint: '01012345678',
                  ctrl: _phone,
                  keyboard: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                AppField(
                  label: 'Password',
                  hint: 'At least 8 characters',
                  ctrl: _pass,
                  obscure: true,
                  validator: _validatePassword,
                ),
                if (_role == 'workshop') ...[
                  const SizedBox(height: 16),
                  AppField(
                    label: 'Workshop Name',
                    hint: 'Salahny Auto Center',
                    ctrl: _workshopName,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter workshop name'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  AppField(
                    label: 'Workshop Address',
                    hint: 'Street, district, city',
                    ctrl: _workshopLocation,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter workshop address'
                        : null,
                  ),
                ],
              ].asMap().entries.map(
                    (e) => e.value.runtimeType == SizedBox
                    ? e.value
                    : e.value
                    .animate()
                    .fadeIn(delay: (200 + e.key * 50).ms)
                    .slideY(begin: 0.2, end: 0),
              ),
              const SizedBox(height: 16),
              _VerificationPicker(
                role: _role,
                fileName: _verificationFile?.name,
                onTap: _pickVerificationFile,
              ),
              const SizedBox(height: 32),
              AppBtn(
                label: 'Create Account',
                loading: _loading,
                onTap: () async {
                  if (!_fk.currentState!.validate()) return;
                  if (_verificationFile == null) {
                    AppErrorHandler.showMessage(
                      context,
                      _role == 'workshop'
                          ? 'Upload a workshop permit before creating the account.'
                          : 'Upload your driver license before creating the account.',
                    );
                    return;
                  }
                  final workshopPoint = _role == 'workshop'
                      ? await _locationService.geocodeAddress(
                    _workshopLocation.text.trim(),
                  )
                      : null;
                  if (!mounted) return;
                  if (_role == 'workshop' && workshopPoint == null) {
                    AppErrorHandler.showMessage(
                      context,
                      'Could not find that workshop address. Add city and country, then try again.',
                    );
                    return;
                  }
                  setState(() => _loading = true);
                  final ok = await AppErrorHandler.guard<bool>(
                    context,
                        () async {
                      final role = await AppCache.getRole() ?? 'driver';
                      final data = await _auth.register(
                        name: _name.text.trim(),
                        email: _email.text.trim(),
                        phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
                        password: _pass.text,
                        role: role,
                      );
                      final user =
                          data['user'] as Map<String, dynamic>? ?? const {};
                      await AppCache.saveCurrentUser(
                        name: user['name']?.toString() ?? _name.text.trim(),
                        phone:
                        user['phone']?.toString() ??
                            _phone.text.replaceAll(RegExp(r'\D'), ''),
                        email: user['email']?.toString() ?? _email.text.trim(),
                        role: user['role']?.toString() ?? role,
                        userId:
                        user['id']?.toString() ?? user['_id']?.toString(),
                      );
                      if (_role == 'workshop') {
                        await _workshops.createWorkshop({
                          'name': _workshopName.text.trim(),
                          'location': _workshopLocation.text.trim(),
                          'latitude': workshopPoint!.latitude,
                          'longitude': workshopPoint.longitude,
                          'services': const <String>[],
                          'accountStatus': 'pending',
                          'isVerified': false,
                        });
                      }
                      final verification = await _documents.upload(
                        kind: _role == 'workshop' ? 'permit' : 'driver_license',
                        file: _verificationFile!,
                      );
                      if (mounted) {
                        final message = switch (verification
                            .aiVerificationStatus) {
                          'ai_verified' =>
                          'AI verification completed. Admin approval is still required.',
                          'ai_rejected' =>
                          'AI rejected this document. Admin can still review it.',
                          _ =>
                          'Your document is being verified and may need admin review.',
                        };
                        AppErrorHandler.showMessage(context, message);
                      }
                      return true;
                    },
                    fallbackMessage:
                    'Could not create the account. Please try again.',
                  );
                  if (!mounted) return;
                  setState(() => _loading = false);
                  if (ok == true) Navigator.pushNamed(context, R.otp);
                },
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 13, color: AC.t3),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AC.red,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 550.ms),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
}

class _VerificationPicker extends StatelessWidget {
  const _VerificationPicker({
    required this.role,
    required this.fileName,
    required this.onTap,
  });

  final String role;
  final String? fileName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AC.s2,
        borderRadius: Rd.mdA,
        border: Border.all(color: fileName == null ? AC.border : AC.red),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file_rounded, color: AC.t2),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role == 'workshop'
                      ? 'Workshop permit verification'
                      : 'Driver license verification',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AC.t1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fileName ?? 'Upload PDF, JPG, or PNG up to 5 MB',
                  style: const TextStyle(fontSize: 12, color: AC.t3),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
