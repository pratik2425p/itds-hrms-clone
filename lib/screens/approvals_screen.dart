import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';

class ApprovalsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ApprovalsScreen({super.key, this.onBack});

  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  bool _isLoading = true;
  String _activeFilter = 'Pending'; // 'Pending', 'Approved', 'Rejected', 'All'
  String _searchQuery = '';
  List<LeaveRecord> _allRequests = [];
  Map<String, EmployeeRecord> _employeeCache = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final serverpod = ServerpodService();
      final leavesFuture = serverpod.getAllLeaveApplications();
      final employeesFuture = serverpod.getEmployees();

      final results = await Future.wait([leavesFuture, employeesFuture]);
      final leaves = results[0] as List<LeaveRecord>;
      final employees = results[1] as List<EmployeeRecord>;

      final empMap = <String, EmployeeRecord>{};
      for (final emp in employees) {
        empMap[emp.code] = emp;
      }

      // Also trigger pending approvals seeding check if leaves are empty
      if (leaves.isEmpty) {
        await serverpod.getPendingApprovals();
        final refreshed = await serverpod.getAllLeaveApplications();
        if (mounted) {
          setState(() {
            _allRequests = refreshed;
            _employeeCache = empMap;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _allRequests = leaves;
            _employeeCache = empMap;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading approvals data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(LeaveRecord record) async {
    if (record.id == null) return;
    try {
      final success = await ServerpodService().approveLeave(record.id!);
      if (success) {
        if (mounted) {
          String message = 'Leave request for ${record.employeeCode} has been approved!';
          final sLower = record.status.toLowerCase();
          if (sLower.contains('level 1') || sLower.contains('senior')) {
            message = 'Level 1 Approval confirmed by Senior Lead! Request forwarded to Engineering Manager (Level 2).';
          } else if (sLower.contains('level 2')) {
            message = 'Level 2 Approval confirmed by Engineering Manager! Leave is now Fully Approved.';
          } else if (sLower.contains('manager')) {
            message = 'Manager Approval confirmed! Leave is now Fully Approved.';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(message, style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                ],
              ),
              backgroundColor: AppColors.presentGreen,
              duration: const Duration(seconds: 4),
            ),
          );
          _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e'), backgroundColor: AppColors.absentRed),
        );
      }
    }
  }

  Future<void> _showRejectDialog(LeaveRecord record) async {
    if (record.id == null) return;
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.absentRed, size: 24),
            const SizedBox(width: 8),
            Text('Reject Leave Request', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please provide a reason for rejecting ${record.employeeCode}\'s ${record.category}:',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'e.g. Critical project deadline, lack of staffing...',
                hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primaryOrange),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              Navigator.of(ctx).pop();
              try {
                final success = await ServerpodService().rejectLeave(record.id!, reason);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Leave request for ${record.employeeCode} was rejected.'),
                      backgroundColor: AppColors.absentRed,
                    ),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error rejecting request: $e'), backgroundColor: AppColors.absentRed),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.absentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirm Reject', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<LeaveRecord> get _filteredRequests {
    return _allRequests.where((req) {
      // 1. Status Filter
      if (_activeFilter == 'Pending' && !req.status.toLowerCase().contains('pending')) {
        return false;
      }
      if (_activeFilter == 'Approved' && !req.status.toLowerCase().contains('approved')) {
        return false;
      }
      if (_activeFilter == 'Rejected' && !req.status.toLowerCase().contains('rejected')) {
        return false;
      }

      // 2. Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final emp = _employeeCache[req.employeeCode];
        final empName = emp?.name.toLowerCase() ?? '';
        final matches = req.employeeCode.toLowerCase().contains(q) ||
            req.category.toLowerCase().contains(q) ||
            (req.reason ?? '').toLowerCase().contains(q) ||
            empName.contains(q);
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  int get _pendingCount => _allRequests.where((r) => r.status.toLowerCase().contains('pending')).length;
  int get _approvedCount => _allRequests.where((r) => r.status.toLowerCase().contains('approved')).length;
  int get _rejectedCount => _allRequests.where((r) => r.status.toLowerCase().contains('rejected')).length;

  @override
  Widget build(BuildContext context) {
    final list = _filteredRequests;

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Subheader bar with metrics & search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 700;

                final searchBar = SizedBox(
                  width: isCompact ? double.infinity : 280,
                  height: 40,
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search by employee or reason...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                );

                final filterChips = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('Pending', 'Pending ($_pendingCount)', AppColors.primaryOrange),
                    _buildFilterChip('Approved', 'Approved ($_approvedCount)', AppColors.presentGreen),
                    _buildFilterChip('Rejected', 'Rejected ($_rejectedCount)', AppColors.absentRed),
                    _buildFilterChip('All', 'All Requests (${_allRequests.length})', const Color(0xFF475569)),
                  ],
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      filterChips,
                      const SizedBox(height: 12),
                      searchBar,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    filterChips,
                    Row(
                      children: [
                        searchBar,
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh, color: AppColors.primaryOrange),
                          tooltip: 'Refresh Requests',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),

          // Main List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                : list.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(24),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return _buildRequestCard(list[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label, Color activeColor) {
    final isSelected = _activeFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _activeFilter = filterKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? activeColor : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(LeaveRecord record) {
    final emp = _employeeCache[record.employeeCode];
    final empName = emp?.name ?? record.employeeCode;
    final initials = emp?.initials ?? record.employeeCode.substring(0, 2);
    final department = emp?.department ?? 'General';
    final role = emp?.position ?? emp?.role ?? 'Team Member';

    final isPending = record.status.toLowerCase().contains('pending');
    final isApproved = record.status.toLowerCase().contains('approved');
    final isRejected = record.status.toLowerCase().contains('rejected');

    Color statusColor = AppColors.primaryOrange;
    if (isApproved) statusColor = AppColors.presentGreen;
    if (isRejected) statusColor = AppColors.absentRed;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          final employeeInfo = Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                child: Text(
                  initials,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primaryOrange, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(empName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(
                    '${record.employeeCode} • $role ($department)',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          );

          final leaveDetails = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      record.category,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryOrange),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${record.totalDays} ${record.totalDays == 1 ? 'Day' : 'Days'}',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 8),
                  Text('•', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  const SizedBox(width: 8),
                  Text(
                    '${record.startDate} to ${record.endDate}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                  ),
                ],
              ),
              if (record.reason != null && record.reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.reason!,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );

          final sLower = record.status.toLowerCase();
          final isLevel1 = sLower.contains('level 1') || sLower.contains('senior');
          final isLevel2 = sLower.contains('level 2');
          final isPendingManagerOnly = sLower == 'pending manager approval';

          String actionButtonLabel = 'Approve';
          Color actionButtonColor = AppColors.presentGreen;
          IconData actionIcon = Icons.check_circle_outline;

          if (isLevel1) {
            actionButtonLabel = 'Approve as Senior (L1)';
            actionButtonColor = const Color(0xFFD97706); // Amber
            actionIcon = Icons.military_tech_outlined;
          } else if (isLevel2) {
            actionButtonLabel = 'Approve as Manager (L2)';
            actionButtonColor = const Color(0xFF2563EB); // Royal Blue
            actionIcon = Icons.verified_user_outlined;
          } else if (isPendingManagerOnly) {
            actionButtonLabel = 'Approve as Manager';
            actionButtonColor = const Color(0xFF2563EB);
            actionIcon = Icons.verified_user_outlined;
          }

          // Build Hierarchy Stepper badge
          Widget buildHierarchyTracker() {
            final isJuniorDev = record.employeeCode.startsWith('ITD') ||
                role.toLowerCase().contains('developer') ||
                role.toLowerCase().contains('engineer');

            if (!isJuniorDev && !sLower.contains('level')) {
              return const SizedBox.shrink();
            }

            final step1Done = !isLevel1;
            final step2Done = isApproved;

            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    step1Done ? Icons.check_circle : (isLevel1 ? Icons.timelapse : Icons.radio_button_unchecked),
                    size: 14,
                    color: step1Done
                        ? AppColors.presentGreen
                        : (isLevel1 ? const Color(0xFFD97706) : AppColors.textMuted),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '1. Senior Lead (L1)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isLevel1 ? FontWeight.w700 : FontWeight.w500,
                      color: isLevel1 ? const Color(0xFFD97706) : AppColors.textDark,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textMuted),
                  ),
                  Icon(
                    step2Done ? Icons.check_circle : (isLevel2 ? Icons.timelapse : Icons.radio_button_unchecked),
                    size: 14,
                    color: step2Done
                        ? AppColors.presentGreen
                        : (isLevel2 ? const Color(0xFF2563EB) : AppColors.textMuted),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '2. Manager (L2)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: isLevel2 ? FontWeight.w700 : FontWeight.w500,
                      color: isLevel2 ? const Color(0xFF2563EB) : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }

          final statusAndActions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 4, backgroundColor: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      record.status,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ],
                ),
              ),
              if (isPending) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _approve(record),
                  icon: Icon(actionIcon, size: 16, color: Colors.white),
                  label: Text(actionButtonLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionButtonColor,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(record),
                  icon: const Icon(Icons.close, size: 16, color: AppColors.absentRed),
                  label: Text('Reject', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.absentRed)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.absentRed),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 3, child: employeeInfo),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leaveDetails,
                      buildHierarchyTracker(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                statusAndActions,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              employeeInfo,
              const SizedBox(height: 12),
              leaveDetails,
              buildHierarchyTracker(),
              const SizedBox(height: 12),
              const Divider(color: AppColors.borderLight, height: 1),
              const SizedBox(height: 12),
              statusAndActions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fact_check_outlined, size: 48, color: AppColors.primaryOrange),
          ),
          const SizedBox(height: 16),
          Text(
            'No Requests Found',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'There are currently no leave requests in the "$_activeFilter" category.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
