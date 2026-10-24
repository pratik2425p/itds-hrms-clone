import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';

class AddEmployeeDialog extends StatefulWidget {
  final VoidCallback onEmployeeAdded;

  const AddEmployeeDialog({super.key, required this.onEmployeeAdded});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _positionController = TextEditingController();
  final _locationController = TextEditingController(text: 'Mumbai HQ');

  String _department = 'Engineering';
  String _gender = 'Male';
  String _maritalStatus = 'Single';
  String _bloodGroup = 'B+';
  bool _isLoading = false;

  final List<String> _departments = [
    'Engineering',
    'Human Resources',
    'Quality Assurance',
    'Product',
    'Design',
    'Sales',
    'Marketing',
    'Finance',
  ];

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _positionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'EM';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final email = _emailController.text.trim();
    final position = _positionController.text.trim();

    if (name.isEmpty || code.isEmpty || email.isEmpty || position.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all mandatory fields (Name, Code, Email, Position).'),
          backgroundColor: AppColors.absentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final dayStr = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      final emp = EmployeeRecord(
        code: code,
        name: name,
        initials: _getInitials(name),
        role: position,
        department: _department,
        email: email,
        position: position,
        mobile: _mobileController.text.trim().isNotEmpty ? _mobileController.text.trim() : '+91 98000 00000',
        joinedOn: dayStr,
        branchLocation: _locationController.text.trim(),
        gender: _gender,
        maritalStatus: _maritalStatus,
        bloodGroup: _bloodGroup,
      );

      await ServerpodService().addEmployee(emp);

      if (mounted) {
        widget.onEmployeeAdded();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee $name ($code) successfully added to directory!'),
            backgroundColor: AppColors.presentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding employee: $e'),
            backgroundColor: AppColors.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_1, color: AppColors.primaryOrange, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Add New Employee',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Enter employee personal, contact, and job designation information.',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),

              // Two columns: Name & Code
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField('Full Name *', _nameController, hint: 'e.g. Rahul Sharma'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _buildTextField('Employee Code *', _codeController, hint: 'e.g. HRC09'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Two columns: Email & Mobile
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Work Email *', _emailController, hint: 'e.g. rahul@codeqube.ai'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Mobile Number', _mobileController, hint: '+91 98200 12345'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Two columns: Department & Position
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Department *', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _department,
                              isExpanded: true,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              items: _departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _department = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField('Position / Role *', _positionController, hint: 'e.g. Software Engineer'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Location & Marital Status
              Row(
                children: [
                  Expanded(
                    child: _buildTextField('Work Location', _locationController, hint: 'e.g. Mumbai HQ'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Marital Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _maritalStatus,
                              isExpanded: true,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              items: ['Single', 'Married', 'Other'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _maritalStatus = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gender & Blood Group
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gender', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _gender,
                              isExpanded: true,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _gender = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Blood Group', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _bloodGroup,
                              isExpanded: true,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                              items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _bloodGroup = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Save Employee',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
