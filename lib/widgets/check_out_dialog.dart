import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/attendance_tracker_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class CheckOutDialog extends StatefulWidget {
  final VoidCallback onCheckedOut;

  const CheckOutDialog({super.key, required this.onCheckedOut});

  @override
  State<CheckOutDialog> createState() => _CheckOutDialogState();
}

class _CheckOutDialogState extends State<CheckOutDialog> {
  final _remarksController = TextEditingController();
  final _tracker = AttendanceTrackerService();
  bool _isLoading = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final outTimeStr = DateFormat('hh:mm a').format(now);
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final workingHrs = '${_tracker.elapsedDurationStr.substring(0, 5)} Hrs';

      final empCode = AuthService().employeeCode;

      await _tracker.checkOut(
        employeeCode: empCode,
        outTime: outTimeStr,
        dateStr: dateStr,
        workingHours: workingHrs,
      );

      if (mounted) {
        widget.onCheckedOut();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checked out successfully at $outTimeStr! Total time: $workingHrs'),
            backgroundColor: AppColors.presentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during check-out: $e'),
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
    final now = DateTime.now();
    final outTimeStr = DateFormat('hh:mm a').format(now);
    final inTimeStr = _tracker.inTime ?? '--:--';
    final timerStr = _tracker.elapsedDurationStr;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
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
                          color: AppColors.absentRed.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout, color: AppColors.absentRed, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Confirm Check-Out',
                        style: GoogleFonts.inter(
                          fontSize: 17,
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
                'Are you sure you want to end your shift for today?',
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),

              // Time Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Check-In Time:', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        Text(inTimeStr, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.presentGreen)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Check-Out Time (Now):', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        Text(outTimeStr, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryOrange)),
                      ],
                    ),
                    const Divider(height: 16, color: AppColors.borderLight),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Working Time:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                        Text(
                          timerStr,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0D9488)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Work Notes / Handover remarks
              Text(
                'Daily Work Notes / Handover (Optional)',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _remarksController,
                  maxLines: 2,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Brief summary of today tasks completed...',
                    hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                    contentPadding: const EdgeInsets.all(12),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
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
                      backgroundColor: AppColors.absentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isLoading ? null : _handleCheckOut,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Confirm Check Out',
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
}
