import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _currentMonth = DateTime(2026, 10, 1);
  List<HolidayEntry> _allHolidays = [];
  List<EmployeeRecord> _allEmployees = [];

  @override
  void initState() {
    super.initState();
    _loadEventsData();
  }

  Future<void> _loadEventsData() async {
    try {
      final holidaysFuture = ServerpodService().getHolidays();
      final employeesFuture = ServerpodService().getEmployees();

      final results = await Future.wait([holidaysFuture, employeesFuture]);
      if (mounted) {
        setState(() {
          _allHolidays = results[0] as List<HolidayEntry>;
          _allEmployees = results[1] as List<EmployeeRecord>;
        });
      }
    } catch (e) {
      debugPrint('Error loading calendar data: $e');
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  int get _monthHolidaysCount {
    return _allHolidays.where((h) {
      final parts = h.date.split('-');
      if (parts.length >= 2) {
        final monthStr = parts[1].toLowerCase();
        final currentMonthNames = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
        final currentAbbr = currentMonthNames[_currentMonth.month - 1];
        if (monthStr.startsWith(currentAbbr) || parts[1] == _currentMonth.month.toString().padLeft(2, '0')) {
          return true;
        }
      }
      return false;
    }).length;
  }

  int get _monthBirthdaysCount {
    // Sneha Kulkarni's birthday is celebrated in October
    int count = 0;
    for (final e in _allEmployees) {
      if (e.name.toLowerCase().contains('sneha') && _currentMonth.month == 10) {
        count++;
      }
    }
    return count;
  }

  int get _monthAnniversariesCount {
    return _allEmployees.where((e) {
      final joined = e.joinedOn;
      if (joined != null && joined.isNotEmpty) {
        final parts = joined.split('-');
        if (parts.length >= 2) {
          final m = int.tryParse(parts[1]);
          if (m == _currentMonth.month) return true;
        }
      }
      return false;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthStr = '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Events Breakdown Card
            Container(
              width: 260,
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
                        const Icon(Icons.calendar_month, size: 18, color: AppColors.primaryOrange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$monthStr Events',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  _buildEventStatItem(
                    icon: Icons.cake_outlined,
                    iconBg: const Color(0xFFFED7AA),
                    iconColor: AppColors.primaryOrange,
                    title: 'Birthday',
                    count: _monthBirthdaysCount.toString(),
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildEventStatItem(
                    icon: Icons.card_giftcard,
                    iconBg: const Color(0xFFC7D2FE),
                    iconColor: const Color(0xFF4F46E5),
                    title: 'Work Anniversary',
                    count: _monthAnniversariesCount.toString(),
                  ),
                  const Divider(height: 1, color: AppColors.borderLight),
                  _buildEventStatItem(
                    icon: Icons.beach_access,
                    iconBg: const Color(0xFFBAE6FD),
                    iconColor: const Color(0xFF0284C7),
                    title: 'Company Holidays',
                    count: _monthHolidaysCount.toString(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Right Column: Full Month Calendar
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month Navigation Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          monthStr,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        Row(
                          children: [
                            _buildNavArrow(Icons.chevron_left, _previousMonth),
                            const SizedBox(width: 8),
                            _buildNavArrow(Icons.chevron_right, _nextMonth),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Calendar Grid Table
                    _buildDynamicCalendarGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Center(
          child: Icon(icon, size: 20, color: AppColors.textDark),
        ),
      ),
    );
  }

  Widget _buildEventStatItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String count,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicCalendarGrid() {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final year = _currentMonth.year;
    final month = _currentMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final prevMonthLastDay = DateTime(year, month, 0).day;
    final now = DateTime.now();

    final cells = <Widget>[];

    // Previous month filler days
    for (int i = startingWeekday - 1; i >= 0; i--) {
      final d = prevMonthLastDay - i;
      cells.add(_buildCalendarCell(d.toString(), isFaded: true));
    }

    // Current month days
    for (int d = 1; d <= daysInMonth; d++) {
      final isToday = (now.year == year && now.month == month && now.day == d);
      final pills = <Widget>[];

      // Check for holiday
      for (final h in _allHolidays) {
        final parts = h.date.split('-');
        if (parts.isNotEmpty && int.tryParse(parts[0]) == d) {
          final monthStr = parts.length > 1 ? parts[1].toLowerCase() : '';
          final currentAbbr = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'][month - 1];
          if (monthStr.startsWith(currentAbbr) || (parts.length > 1 && parts[1] == month.toString().padLeft(2, '0'))) {
            pills.add(
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  h.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
                ),
              ),
            );
          }
        }
      }

      // Check for birthday in October
      if (month == 10 && d == 24) {
        pills.add(
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '🎂 Sneha Kulkarni',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.logiBlue),
            ),
          ),
        );
      }

      cells.add(_buildCalendarCell(d.toString(), isToday: isToday, eventPills: pills));
    }

    // Next month filler days to complete rows
    final totalCells = cells.length;
    final remaining = (7 - (totalCells % 7)) % 7;
    for (int d = 1; d <= remaining; d++) {
      cells.add(_buildCalendarCell(d.toString(), isFaded: true));
    }

    // Group into rows of 7
    final tableRows = <TableRow>[];

    // Header Row
    tableRows.add(
      TableRow(
        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
        children: weekdays.map((day) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                day,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    for (int i = 0; i < cells.length; i += 7) {
      tableRows.add(TableRow(children: cells.sublist(i, i + 7)));
    }

    return Table(
      border: TableBorder.all(color: AppColors.borderLight, width: 1),
      children: tableRows,
    );
  }

  Widget _buildCalendarCell(
    String dayNumber, {
    bool isFaded = false,
    bool isToday = false,
    List<Widget>? eventPills,
  }) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(6),
      color: isToday ? const Color(0xFFFEF9C3) : Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Text(
              dayNumber,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isFaded ? AppColors.textLight : AppColors.textDark,
              ),
            ),
          ),
          if (eventPills != null && eventPills.isNotEmpty) ...[
            const SizedBox(height: 2),
            ...eventPills,
          ],
        ],
      ),
    );
  }
}
