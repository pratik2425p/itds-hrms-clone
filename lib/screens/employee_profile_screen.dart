import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import '../services/auth_service.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';
import '../models/hrms_models.dart';

class EmployeeProfileScreen extends StatefulWidget {
  final Employee? employee;

  const EmployeeProfileScreen({super.key, this.employee});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  int _selectedSection = 0; // 0: Personal, 1: Employment, 2: Bank & Statutory, 3: Emergency Contacts
  bool _isLoading = false;
  bool _isSaving = false;

  EmployeeRecord? _loadedRecord;

  // Personal Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _dobController;
  String _gender = 'Male';
  String _maritalStatus = 'Single';
  String _bloodGroup = 'B+';

  // Employment Controllers
  late TextEditingController _codeController;
  late TextEditingController _roleController;
  late TextEditingController _deptController;
  late TextEditingController _joinedController;
  late TextEditingController _locationController;

  // Bank & Statutory Controllers
  late TextEditingController _bankNameController;
  late TextEditingController _accountNoController;
  late TextEditingController _ifscController;
  late TextEditingController _panController;

  // Emergency Contact Controllers
  late TextEditingController _emergencyNameController;
  late TextEditingController _emergencyRelationController;
  late TextEditingController _emergencyPhoneController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchEmployeeData();
  }

  void _initControllers() {
    final defaultName = widget.employee?.name ?? AuthService().displayName;
    final nameParts = defaultName.split(' ');
    _firstNameController = TextEditingController(text: nameParts.isNotEmpty ? nameParts.first : '');
    _middleNameController = TextEditingController(text: nameParts.length > 2 ? nameParts[1] : '');
    _lastNameController = TextEditingController(text: nameParts.length > 1 ? nameParts.last : '');

    _emailController = TextEditingController(text: widget.employee?.email ?? AuthService().email);
    _mobileController = TextEditingController(text: widget.employee?.mobile ?? '+91 98765 43210');
    _dobController = TextEditingController(text: '24-07-1994');

    final code = widget.employee?.code ?? AuthService().employeeCode;
    _codeController = TextEditingController(text: code);
    _roleController = TextEditingController(text: widget.employee?.role ?? AuthService().role);
    _deptController = TextEditingController(text: widget.employee?.department ?? 'Engineering');
    _joinedController = TextEditingController(text: widget.employee?.joinedOn ?? '01-Jan-2023');
    _locationController = TextEditingController(text: widget.employee?.branchLocation ?? 'Mumbai HQ');

    _bankNameController = TextEditingController(text: 'HDFC Bank Ltd');
    _accountNoController = TextEditingController(text: '50100234567890');
    _ifscController = TextEditingController(text: 'HDFC0001234');
    _panController = TextEditingController(text: 'ABCDE1234F');

    _emergencyNameController = TextEditingController(text: 'Sunil Nikam');
    _emergencyRelationController = TextEditingController(text: 'Father');
    _emergencyPhoneController = TextEditingController(text: '+91 98200 99887');
  }

  Future<void> _fetchEmployeeData() async {
    setState(() => _isLoading = true);
    try {
      final code = widget.employee?.code ?? AuthService().employeeCode;
      final record = await ServerpodService().getEmployeeByCode(code);
      if (record != null && mounted) {
        setState(() {
          _loadedRecord = record;
          final nameParts = record.name.split(' ');
          _firstNameController.text = nameParts.isNotEmpty ? nameParts.first : '';
          _middleNameController.text = nameParts.length > 2 ? nameParts[1] : '';
          _lastNameController.text = nameParts.length > 1 ? nameParts.last : '';
          _emailController.text = record.email;
          _mobileController.text = record.mobile ?? '';
          _roleController.text = record.role;
          _deptController.text = record.department;
          _joinedController.text = record.joinedOn ?? '';
          _locationController.text = record.branchLocation ?? '';
          if (record.bloodGroup != null) {
            if (record.bloodGroup!.startsWith('{')) {
              try {
                final data = jsonDecode(record.bloodGroup!) as Map<String, dynamic>;
                _bankNameController.text = data['bankName'] ?? _bankNameController.text;
                _accountNoController.text = data['accountNo'] ?? _accountNoController.text;
                _ifscController.text = data['ifsc'] ?? _ifscController.text;
                _panController.text = data['pan'] ?? _panController.text;
                _emergencyNameController.text = data['emergencyName'] ?? _emergencyNameController.text;
                _emergencyRelationController.text = data['emergencyRelation'] ?? _emergencyRelationController.text;
                _emergencyPhoneController.text = data['emergencyPhone'] ?? _emergencyPhoneController.text;
                if (data['bloodGroup'] != null) _bloodGroup = data['bloodGroup'];
              } catch (_) {}
            } else {
              _bloodGroup = record.bloodGroup!;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching employee details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final fName = _firstNameController.text.trim();
      final lName = _lastNameController.text.trim();
      final fullName = lName.isNotEmpty ? '$fName $lName' : fName;
      final code = _codeController.text.trim();

      final bankAndEmergencyJson = jsonEncode({
        'bankName': _bankNameController.text.trim(),
        'accountNo': _accountNoController.text.trim(),
        'ifsc': _ifscController.text.trim(),
        'pan': _panController.text.trim(),
        'emergencyName': _emergencyNameController.text.trim(),
        'emergencyRelation': _emergencyRelationController.text.trim(),
        'emergencyPhone': _emergencyPhoneController.text.trim(),
        'bloodGroup': _bloodGroup,
      });

      final record = EmployeeRecord(
        id: _loadedRecord?.id,
        code: code,
        name: fullName,
        initials: (fName.isNotEmpty ? fName[0] : 'E') + (lName.isNotEmpty ? lName[0] : ''),
        role: _roleController.text.trim(),
        department: _deptController.text.trim(),
        email: _emailController.text.trim(),
        position: _roleController.text.trim(),
        mobile: _mobileController.text.trim(),
        joinedOn: _joinedController.text.trim(),
        branchLocation: _locationController.text.trim(),
        gender: _loadedRecord?.gender ?? '68000', // Keep monthly gross salary intact
        maritalStatus: _loadedRecord?.maritalStatus ?? 'welcome123', // Keep login password intact
        bloodGroup: bankAndEmergencyJson, // Save structured bank & statutory details
      );

      if (_loadedRecord != null && _loadedRecord!.id != null) {
        await ServerpodService().updateEmployee(record);
      } else {
        await ServerpodService().addEmployee(record);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee profile updated successfully in database!'),
            backgroundColor: AppColors.presentGreen,
          ),
        );
        _fetchEmployeeData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _codeController.dispose();
    _roleController.dispose();
    _deptController.dispose();
    _joinedController.dispose();
    _locationController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _panController.dispose();
    _emergencyNameController.dispose();
    _emergencyRelationController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empName = _loadedRecord?.name ?? widget.employee?.name ?? AuthService().displayName;
    final empCode = _loadedRecord?.code ?? widget.employee?.code ?? AuthService().employeeCode;
    final empInitials = _loadedRecord?.initials ?? widget.employee?.initials ?? AuthService().initials;
    final empEmail = _loadedRecord?.email ?? widget.employee?.email ?? AuthService().email;
    final empRole = _loadedRecord?.role ?? widget.employee?.role ?? AuthService().role;

    return Container(
      color: Colors.white,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Profile Card
                  _buildHeroProfileCard(empName, empCode, empInitials, empEmail, empRole),
                  const SizedBox(height: 24),

                  // Two-column section & form
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Navigation: Sections
                      Container(
                        width: 220,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(Icons.dashboard_customize_outlined, size: 18, color: AppColors.primaryOrange),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Profile Sections',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: AppColors.border),
                            _buildSectionNavItem(0, Icons.badge_outlined, 'Personal Info'),
                            _buildSectionNavItem(1, Icons.work_outline, 'Employment Details'),
                            _buildSectionNavItem(2, Icons.account_balance_outlined, 'Bank & Statutory'),
                            _buildSectionNavItem(3, Icons.contact_phone_outlined, 'Emergency Contacts'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Right Content: Form
                      Expanded(
                        child: _buildFormCard(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroProfileCard(
    String name,
    String code,
    String initials,
    String email,
    String role,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryOrange.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        code,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$role • ${_deptController.text}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(email, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                    const SizedBox(width: 16),
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 6),
                    Text(_mobileController.text, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight)),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isSaving ? null : _saveChanges,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, size: 16),
            label: Text(
              _isSaving ? 'Saving...' : 'Save Profile',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionNavItem(int sectionIndex, IconData icon, String title) {
    final isSelected = _selectedSection == sectionIndex;
    return InkWell(
      onTap: () => setState(() => _selectedSection = sectionIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: isSelected ? const Color(0xFFFFF4EC) : Colors.transparent,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryOrange : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryOrange : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    switch (_selectedSection) {
      case 0:
        return _buildPersonalForm();
      case 1:
        return _buildEmploymentForm();
      case 2:
        return _buildBankStatutoryForm();
      case 3:
        return _buildEmergencyContactsForm();
      default:
        return _buildPersonalForm();
    }
  }

  Widget _buildPersonalForm() {
    return _buildContainerWrapper(
      title: 'Personal Information',
      icon: Icons.person_pin,
      children: [
        Row(
          children: [
            Expanded(child: _buildFormField('First Name *', _firstNameController)),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('Middle Name', _middleNameController, hint: 'Middle Name')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFormField('Last Name *', _lastNameController)),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('Email ID *', _emailController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFormField('Mobile Number', _mobileController)),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDropdownField('Gender', _gender, ['Male', 'Female', 'Other'], (val) {
                setState(() => _gender = val!);
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDropdownField('Marital Status', _maritalStatus, ['Single', 'Married', 'Other'], (val) {
                setState(() => _maritalStatus = val!);
              }),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _buildDropdownField('Blood Group', _bloodGroup, ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'], (val) {
                setState(() => _bloodGroup = val!);
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmploymentForm() {
    return _buildContainerWrapper(
      title: 'Employment Details',
      icon: Icons.work,
      children: [
        Row(
          children: [
            Expanded(child: _buildFormField('Employee Code', _codeController, readOnly: true)),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('Designation / Role *', _roleController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFormField('Department *', _deptController)),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('Branch Location', _locationController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFormField('Date of Joining', _joinedController)),
            const SizedBox(width: 24),
            Expanded(
              child: _buildFormField('Employment Type', TextEditingController(text: 'Full-Time (Permanent)'), readOnly: true),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBankStatutoryForm() {
    return _buildContainerWrapper(
      title: 'Bank & Statutory Details',
      icon: Icons.account_balance,
      children: [
        Row(
          children: [
            Expanded(child: _buildFormField('Bank Name', _bankNameController)),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('Account Number', _accountNoController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFormField('IFSC Code', _ifscController)),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('PAN Card Number', _panController)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmergencyContactsForm() {
    return _buildContainerWrapper(
      title: 'Emergency Contact Information',
      icon: Icons.contact_phone,
      children: [
        Row(
          children: [
            Expanded(child: _buildFormField('Contact Person Name', _emergencyNameController)),
            const SizedBox(width: 24),
            Expanded(child: _buildFormField('Relationship', _emergencyRelationController)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildFormField('Contact Phone Number', _emergencyPhoneController)),
            const SizedBox(width: 24),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildContainerWrapper({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: AppColors.primaryOrange),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, {String? hint, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
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

  Widget _buildDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: items.contains(value) ? value : items.first,
              isExpanded: true,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
