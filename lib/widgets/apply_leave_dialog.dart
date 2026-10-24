import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';

class ApplyLeaveDialog extends StatefulWidget {
  final VoidCallback onSubmitted;

  const ApplyLeaveDialog({super.key, required this.onSubmitted});

  @override
  State<ApplyLeaveDialog> createState() => _ApplyLeaveDialogState();
}

class _ApplyLeaveDialogState extends State<ApplyLeaveDialog> {
  String _leaveType = 'Casual Leave';
  final _reasonController = TextEditingController();
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isHalfDay = false;
  String _halfDaySession = 'First Half (Morning)'; // 'First Half (Morning)' or 'Second Half (Afternoon)'
  bool _isLoading = false;
  bool _isLoadingBalances = true;
  int _earnedLeaveTimesUsed = 0;
  String _employeeRole = 'Employee';

  final Map<String, double> _balances = {
    'Casual Leave': 12.0,
    'Sick Leave': 7.0,
    'Earned Leave': 15.0,
    'Compensatory Off': 3.0,
    'Leave Without Pay (LWP)': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final empCode = AuthService().employeeCode;
      final serverpod = ServerpodService();

      final results = await Future.wait([
        serverpod.getLeaveSummaries(employeeCode: empCode),
        serverpod.getLeaveApplications(employeeCode: empCode),
        serverpod.getEmployees(),
      ]);

      final summaries = results[0] as List<LeaveSummary>;
      final records = results[1] as List<LeaveRecord>;
      final employees = results[2] as List<EmployeeRecord>;

      if (mounted) {
        setState(() {
          for (final s in summaries) {
            _balances[s.category] = s.remaining;
            if (s.category.toLowerCase().contains('privilege')) {
              _balances['Earned Leave'] = s.remaining;
            }
          }

          // Count how many times Earned Leave has been applied in the current calendar year
          final currentYear = DateTime.now().year.toString();
          _earnedLeaveTimesUsed = records.where((l) {
            final isEl = l.category.toLowerCase().contains('earned') || l.category.toLowerCase().contains('privilege');
            final isYear = l.startDate.startsWith(currentYear) || l.appliedAt.year.toString() == currentYear;
            final isValid = !l.status.toLowerCase().contains('reject') && !l.status.toLowerCase().contains('cancel');
            return isEl && isYear && isValid;
          }).length;

          // Identify employee role
          final myEmp = employees.firstWhere(
            (e) => e.code == empCode,
            orElse: () => EmployeeRecord(
              code: empCode,
              name: 'Employee',
              initials: 'EM',
              role: 'Developer',
              department: 'Engineering',
              email: '',
              position: 'Developer',
            ),
          );
          _employeeRole = myEmp.role;
        });
      }
    } catch (e) {
      debugPrint('Error loading leave data in dialog: $e');
    } finally {
      if (mounted) setState(() => _isLoadingBalances = false);
    }
  }

  double get _calculatedDays {
    if (_isHalfDay) return 0.5;
    final diff = _endDate.difference(_startDate).inDays + 1;
    return diff > 0 ? diff.toDouble() : 1.0;
  }

  double get _currentAvailableBalance {
    return _balances[_leaveType] ?? 0.0;
  }

  bool get _isEarnedLeaveExhausted {
    return (_leaveType == 'Earned Leave' || _leaveType == 'Privilege Leave') && _earnedLeaveTimesUsed >= 3;
  }

  bool get _isSeniorOrManager {
    final r = _employeeRole.toLowerCase();
    return r.contains('senior') || r.contains('lead') || r.contains('manager') || r.contains('head');
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_isHalfDay || _endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please specify a brief reason for your leave application.'),
          backgroundColor: AppColors.absentRed,
        ),
      );
      return;
    }

    // Check Earned Leave 3-times annual limit
    if (_isEarnedLeaveExhausted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company Policy Restriction: Earned Leave is capped at 3 applications per calendar year. Please select Casual Leave, Sick Leave, or LWP.'),
          backgroundColor: AppColors.absentRed,
        ),
      );
      return;
    }

    final totalDays = _calculatedDays;
    final available = _currentAvailableBalance;
    final isLwp = _leaveType.toLowerCase().contains('lwp') || _leaveType.toLowerCase().contains('without pay');

    if (!isLwp && totalDays > available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance! You requested $totalDays day(s), but only $available day(s) remain for $_leaveType. Choose LWP if required.'),
          backgroundColor: AppColors.absentRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate);
      final empCode = AuthService().employeeCode;

      final sessionNote = _isHalfDay ? ' [Session: $_halfDaySession]' : '';
      final fullReason = '$reason$sessionNote';

      await ServerpodService().applyLeave(
        employeeCode: empCode,
        category: _leaveType,
        startDate: startStr,
        endDate: endStr,
        totalDays: totalDays,
        reason: fullReason,
      );

      if (mounted) {
        widget.onSubmitted();
        Navigator.of(context).pop();

        final approvalTarget = _isSeniorOrManager
            ? 'Manager Approval (Level 1)'
            : 'Level 1 Senior Approval & Level 2 Manager Approval';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Leave application for $totalDays day(s) submitted for $approvalTarget!',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.presentGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit leave: $e'),
            backgroundColor: AppColors.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalDays = _calculatedDays;
    final available = _currentAvailableBalance;
    final isLwp = _leaveType.toLowerCase().contains('lwp') || _leaveType.toLowerCase().contains('without pay');
    final isEl = _leaveType == 'Earned Leave' || _leaveType == 'Privilege Leave';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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
                          color: AppColors.logiBlue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flight_takeoff, color: AppColors.logiBlue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Apply for Leave',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Company Hierarchy Multi-Tier Approval Flow',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
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

              // Hierarchy Flow Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 14, color: AppColors.logiBlue),
                        const SizedBox(width: 6),
                        Text(
                          'Approval Hierarchy Route:',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (!_isSeniorOrManager) ...[
                          _buildHierarchyBadge('L1: Senior Lead (Anant G.)'),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          _buildHierarchyBadge('L2: Manager (Vikram M.)'),
                        ] else ...[
                          _buildHierarchyBadge('L1: Manager (Vikram M.)'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Leave Type Dropdown
              Text(
                'Leave Category *',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
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
                    value: _leaveType,
                    isExpanded: true,
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                    items: [
                      'Casual Leave',
                      'Sick Leave',
                      'Earned Leave',
                      'Leave Without Pay (LWP)',
                      'Compensatory Off',
                    ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _leaveType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Earned Leave Annual Quota Tracker (Max 3 times per calendar year)
              if (isEl) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _earnedLeaveTimesUsed >= 3 ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _earnedLeaveTimesUsed >= 3 ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _earnedLeaveTimesUsed >= 3 ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                        size: 16,
                        color: _earnedLeaveTimesUsed >= 3 ? AppColors.absentRed : AppColors.logiBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Earned Leave Policy: Max 3 times per calendar year',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _earnedLeaveTimesUsed >= 3 ? AppColors.absentRed : const Color(0xFF1E40AF),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _earnedLeaveTimesUsed >= 3
                                  ? 'Annual limit reached! You have utilized 3 of 3 applications for 2026.'
                                  : 'Yearly Usage: $_earnedLeaveTimesUsed of 3 applications used (${3 - _earnedLeaveTimesUsed} remaining)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: _earnedLeaveTimesUsed >= 3 ? AppColors.absentRed : const Color(0xFF1E3A8A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Available Balance Badge
              if (!isLwp) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Balance:',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: available > 0
                            ? AppColors.presentGreen.withValues(alpha: 0.12)
                            : AppColors.absentRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isLoadingBalances ? 'Checking...' : '$available Days Remaining',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: available > 0 ? AppColors.presentGreen : AppColors.absentRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.money_off_rounded, size: 14, color: Color(0xFFB45309)),
                      const SizedBox(width: 6),
                      Text(
                        'Unpaid Leave: Salary deduction applies for approved LWP days.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Half Day Toggle
              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _isHalfDay,
                      activeColor: AppColors.logiBlue,
                      onChanged: (val) {
                        setState(() {
                          _isHalfDay = val ?? false;
                          if (_isHalfDay) {
                            _endDate = _startDate;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Apply for Half Day (0.5 Day)',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                ],
              ),

              // Half Day Session Selection (Morning / Afternoon)
              if (_isHalfDay) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Half Day Session *',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSessionChoiceChip(
                              label: 'First Half (Morning)',
                              time: '09:30 AM - 01:30 PM',
                              selected: _halfDaySession.contains('First'),
                              onTap: () => setState(() => _halfDaySession = 'First Half (Morning)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSessionChoiceChip(
                              label: 'Second Half (Afternoon)',
                              time: '02:00 PM - 06:30 PM',
                              selected: _halfDaySession.contains('Second'),
                              onTap: () => setState(() => _halfDaySession = 'Second Half (Afternoon)'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Date Range Picker
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isHalfDay ? 'Leave Date' : 'Start Date',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pickStartDate,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd MMM yyyy').format(_startDate),
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                                const Icon(Icons.calendar_today, size: 14, color: AppColors.logiBlue),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isHalfDay) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _pickEndDate,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd MMM yyyy').format(_endDate),
                                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const Icon(Icons.calendar_today, size: 14, color: AppColors.logiBlue),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Total Days Calculated banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Leave Duration:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                    Text(
                      _isHalfDay ? '0.5 Day (Half Day)' : '$totalDays Day${totalDays > 1 ? "s" : ""}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.logiBlue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Reason
              Text(
                'Reason for Leave *',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _reasonController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Attending family function / Medical consultation...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                    contentPadding: const EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                      backgroundColor: _isEarnedLeaveExhausted ? Colors.grey : AppColors.logiBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading || _isEarnedLeaveExhausted ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEarnedLeaveExhausted ? 'Quota Reached (3/3)' : 'Submit Application',
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

  Widget _buildHierarchyBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.logiBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.logiBlue),
      ),
    );
  }

  Widget _buildSessionChoiceChip({
    required String label,
    required String time,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.logiBlue : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.logiBlue : AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: selected ? Colors.white.withValues(alpha: 0.85) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
