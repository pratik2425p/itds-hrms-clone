import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../models/hrms_models.dart';

class RosterRecordScreen extends StatefulWidget {
  const RosterRecordScreen({super.key});

  @override
  State<RosterRecordScreen> createState() => _RosterRecordScreenState();
}

class _RosterRecordScreenState extends State<RosterRecordScreen> {
  late List<RosterDay> _days;
  String _selectedMonth = 'October-2026';

  @override
  void initState() {
    super.initState();
    _generateRoster();
  }

  void _generateRoster() {
    final parts = _selectedMonth.split('-');
    final monthName = parts[0];
    final year = int.tryParse(parts.length > 1 ? parts[1] : '2026') ?? 2026;

    final monthMap = {
      'October': 10,
      'November': 11,
      'December': 12,
    };
    final monthNumber = monthMap[monthName] ?? 10;
    final totalDays = DateTime(year, monthNumber + 1, 0).day;

    final generated = <RosterDay>[];
    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(year, monthNumber, day);
      final weekdayStr = DateFormat('EEE').format(date);
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

      generated.add(RosterDay(
        dayNumber: day,
        weekday: weekdayStr,
        shiftTime: isWeekend ? 'Weekly Off' : '10:00 AM-07:00 PM',
        isWeeklyOff: isWeekend,
      ));
    }

    setState(() {
      _days = generated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Picker Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  items: ['October-2026', 'November-2026', 'December-2026']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMonth = val);
                      _generateRoster();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Roster Cards Grid
            _days.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No Roster Schedule Published',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Shift timings and weekly offs for $_selectedMonth will be displayed here.',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: _days.map((day) => _buildRosterCard(day)).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildRosterCard(RosterDay day) {
    final isOff = day.isWeeklyOff;
    final primaryColor = isOff ? AppColors.weeklyOffOrange : const Color(0xFF059669);

    return Container(
      width: 175,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryColor, width: 1.2),
      ),
      child: Row(
        children: [
          // Left Day Indicator
          Container(
            width: 52,
            height: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.dayNumber.toString().padLeft(2, '0'),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  day.weekday,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          // Right Shift Description
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: Text(
                  day.shiftTime,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
