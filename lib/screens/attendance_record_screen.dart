import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';
import '../models/hrms_models.dart';
import '../widgets/regularize_attendance_dialog.dart';

class AttendanceRecordScreen extends StatefulWidget {
  const AttendanceRecordScreen({super.key});

  @override
  State<AttendanceRecordScreen> createState() => _AttendanceRecordScreenState();
}

class _AttendanceRecordScreenState extends State<AttendanceRecordScreen> {
  List<AttendanceRow> _rows = [];
  String _selectedMonth = 'October-2026';
  bool _isLoading = false;

  void _openRegularizationDialog([String? date]) {
    showDialog(
      context: context,
      builder: (ctx) => RegularizeAttendanceDialog(
        initialDate: date,
        onSubmitted: _loadAttendance,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  double get _presentDaysCount => _rows.where((r) => r.status.toLowerCase().contains('present')).length.toDouble();
  double get _weeklyOffCount => _rows.where((r) => r.status.toLowerCase().contains('weekly')).length.toDouble();
  double get _absentDaysCount => _rows.where((r) => r.status.toLowerCase().contains('absent')).length.toDouble();

  String get _totalWorkedHoursStr {
    int totalMinutes = 0;
    for (final r in _rows) {
      final parts = r.workingHrs.split(':');
      if (parts.length == 2) {
        final hrs = int.tryParse(parts[0]) ?? 0;
        final mins = int.tryParse(parts[1]) ?? 0;
        totalMinutes += hrs * 60 + mins;
      }
    }
    final hrs = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    return '${hrs.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    try {
      final empCode = AuthService().employeeCode.isNotEmpty ? AuthService().employeeCode : 'HRC06';
      final entries = await ServerpodService().getAttendanceHistory(employeeCode: empCode);
      if (!mounted) return;
      setState(() {
        _rows = entries.map((e) {
          final isPresent = e.status.toLowerCase() == 'present';
          final isWeeklyOff = e.status.toLowerCase().contains('weekly');
          return AttendanceRow(
            status: e.status,
            date: e.date,
            inTime: e.inTime ?? '',
            outTime: e.outTime ?? '',
            workingHrs: e.workingHours ?? '00:00',
            statusColor: isPresent
                ? AppColors.presentGreen
                : isWeeklyOff
                    ? AppColors.weeklyOffOrange
                    : AppColors.absentRed,
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading attendance: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
            // Top: Chart + Summary Card
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Present Days Bar Chart
                Expanded(
                  flex: 6,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Present Days',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const Icon(Icons.menu, size: 18, color: AppColors.textMuted),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Bar Chart Visualization
                        _buildBarChart(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Right: October 2026 Summary
                Expanded(
                  flex: 4,
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
                        Row(
                          children: [
                            Text(
                              'October 2026 Summary',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                          ],
                        ),
                        _buildSummaryItem('Present Days', _presentDaysCount.toStringAsFixed(1), AppColors.presentGreen),
                        _buildSummaryItem('Absent Days', _absentDaysCount.toStringAsFixed(1), AppColors.absentRed),
                        _buildSummaryItem('Invalid Days', '0.0', AppColors.textDark),
                        _buildSummaryItem('Approved Leaves', '0.0', AppColors.leavesBlue),
                        _buildSummaryItem('Holidays', '0.0', AppColors.weeklyOffOrange),
                        _buildSummaryItem('Weekly Off', _weeklyOffCount.toStringAsFixed(1), AppColors.weeklyOffOrange),
                        _buildSummaryItem('Early Mark/Late Mark', '0/0', AppColors.textDark),
                        const Divider(height: 16, color: AppColors.borderLight),
                        _buildSummaryItem('Total Worked Hours', _totalWorkedHoursStr, const Color(0xFF0D9488), isBold: true),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Attendance Details Table Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: AppColors.primaryOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Attendance Details',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'click here to view attendance prior to August 2023',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.primaryOrange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          isDense: true,
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.textMuted),
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                          items: ['October-2026', 'September-2026', 'August-2026']
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMonth = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.logiBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () => _openRegularizationDialog(),
                      icon: const Icon(Icons.alarm_add_rounded, size: 16),
                      label: Text('Regularize Attendance', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading Attendance Log...')),
                        );
                      },
                      child: Text('Download', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Comprehensive Table
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primaryOrange),
                      ),
                    )
                  : _rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                          child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.history_toggle_off, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No Attendance Logs Found',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Daily check-in and check-out records for $_selectedMonth will be recorded here.',
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: [
                          _buildDataColumn('Date'),
                          _buildDataColumn('Check In'),
                          _buildDataColumn('Check Out'),
                          _buildDataColumn('Working Hrs.'),
                          _buildDataColumn('Deviation Hrs.'),
                          _buildDataColumn('Break Hrs.'),
                          _buildDataColumn('Late/Early Mark'),
                          _buildDataColumn('Status'),
                          _buildDataColumn('Shift Time'),
                          _buildDataColumn('Reg. Status'),
                          _buildDataColumn('Action'),
                        ],
                        rows: _rows.map((row) {
                          return DataRow(
                            cells: [
                              DataCell(Text(row.date, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500))),
                              DataCell(Text(row.inTime.isEmpty ? '-' : row.inTime, style: GoogleFonts.inter(fontSize: 12))),
                              DataCell(Text(row.outTime.isEmpty ? '-' : row.outTime, style: GoogleFonts.inter(fontSize: 12))),
                              DataCell(Text(row.workingHrs, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                              DataCell(Text(row.deviationHrs, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                              DataCell(Text(row.breakHrs, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                              DataCell(Text(row.lateMark, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                              DataCell(
                                Text(
                                  row.status,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: row.statusColor,
                                  ),
                                ),
                              ),
                              DataCell(Text(row.shiftTime, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                              DataCell(Text(row.regStatus, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted))),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.menu, size: 16, color: AppColors.textMuted),
                                      onPressed: () => _openRegularizationDialog(row.date),
                                      tooltip: 'Details',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.alarm_add_rounded, size: 16, color: AppColors.primaryOrange),
                                      onPressed: () => _openRegularizationDialog(row.date),
                                      tooltip: 'Regularize ${row.date}',
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final bars = [
      {'month': 'Jul-26', 'val': 24.0},
      {'month': 'Aug-26', 'val': 22.5},
      {'month': 'Sep-26', 'val': 20.5},
      {'month': 'Oct-26', 'val': 16.5},
    ];

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          // Y Axis Labels
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: ['25.0', '20.0', '15.0', '10.0', '5.0', '0.0']
                .map((e) => Text(e, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textLight)))
                .toList(),
          ),
          const SizedBox(width: 12),
          // Chart area with horizontal grid lines and vertical bars
          Expanded(
            child: Stack(
              children: [
                // Grid lines
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    6,
                    (index) => Container(height: 1, color: AppColors.borderLight),
                  ),
                ),
                // Bars
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: bars.map((b) {
                      final double heightFactor = (b['val'] as double) / 25.0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 32,
                            height: 160 * heightFactor,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                topRight: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b['month'] as String,
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
