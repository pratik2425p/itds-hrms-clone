import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ProfileMenuPopup extends StatelessWidget {
  final VoidCallback onSignOut;
  final VoidCallback onNotificationSettings;
  final VoidCallback onHelpCenter;

  const ProfileMenuPopup({
    super.key,
    required this.onSignOut,
    required this.onNotificationSettings,
    required this.onHelpCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            icon: Icons.notifications_none,
            title: 'Notification Settings',
            onTap: onNotificationSettings,
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help Center',
            onTap: onHelpCenter,
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: onSignOut,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isDestructive ? AppColors.absentRed : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDestructive ? AppColors.absentRed : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
