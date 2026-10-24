import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';

class SidebarNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const SidebarNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(
          right: BorderSide(color: AppColors.sidebarBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enterprise Brand Header
          _buildBrandHeader(),

          const Divider(height: 1, color: AppColors.sidebarBorder),

          // Categorized Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildSectionLabel('CORE WORKSPACE'),
                _buildNavItem(
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  title: 'Dashboard',
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.fact_check_rounded,
                  title: 'Approvals & Requests',
                  hasBadge: true,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.badge_rounded,
                  title: 'Employee Directory',
                ),
                _buildNavItem(
                  index: 11,
                  icon: Icons.confirmation_number_rounded,
                  title: 'Office Ticketing',
                  hasBadge: true,
                ),

                const SizedBox(height: 16),
                _buildSectionLabel('TIME & ATTENDANCE'),
                _buildNavItem(
                  index: 6,
                  icon: Icons.access_time_filled_rounded,
                  title: 'Attendance Record',
                ),
                _buildNavItem(
                  index: 5,
                  icon: Icons.calendar_view_week_rounded,
                  title: 'Roster Record',
                ),

                const SizedBox(height: 16),
                _buildSectionLabel('LEAVE & COMPENSATION'),
                _buildNavItem(
                  index: 8,
                  icon: Icons.event_busy_rounded,
                  title: 'Leave Applications',
                ),
                _buildNavItem(
                  index: 9,
                  icon: Icons.calendar_month_rounded,
                  title: 'Company Calendar',
                ),
                _buildNavItem(
                  index: 10,
                  icon: Icons.receipt_long_rounded,
                  title: 'My Payslips',
                ),

                const SizedBox(height: 16),
                _buildSectionLabel('ORGANIZATION & PROFILE'),
                _buildNavItem(
                  index: 3,
                  icon: Icons.person_rounded,
                  title: 'Employee Profile',
                ),
                _buildNavItem(
                  index: 7,
                  icon: Icons.menu_book_rounded,
                  title: 'Holidays & Policies',
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.celebration_rounded,
                  title: 'Milestones & Events',
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.sidebarBorder),

          // User Profile Mini Card
          _buildUserProfileFooter(context),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LogiLead',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2D4A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'WORKFORCE PORTAL',
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF38BDF8),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 4, bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String title,
    bool hasBadge = false,
  }) {
    final isSelected = selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onDestinationSelected(index),
          borderRadius: BorderRadius.circular(8),
          hoverColor: const Color(0xFF132240),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasBadge)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF38BDF8),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileFooter(BuildContext context) {
    final auth = AuthService();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: const Color(0xFF070E20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Center(
              child: Text(
                auth.initials,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  auth.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  auth.employeeCode.isNotEmpty ? auth.employeeCode : 'Employee',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF94A3B8)),
            tooltip: 'Sign Out',
            onPressed: () {
              auth.logout();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out successfully')),
              );
            },
          ),
        ],
      ),
    );
  }
}
