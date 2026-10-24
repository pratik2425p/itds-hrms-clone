import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import '../services/auth_service.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';
import '../widgets/apply_leave_dialog.dart';

class LeaveApplicationsScreen extends StatefulWidget {
  final VoidCallback onOpenApplyLeave;

  const LeaveApplicationsScreen({
    super.key,
    required this.onOpenApplyLeave,
  });

  @override
  State<LeaveApplicationsScreen> createState() => _LeaveApplicationsScreenState();
}

class _LeaveApplicationsScreenState extends State<LeaveApplicationsScreen> {
  int _activeTab = 0; // 0: Pending, 1: Completed
  bool _isLoading = false;

  final List<LeaveRecord> _pendingLeaves = [];
  final List<LeaveRecord> _completedLeaves = [];
  final List<LeaveSummary> _leaveSummaries = [];

  @override
  void initState() {
    super.initState();
    _fetchLeavesAndBalances();
  }

  Future<void> _fetchLeavesAndBalances() async {
    setState(() => _isLoading = true);
    try {
      final empCode = AuthService().employeeCode;
      final serverpod = ServerpodService();

      // 1. Fetch live leave balances
      final summaries = await serverpod.getLeaveSummaries(employeeCode: empCode);

      // 2. Fetch live leave applications
      final records = await serverpod.getLeaveApplications(employeeCode: empCode);

      if (!mounted) return;
      setState(() {
        _leaveSummaries.clear();
        _leaveSummaries.addAll(summaries);

        _pendingLeaves.clear();
        _completedLeaves.clear();

        for (final rec in records) {
          final statusLower = rec.status.toLowerCase();
          if (statusLower.contains('pending')) {
            _pendingLeaves.add(rec);
          } else {
            _completedLeaves.add(rec);
          }
        }
      });
    } catch (e) {
      debugPrint('Error fetching leaves: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showApplyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ApplyLeaveDialog(
        onSubmitted: () {
          _fetchLeavesAndBalances();
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('approved')) return AppColors.presentGreen;
    if (s.contains('rejected')) return AppColors.absentRed;
    if (s.contains('cancelled')) return AppColors.textMuted;
    if (s.contains('level 1') || s.contains('senior')) return const Color(0xFFD97706);
    if (s.contains('level 2')) return const Color(0xFF2563EB);
    return AppColors.warningYellow;
  }

  Future<void> _handleCancelLeave(LeaveRecord leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cancel Leave Application', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Are you sure you want to cancel your leave request for ${leave.totalDays} day(s) (${leave.category})?',
          style: GoogleFonts.inter(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep Request', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.absentRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Yes, Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed == true && leave.id != null) {
      try {
        final empCode = AuthService().employeeCode;
        final success = await ServerpodService().cancelLeave(leaveId: leave.id!, employeeCode: empCode);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Leave application cancelled successfully.'),
                backgroundColor: AppColors.primaryOrange,
              ),
            );
            _fetchLeavesAndBalances();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel leave: $e'), backgroundColor: AppColors.absentRed),
          );
        }
      }
    }
  }

  void _showLeaveDetails(LeaveRecord leave) {
    final sLower = leave.status.toLowerCase();
    final isLevel1 = sLower.contains('level 1') || sLower.contains('senior');
    final isLevel2 = sLower.contains('level 2');
    final isApproved = sLower.contains('approved');
    final isRejected = sLower.contains('rejected');
    final isHalfDay = leave.totalDays == 0.5;
    final isEarnedLeave = leave.category.toLowerCase().contains('earned');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Leave Application Details',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Category:', leave.category),
                _buildDetailRow('From Date:', leave.startDate),
                _buildDetailRow('To Date:', leave.endDate),
                _buildDetailRow(
                  'Duration:',
                  isHalfDay ? '0.5 Day (Half Day Session)' : '${leave.totalDays} Day(s)',
                  valueColor: isHalfDay ? const Color(0xFF7C3AED) : null,
                  isBold: isHalfDay,
                ),
                _buildDetailRow('Applied On:', '${leave.appliedAt.day}-${leave.appliedAt.month}-${leave.appliedAt.year}'),
                _buildDetailRow(
                  'Current Status:',
                  leave.status,
                  valueColor: _getStatusColor(leave.status),
                  isBold: true,
                ),

                const SizedBox(height: 14),

                // Multi-Tier Hierarchy Stepper
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_tree_outlined, size: 14, color: AppColors.logiBlue),
                          const SizedBox(width: 6),
                          Text(
                            'Approval Hierarchy Tracking',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.logiBlue),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Step 1: Senior Lead
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isApproved || isLevel2
                                ? Icons.check_circle
                                : (isLevel1 ? Icons.timelapse : (isRejected ? Icons.cancel : Icons.radio_button_unchecked)),
                            size: 16,
                            color: isApproved || isLevel2
                                ? AppColors.presentGreen
                                : (isLevel1 ? const Color(0xFFD97706) : (isRejected ? AppColors.absentRed : AppColors.textMuted)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level 1: Senior Tech Lead (Anant Gangurde)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isLevel1 ? FontWeight.w700 : FontWeight.w600,
                                    color: isLevel1 ? const Color(0xFFD97706) : AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  isApproved || isLevel2
                                      ? 'Reviewed and Approved by Senior Lead'
                                      : (isLevel1 ? 'Awaiting Senior Lead Review' : 'Pending'),
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 7),
                        child: SizedBox(
                          height: 14,
                          child: VerticalDivider(thickness: 1.5, color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      // Step 2: Engineering Manager
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isApproved
                                ? Icons.check_circle
                                : (isLevel2 ? Icons.timelapse : (isRejected ? Icons.cancel : Icons.radio_button_unchecked)),
                            size: 16,
                            color: isApproved
                                ? AppColors.presentGreen
                                : (isLevel2 ? const Color(0xFF2563EB) : (isRejected ? AppColors.absentRed : AppColors.textMuted)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Level 2: Engineering Manager (Vikram Malhotra)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: isLevel2 ? FontWeight.w700 : FontWeight.w600,
                                    color: isLevel2 ? const Color(0xFF2563EB) : AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  isApproved
                                      ? 'Final Approval Granted'
                                      : (isLevel2 ? 'Awaiting Final Manager Sign-off' : 'Pending Step 1'),
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (isEarnedLeave) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFFB45309)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Earned Leave Policy: Max 3 applications allowed per calendar year.',
                            style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFB45309), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const Divider(height: 24, color: AppColors.borderLight),
                Text('Reason & Notes:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    leave.reason?.isNotEmpty == true ? leave.reason! : 'No reason specified',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentList = _activeTab == 0 ? _pendingLeaves : _completedLeaves;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top Leave Quotas Summary Cards
          _buildLeaveQuotasBar(),

          const Divider(height: 1, color: AppColors.border),

          // Sub-header with Tabs & Apply Leave button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildTab('Pending Applications (${_pendingLeaves.length})', 0),
                    const SizedBox(width: 24),
                    _buildTab('Completed Applications (${_completedLeaves.length})', 1),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20, color: AppColors.textMuted),
                      tooltip: 'Refresh',
                      onPressed: _fetchLeavesAndBalances,
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: _showApplyDialog,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(
                        'Apply for Leave',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Table Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    // Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(10),
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: _buildColHeader('Category')),
                          Expanded(flex: 2, child: _buildColHeader('Start Date')),
                          Expanded(flex: 2, child: _buildColHeader('End Date')),
                          Expanded(flex: 2, child: _buildColHeader('Total Leave Days')),
                          Expanded(flex: 2, child: _buildColHeader('Status')),
                          Expanded(flex: 2, child: _buildColHeader('Actions')),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.border),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryOrange),
                        ),
                      )
                    else if (currentList.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.assignment_outlined, size: 44, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                _activeTab == 0
                                    ? 'No Pending Leave Applications'
                                    : 'No Completed Leave Applications',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Click "Apply for Leave" above to submit a new time off request.',
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      for (final item in currentList) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.startDate,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.endDate,
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${item.totalDays} Day${item.totalDays > 1 ? "s" : ""}',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(item.status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(item.status),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.visibility_outlined, size: 18, color: AppColors.primaryOrange),
                                      tooltip: 'View Details',
                                      onPressed: () => _showLeaveDetails(item),
                                    ),
                                    if (_activeTab == 0)
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.absentRed),
                                        tooltip: 'Cancel Request',
                                        onPressed: () => _handleCancelLeave(item),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.borderLight),
                      ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveQuotasBar() {
    if (_leaveSummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: const Color(0xFFFBFBFD),
      child: Row(
        children: _leaveSummaries.map((summary) {
          Color color;
          String policySub = '${summary.remaining.toStringAsFixed(summary.remaining % 1 == 0 ? 0 : 1)}/${summary.totalQuotas} Available';
          final cat = summary.category.toLowerCase();
          if (cat.contains('privilege') || cat.contains('earned')) {
            color = AppColors.leavesBlue;
            policySub = 'Max 3 Times / Year';
          } else if (cat.contains('casual')) {
            color = AppColors.presentGreen;
            policySub = 'Flexible • Half Day avail';
          } else if (cat.contains('sick')) {
            color = AppColors.holidaysPurple;
            policySub = 'Medical • Anytime';
          } else if (cat.contains('lwp') || cat.contains('without pay')) {
            color = const Color(0xFF64748B);
            policySub = 'Loss of Pay';
          } else {
            color = const Color(0xFF0284C7);
          }

          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        summary.remaining.toStringAsFixed(summary.remaining % 1 == 0 ? 0 : 1),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.category,
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          policySub,
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _activeTab == 0 ? index == 0 : index == 1;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primaryOrange : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryOrange : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildColHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
      ),
    );
  }
}
