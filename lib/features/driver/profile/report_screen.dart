import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _formKey = GlobalKey<FormState>();

  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'App Issue';
  bool _loading = false;

  final List<String> _reportTypes = [
    'App Issue',
    'Booking Problem',
    'Workshop Problem',
    'Payment Problem',
    'Account Problem',
    'Other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted successfully'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AC.bg,
      appBar: SAppBar(title: 'Report a Problem'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ACard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.report_problem_outlined,
                  color: AC.red,
                  size: 34,
                ),
                SizedBox(height: 12),
                Text(
                  'Tell us what happened',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AC.t1,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Your report helps us improve Salahny and solve your issue faster.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AC.t3,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Form(
            key: _formKey,
            child: ACard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Report Type',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AC.t1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: AC.s1,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AC.s2,
                      border: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.red),
                      ),
                    ),
                    style: const TextStyle(color: AC.t1),
                    items: _reportTypes
                        .map(
                          (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ),
                    )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _subjectController,
                    style: const TextStyle(color: AC.t1),
                    decoration: InputDecoration(
                      labelText: 'Subject',
                      labelStyle: const TextStyle(color: AC.t3),
                      filled: true,
                      fillColor: AC.s2,
                      border: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.red),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter report subject';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    style: const TextStyle(color: AC.t1),
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                      labelStyle: const TextStyle(color: AC.t3),
                      filled: true,
                      fillColor: AC.s2,
                      border: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: Rd.mdA,
                        borderSide: const BorderSide(color: AC.red),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe your problem';
                      }
                      if (value.trim().length < 10) {
                        return 'Description must be at least 10 characters';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 22),

                  AppBtn(
                    label: 'Submit Report',
                    loading: _loading,
                    onTap: _loading ? null : _submitReport,
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
