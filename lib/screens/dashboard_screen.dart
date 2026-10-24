import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import 'package:intl/intl.dart';
import '../services/attendance_tracker_service.dart';
import '../services/auth_service.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';
import '../models/hrms_models.dart';
import '../models/ticket_models.dart';
import 'ticket_detail_dialog.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int> onNavigateToScreen;
  final VoidCallback onOpenLeaveDialog;

  const DashboardScreen({
    super.key,
    required this.onNavigateToScreen,
    required this.onOpenLeaveDialog,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<FeedItem> _feeds;
  late List<AttendanceRow> _dashboardAttendance;
  final List<LeaveSummary> _leaveSummaries = [];
  List<ClientTicket> _recentTickets = [];
  List<HolidayEntry> _upcomingHolidays = [];
  final _postContentController = TextEditingController();
  bool _isPostingFeed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _feeds = [];
    _dashboardAttendance = [];
    _loadLiveBackendData();
  }

  @override
  void dispose() {
    _postContentController.dispose();
    super.dispose();
  }

  Future<void> _loadLiveBackendData() async {
    setState(() => _isLoading = true);
    try {
      final serverpod = ServerpodService();
      final empCode = AuthService().employeeCode;

      // Feeds
      final feeds = await serverpod.getFeeds();
      if (feeds.isNotEmpty) {
        _feeds = feeds
            .map((f) => FeedItem(
                  id: f.id?.toString() ?? '',
                  author: f.author,
                  authorInitials: f.authorInitials,
                  avatarBg: AppColors.primary,
                  postedTime: f.postedTime,
                  content: f.content,
                  likes: f.likes,
                  comments: f.comments,
                  isLiked: false,
                ))
            .toList();
      }

      // Attendance
      final attendance = await serverpod.getAttendanceHistory(employeeCode: empCode);
      if (attendance.isNotEmpty) {
        _dashboardAttendance = attendance.take(5).map((e) {
          final isPresent = e.status.toLowerCase() == 'present';
          return AttendanceRow(
            status: e.status,
            date: e.date,
            inTime: e.inTime ?? '--:--',
            outTime: e.outTime ?? '--:--',
            workingHrs: e.workingHours ?? '00:00',
            statusColor: isPresent ? AppColors.presentGreen : AppColors.absentRed,
          );
        }).toList();
      }

      // Leave Summaries
      final leaveSummaries = await serverpod.getLeaveSummaries(employeeCode: empCode);
      if (leaveSummaries.isNotEmpty) {
        _leaveSummaries.clear();
        _leaveSummaries.addAll(leaveSummaries);
      }

      // Holidays
      final holidays = await serverpod.getHolidays();
      if (holidays.isNotEmpty) {
        _upcomingHolidays = holidays.take(3).toList();
      }

      // Tickets
      final tickets = await serverpod.getTickets();
      if (tickets.isNotEmpty) {
        _recentTickets = tickets.take(3).toList();
      }
    } catch (e) {
      debugPrint('Error loading dashboard backend data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRemainingLeave(String type, {String defaultVal = '0.0'}) {
    try {
      final found = _leaveSummaries.firstWhere(
        (s) => s.category.toLowerCase().contains(type.toLowerCase()),
      );
      return found.remaining.toStringAsFixed(1);
    } catch (_) {
      return defaultVal;
    }
  }

  Future<void> _submitAnnouncement() async {
    final text = _postContentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPostingFeed = true);
    try {
      final now = DateTime.now();
      final timeStr = 'Today at ${DateFormat('hh:mm a').format(now)}';
      final author = AuthService().displayName;
      final initials = AuthService().initials;

      final newFeed = await ServerpodService().postFeed(
        author: author,
        authorInitials: initials,
        content: text,
        postedTime: timeStr,
      );

      _postContentController.clear();
      if (mounted) {
        setState(() {
          _feeds.insert(
            0,
            FeedItem(
              id: newFeed.id?.toString() ?? '',
              author: newFeed.author,
              authorInitials: newFeed.authorInitials,
              avatarBg: AppColors.primary,
              postedTime: newFeed.postedTime,
              content: newFeed.content,
              likes: newFeed.likes,
              comments: newFeed.comments,
              isLiked: false,
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Error posting feed: $e');
    } finally {
      if (mounted) setState(() => _isPostingFeed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final tracker = AttendanceTrackerService();
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, y').format(now);

    if (_isLoading) {
      return Container(
        color: AppColors.scaffoldBg,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      color: AppColors.scaffoldBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Simple, Clean Greeting Card
            _buildWelcomeBanner(auth, tracker, dateStr),

            const SizedBox(height: 20),

            // 2. 3 Clean, Uncluttered Metric Cards
            _buildKeyMetricsRow(tracker),

            const SizedBox(height: 24),

            // 3. Simple Two-Column Layout (Attendance & Tickets on Left | Quick Actions & Bulletins on Right)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 950;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Recent Activity & Tickets
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAttendanceCard(),
                            const SizedBox(height: 20),
                            _buildActiveTicketsCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column: Quick Actions & Holidays & Feeds
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildQuickActionsCard(),
                            const SizedBox(height: 20),
                            _buildUpcomingHolidaysCard(),
                            const SizedBox(height: 20),
                            _buildCompanyBulletinsCard(),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildQuickActionsCard(),
                      const SizedBox(height: 20),
                      _buildAttendanceCard(),
                      const SizedBox(height: 20),
                      _buildActiveTicketsCard(),
                      const SizedBox(height: 20),
                      _buildUpcomingHolidaysCard(),
                      const SizedBox(height: 20),
                      _buildCompanyBulletinsCard(),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. WELCOME BANNER ---
  Widget _buildWelcomeBanner(AuthService auth, AttendanceTrackerService tracker, String dateStr) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary,
            child: Text(
              auth.initials,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hello, ${auth.displayName} 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        auth.role.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$dateStr • Employee Code: ${auth.employeeCode}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Shift Punch Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: tracker.isCheckedIn ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: tracker.isCheckedIn ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  tracker.isCheckedIn ? Icons.check_circle : Icons.schedule,
                  size: 16,
                  color: tracker.isCheckedIn ? AppColors.presentGreen : const Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
                Text(
                  tracker.isCheckedIn
                      ? (tracker.isCheckedOut ? 'Shift Done (${tracker.workingHours})' : 'Punched In (${tracker.inTime})')
                      : 'Not Punched In',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tracker.isCheckedIn ? const Color(0xFF166534) : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. 3 CLEAN METRIC CARDS ---
  Widget _buildKeyMetricsRow(AttendanceTrackerService tracker) {
    return Row(
      children: [
        // Attendance Card
        Expanded(
          child: _buildSimpleMetricCard(
            icon: Icons.access_time_rounded,
            color: AppColors.primary,
            title: 'Today Shift Log',
            value: tracker.isCheckedIn ? (tracker.inTime ?? '09:30 AM') : '09:30 AM - 06:30 PM',
            subtitle: tracker.isCheckedIn
                ? 'Duration: ${tracker.workingHours ?? tracker.elapsedDurationStr}'
                : 'General Schedule',
            actionText: 'View History',
            onTap: () => widget.onNavigateToScreen(6),
          ),
        ),
        const SizedBox(width: 16),
        // Leaves Available
        Expanded(
          child: _buildSimpleMetricCard(
            icon: Icons.beach_access_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Available Leaves',
            value: '${_getRemainingLeave("Casual", defaultVal: "12")} CL/SL • ${_getRemainingLeave("Earned", defaultVal: "3")} EL',
            subtitle: 'Annual quota & half-day eligible',
            actionText: 'Apply Leave',
            onTap: widget.onOpenLeaveDialog,
          ),
        ),
        const SizedBox(width: 16),
        // Office Tickets
        Expanded(
          child: _buildSimpleMetricCard(
            icon: Icons.confirmation_number_rounded,
            color: const Color(0xFF0D9488),
            title: 'Office Ticketing',
            value: '${_recentTickets.length} Active Tickets',
            subtitle: 'Client support & issue tracking',
            actionText: 'Go to Tickets',
            onTap: () => widget.onNavigateToScreen(11),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleMetricCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onTap,
                child: Text(
                  actionText,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. RECENT ATTENDANCE CARD ---
  Widget _buildAttendanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Recent Attendance Records',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => widget.onNavigateToScreen(6),
                child: Text(
                  'View All ➔',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_dashboardAttendance.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No attendance entries recorded yet.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            )
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
                4: FlexColumnWidth(1.8),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
                  ),
                  children: [
                    _tableHeader('DATE'),
                    _tableHeader('IN TIME'),
                    _tableHeader('OUT TIME'),
                    _tableHeader('WORKING HRS'),
                    _tableHeader('STATUS'),
                  ],
                ),
                ..._dashboardAttendance.map((row) => TableRow(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC), width: 1)),
                      ),
                      children: [
                        _tableCell(row.date, isBold: true),
                        _tableCell(row.inTime),
                        _tableCell(row.outTime),
                        _tableCell(row.workingHrs),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: row.statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                row.status.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: row.statusColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tableHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  // --- 4. ACTIVE TICKETS CARD ---
  Widget _buildActiveTicketsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 18, color: Color(0xFF0D9488)),
              const SizedBox(width: 8),
              Text(
                'Recent Office Tickets',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => widget.onNavigateToScreen(11),
                child: Text(
                  'Manage All ➔',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentTickets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No client tickets generated yet.',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTickets.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (ctx, i) {
                final t = _recentTickets[i];
                return InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => TicketDetailDialog(
                        ticketId: t.id,
                        onTicketUpdated: _loadLiveBackendData,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.priorityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.ticketNumber,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: t.priorityColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Text(
                                'Client: ${t.clientName} • Stage: ${t.currentStageName}',
                                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: t.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            t.humanStatus,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: t.statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- 5. QUICK ACTIONS CARD ---
  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Operations',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.event_note,
                  label: 'Apply Leave',
                  color: AppColors.primary,
                  onTap: widget.onOpenLeaveDialog,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Tickets',
                  color: const Color(0xFF0D9488),
                  onTap: () => widget.onNavigateToScreen(11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history,
                  label: 'Regularize',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => widget.onNavigateToScreen(6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.policy_outlined,
                  label: 'Policies',
                  color: const Color(0xFFD97706),
                  onTap: () => widget.onNavigateToScreen(7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. UPCOMING HOLIDAYS CARD ---
  Widget _buildUpcomingHolidaysCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration_outlined, size: 18, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text(
                'Upcoming Company Holidays',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_upcomingHolidays.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No upcoming holidays this month.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            ..._upcomingHolidays.map((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          h.date,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h.name,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              h.type,
                              style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // --- 7. COMPANY BULLETINS CARD ---
  Widget _buildCompanyBulletinsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Company Announcements',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Post Quick Message
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _postContentController,
                  decoration: InputDecoration(
                    hintText: 'Share a note with your team...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isPostingFeed ? null : _submitAnnouncement,
                icon: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_feeds.isEmpty)
            Text(
              'No posts yet.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
            )
          else
            ..._feeds.take(2).map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                f.authorInitials,
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              f.author,
                              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            ),
                            const Spacer(),
                            Text(
                              f.postedTime,
                              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          f.content,
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textBody, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}
