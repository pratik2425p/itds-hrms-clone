import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import '../models/company_policy.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';

class GeneralInfoScreen extends StatefulWidget {
  const GeneralInfoScreen({super.key});

  @override
  State<GeneralInfoScreen> createState() => _GeneralInfoScreenState();
}

class _GeneralInfoScreenState extends State<GeneralInfoScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  int _selectedTabIndex = 0; // 0: Holidays, 1: Company Policies

  List<HolidayEntry> _holidays = [];
  List<CompanyPolicy> _policies = [];
  String _selectedYear = 'Calendar Year 2026';

  // Policy filters
  String _policyCategoryFilter = 'All';
  final TextEditingController _policySearchController = TextEditingController();
  String _policySearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    _policySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData({bool showRefreshIndicator = false}) async {
    if (showRefreshIndicator) {
      setState(() => _isRefreshing = true);
    } else {
      setState(() => _isLoading = true);
    }

    try {
      final s = ServerpodService();
      final results = await Future.wait([
        s.getHolidays(),
        s.getPolicies(),
      ]);

      if (mounted) {
        setState(() {
          _holidays = results[0] as List<HolidayEntry>;
          _policies = results[1] as List<CompanyPolicy>;
          _isLoading = false;
          _isRefreshing = false;
        });

        if (showRefreshIndicator) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Latest holidays & policies synced with HR Admin Portal',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading general info: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // Filtered policies
  List<CompanyPolicy> get _filteredPolicies {
    return _policies.where((p) {
      final matchesCategory = _policyCategoryFilter == 'All' ||
          p.category.toLowerCase() == _policyCategoryFilter.toLowerCase();
      final matchesSearch = _policySearchQuery.isEmpty ||
          p.title.toLowerCase().contains(_policySearchQuery.toLowerCase()) ||
          p.summary.toLowerCase().contains(_policySearchQuery.toLowerCase()) ||
          p.content.toLowerCase().contains(_policySearchQuery.toLowerCase()) ||
          p.category.toLowerCase().contains(_policySearchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: AppColors.scaffoldBg,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.logiBlue),
              SizedBox(height: 16),
              Text('Fetching corporate holidays and HR policies...'),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.scaffoldBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Tab Navigation & Action Bar
            _buildTopActionBar(),
            const SizedBox(height: 20),

            // Main Content Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Approver & Corporate Info Desk
                SizedBox(
                  width: 260,
                  child: _buildLeftInfoPanel(),
                ),

                const SizedBox(width: 24),

                // Right Column: Active Tab Content (Holidays or Policies)
                Expanded(
                  child: _selectedTabIndex == 0
                      ? _buildHolidaysView()
                      : _buildPoliciesView(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TOP ACTION BAR & TABS ====================

  Widget _buildTopActionBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Segmented Tabs
          Row(
            children: [
              _buildTabPill(
                index: 0,
                icon: Icons.celebration_rounded,
                title: 'Official Holidays',
                count: _holidays.length,
              ),
              const SizedBox(width: 10),
              _buildTabPill(
                index: 1,
                icon: Icons.menu_book_rounded,
                title: 'Company Policies & Guidelines',
                count: _policies.length,
              ),
            ],
          ),

          // Right Controls: Sync / Refresh & Live Indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Live HR Sync',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _isRefreshing
                    ? null
                    : () => _loadAllData(showRefreshIndicator: true),
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.logiBlue),
                      )
                    : const Icon(Icons.refresh_rounded, size: 16, color: AppColors.logiBlue),
                label: Text(
                  _isRefreshing ? 'Syncing...' : 'Refresh',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.logiBlue,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required int index,
    required IconData icon,
    required String title,
    required int count,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.logiBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.logiBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LEFT INFO PANEL ====================

  Widget _buildLeftInfoPanel() {
    return Column(
      children: [
        // Approvers Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: AppColors.logiBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance & Approvers',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              // Level 1 Approver: Senior Tech Lead
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'AG',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Anant Gangurde',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'L1',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Senior Tech Lead • Level 1 Review',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),

              // Level 2 Approver: Engineering Manager
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDBEAFE),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'VM',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Vikram Malhotra',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'L2',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Engineering Manager • Final Approval',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppColors.logiBlue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Leave flow: Senior Lead verifies first ➔ Forwarded to Manager for final sign-off.',
                        style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // HR Policy & Helpdesk Notice Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.logiBlue),
                  const SizedBox(width: 8),
                  Text(
                    'HR Operations Desk',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Company policies and statutory holiday schedules are maintained and updated directly by HR Administration via the LogiLead Admin Portal.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF1E40AF),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFBFDBFE)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.mail_outline_rounded, size: 14, color: AppColors.logiBlue),
                  const SizedBox(width: 6),
                  Text(
                    'hr@logilead.com',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.logiBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.logiBlue),
                  const SizedBox(width: 6),
                  Text(
                    '+91 (020) 6789-0123',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E40AF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TAB 1: HOLIDAYS VIEW ====================

  Widget _buildHolidaysView() {
    // Stats calculation
    final nationalCount = _holidays.where((h) =>
        h.type.toLowerCase().contains('national') ||
        h.type.toLowerCase().contains('public')).length;
    final festivalCount = _holidays.where((h) =>
        h.type.toLowerCase().contains('festival') ||
        h.type.toLowerCase().contains('state')).length;
    final optionalCount = _holidays.length - nationalCount - festivalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row with Year Dropdown & Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Corporate Holiday Calendar',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Official declared paid holidays for all corporate and regional offices',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedYear,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  items: ['Calendar Year 2026', 'Calendar Year 2025']
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedYear = val);
                  },
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Stat Badges
        Row(
          children: [
            _buildStatBadge(
              label: 'Total Holidays',
              value: '${_holidays.length}',
              color: AppColors.logiNavy,
              icon: Icons.calendar_month_rounded,
            ),
            const SizedBox(width: 12),
            _buildStatBadge(
              label: 'National / Statutory',
              value: '$nationalCount',
              color: const Color(0xFFEF4444),
              icon: Icons.flag_rounded,
            ),
            const SizedBox(width: 12),
            _buildStatBadge(
              label: 'Festive & Cultural',
              value: '$festivalCount',
              color: const Color(0xFFF59E0B),
              icon: Icons.celebration_rounded,
            ),
            if (optionalCount > 0) ...[
              const SizedBox(width: 12),
              _buildStatBadge(
                label: 'Restricted / Optional',
                value: '$optionalCount',
                color: const Color(0xFF8B5CF6),
                icon: Icons.stars_rounded,
              ),
            ],
          ],
        ),

        const SizedBox(height: 16),

        // Holidays Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _buildTableHeaderCell('Date & Day')),
                    Expanded(flex: 5, child: _buildTableHeaderCell('Holiday Name')),
                    Expanded(flex: 3, child: _buildTableHeaderCell('Category')),
                    Expanded(flex: 2, child: _buildTableHeaderCell('Status')),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Rows
              if (_holidays.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.event_available, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          'No holidays listed for this calendar year',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Official company holidays will appear once declared by HR.',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (int i = 0; i < _holidays.length; i++) ...[
                  _buildHolidayTableRow(_holidays[i]),
                  if (i < _holidays.length - 1)
                    const Divider(height: 1, color: AppColors.borderLight),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildHolidayTableRow(HolidayEntry item) {
    // Choose icon and color based on name/type
    IconData icon = Icons.celebration_rounded;
    Color iconColor = const Color(0xFFEF4444);

    final nameLower = item.name.toLowerCase();
    if (nameLower.contains('republic') || nameLower.contains('independence') || nameLower.contains('gandhi')) {
      icon = Icons.flag_rounded;
      iconColor = const Color(0xFF0284C7);
    } else if (nameLower.contains('diwali') || nameLower.contains('padwa') || nameLower.contains('dussehra')) {
      icon = Icons.wb_sunny_rounded;
      iconColor = const Color(0xFFF59E0B);
    } else if (nameLower.contains('eid')) {
      icon = Icons.nightlight_round;
      iconColor = const Color(0xFF10B981);
    } else if (nameLower.contains('christmas')) {
      icon = Icons.park_rounded;
      iconColor = const Color(0xFF16A34A);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Date & Day
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.date,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  item.day,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          // Holiday Name + Icon
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),

          // Category Badge
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.type,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  'Upcoming',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.logiBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAB 2: POLICIES VIEW ====================

  Widget _buildPoliciesView() {
    final categories = [
      'All',
      'Attendance & Working Hours',
      'Leave & Time Off',
      'IT & Cyber Security',
      'HR & Culture',
      'Travel & Finance',
    ];

    final filtered = _filteredPolicies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Search Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Corporate Policies & Compliance Guidelines',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Official rules, workplace conduct, attendance norms, and IT policies published by LogiLead HR',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),

            // Search Bar
            SizedBox(
              width: 260,
              height: 38,
              child: TextField(
                controller: _policySearchController,
                onChanged: (val) => setState(() => _policySearchQuery = val),
                style: GoogleFonts.inter(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search policies & rules...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: _policySearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _policySearchController.clear();
                            setState(() => _policySearchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.logiBlue),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = _policyCategoryFilter.toLowerCase() == cat.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _policyCategoryFilter = cat);
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.logiNavy,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.logiNavy : AppColors.border,
                    ),
                  ),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // Policies List
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 10),
                  Text(
                    'No policies matching your filter',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try selecting a different category or clearing your search.',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: filtered.map((policy) => _buildPolicyCard(policy)).toList(),
          ),
      ],
    );
  }

  Widget _buildPolicyCard(CompanyPolicy policy) {
    Color categoryColor = const Color(0xFF0066FF);
    IconData categoryIcon = Icons.article_rounded;

    final catLower = policy.category.toLowerCase();
    if (catLower.contains('attendance')) {
      categoryColor = const Color(0xFF0284C7);
      categoryIcon = Icons.schedule_rounded;
    } else if (catLower.contains('leave')) {
      categoryColor = const Color(0xFF10B981);
      categoryIcon = Icons.time_to_leave_rounded;
    } else if (catLower.contains('it') || catLower.contains('cyber')) {
      categoryColor = const Color(0xFF6366F1);
      categoryIcon = Icons.security_rounded;
    } else if (catLower.contains('conduct') || catLower.contains('culture')) {
      categoryColor = const Color(0xFFF59E0B);
      categoryIcon = Icons.people_rounded;
    } else if (catLower.contains('travel') || catLower.contains('finance')) {
      categoryColor = const Color(0xFF8B5CF6);
      categoryIcon = Icons.account_balance_wallet_rounded;
    }

    // Split content into bullet points
    final bulletLines = policy.content
        .replaceAll(r'\n', '\n')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && (l.startsWith('•') || l.startsWith('-') || l.startsWith('*') || l.contains(':')))
        .take(4)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category pill, Version, Updated Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon, size: 14, color: categoryColor),
                          const SizedBox(width: 6),
                          Text(
                            policy.category,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        policy.version,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Updated: ${policy.updatedAt.isNotEmpty ? policy.updatedAt : 'Active'} • ${policy.updatedBy}',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Policy Title
            Text(
              policy.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),

            const SizedBox(height: 8),

            // Summary Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: categoryColor, width: 4),
                  top: const BorderSide(color: AppColors.borderLight),
                  right: const BorderSide(color: AppColors.borderLight),
                  bottom: const BorderSide(color: AppColors.borderLight),
                ),
              ),
              child: Text(
                policy.summary,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textDark,
                  height: 1.4,
                ),
              ),
            ),

            if (bulletLines.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Key Guidelines & Clauses:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              ...bulletLines.map((line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],

            const SizedBox(height: 14),

            // View Details Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      'Mandatory Employee Compliance Required',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showPolicyDetailsDialog(policy),
                  icon: const Icon(Icons.visibility_outlined, size: 16, color: AppColors.logiBlue),
                  label: Text(
                    'Read Full Policy Guidelines',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.logiBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== POLICY DETAILS MODAL ====================

  void _showPolicyDetailsDialog(CompanyPolicy policy) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 650,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.logiBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                policy.category,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.logiBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                policy.version,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          policy.title,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                'Published by: ${policy.updatedBy} • Last Revised: ${policy.updatedAt.isNotEmpty ? policy.updatedAt : 'Current'}',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
              ),
              const Divider(height: 24, color: AppColors.border),

              // Content Body
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POLICY OVERVIEW & EXECUTIVE SUMMARY',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          policy.summary,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF1E3A8A),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'FULL OPERATIONAL GUIDELINES & CLAUSES',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: policy.content
                              .replaceAll(r'\n', '\n')
                              .split('\n')
                              .map((l) => l.trim())
                              .where((l) => l.isNotEmpty)
                              .map((line) {
                            final cleanLine = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 5),
                                    child: Icon(Icons.circle, size: 5, color: AppColors.logiBlue),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      cleanLine,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: AppColors.textDark,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'All employees are required to comply with published company policies. For clarifications or accommodation requests, contact HR Operations at hr@logilead.com.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF92400E),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 24, color: AppColors.border),

              // Bottom Action
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.logiBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Close & Acknowledge',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
