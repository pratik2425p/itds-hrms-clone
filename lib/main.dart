import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme/app_colors.dart';
import 'models/hrms_models.dart';
import 'services/auth_service.dart';
import 'services/attendance_tracker_service.dart';
import 'widgets/sidebar_navigation.dart';
import 'widgets/header_banner.dart';
import 'widgets/mark_attendance_dialog.dart';
import 'widgets/check_out_dialog.dart';
import 'widgets/profile_menu_popup.dart';
import 'widgets/apply_leave_dialog.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/employee_directory_screen.dart';
import 'screens/employee_profile_screen.dart';
import 'screens/attendance_record_screen.dart';
import 'screens/roster_record_screen.dart';
import 'screens/general_info_screen.dart';
import 'screens/leave_applications_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/approvals_screen.dart';
import 'screens/my_payslip_screen.dart';
import 'screens/ticketing_screen.dart';

void main() {
  runApp(const LogiLeadPortalApp());
}

typedef QuikchexPortalApp = LogiLeadPortalApp;

class LogiLeadPortalApp extends StatefulWidget {
  const LogiLeadPortalApp({super.key});

  @override
  State<LogiLeadPortalApp> createState() => _LogiLeadPortalAppState();
}

class _LogiLeadPortalAppState extends State<LogiLeadPortalApp> {
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LogiLead - Workforce & Logistics Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryOrange,
          primary: AppColors.primaryOrange,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: _authService.isLoggedIn
          ? const MainPortalScreen()
          : LoginScreen(onLoginSuccess: () => setState(() {})),
    );
  }
}

class MainPortalScreen extends StatefulWidget {
  const MainPortalScreen({super.key});

  @override
  State<MainPortalScreen> createState() => _MainPortalScreenState();
}

class _MainPortalScreenState extends State<MainPortalScreen> {
  int _selectedNavIndex = 0;
  bool _isProfileMenuOpen = false;
  Employee? _selectedProfileEmployee;

  @override
  void initState() {
    super.initState();
    AttendanceTrackerService().initTodayAttendance(AuthService().employeeCode);
  }

  void _onNavigate(int index) {
    setState(() {
      _selectedNavIndex = index;
      _isProfileMenuOpen = false;
    });
  }

  void _showMarkAttendanceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => MarkAttendanceDialog(
        onAttendanceMarked: () {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance marked successfully for today!'),
              backgroundColor: AppColors.presentGreen,
            ),
          );
        },
      ),
    );
  }

  void _showCheckOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CheckOutDialog(
        onCheckedOut: () {
          setState(() {});
        },
      ),
    );
  }

  void _showApplyLeaveDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ApplyLeaveDialog(
        onSubmitted: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave application submitted for approval!'),
              backgroundColor: AppColors.primaryOrange,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Stack(
        children: [
          Row(
            children: [
              // Enterprise Sidebar Navigation
              SidebarNavigation(
                selectedIndex: _selectedNavIndex,
                onDestinationSelected: _onNavigate,
              ),

              // Main Application View
              Expanded(
                child: Column(
                  children: [
                    // Dynamic Modern Header
                    _buildHeaderBanner(),

                    // Screen Body
                    Expanded(
                      child: _buildCurrentScreen(),
                    ),

                    // Bottom Footer with Copyright
                    _buildFooter(),
                  ],
                ),
              ),
            ],
          ),

          // Profile Menu Dropdown Overlay
          if (_isProfileMenuOpen)
            Positioned(
              top: 64,
              right: 24,
              child: ProfileMenuPopup(
                onSignOut: () {
                  setState(() => _isProfileMenuOpen = false);
                  AuthService().logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                },
                onNotificationSettings: () {
                  setState(() => _isProfileMenuOpen = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification Settings opened')),
                  );
                },
                onHelpCenter: () {
                  setState(() => _isProfileMenuOpen = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help Center opened')),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    switch (_selectedNavIndex) {
      case 0:
        return HeaderBanner(
          title: 'Welcome, ${AuthService().displayName}',
          isDashboard: true,
          onMarkAttendance: _showMarkAttendanceDialog,
          onCheckOut: _showCheckOutDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () {
            setState(() {
              _isProfileMenuOpen = !_isProfileMenuOpen;
            });
          },
        );
      case 1:
        return HeaderBanner(
          title: 'Approvals & Requests',
          subtitle: 'Review team approval requests and notifications.',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 2:
        return HeaderBanner(
          title: 'Employee Directory',
          subtitle: 'Employee personal details are noted under this section.',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 3:
        return HeaderBanner(
          title: 'Employee Profile',
          subtitle: 'Employee details can be mentioned under this section.',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 4:
        return HeaderBanner(
          title: 'Milestones & Celebrations',
          subtitle: 'Celebrate company achievements, birthdays, and work anniversaries.',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 5:
        return HeaderBanner(
          title: 'Roster Record',
          subtitle: 'Employee Roster records must be noted under this section',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 6:
        return HeaderBanner(
          title: 'Attendance Record',
          subtitle: 'Employee Attendance records must be noted under this section',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 7:
        return HeaderBanner(
          title: 'Holidays & Company Policies',
          subtitle: 'Official corporate holidays, rules, and workplace policies published by LogiLead HR Operations',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 8:
        return HeaderBanner(
          title: 'My Leave Applications',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 9:
        return HeaderBanner(
          title: 'Calendar',
          subtitle: 'Comprehensive Calendar View of Company-Wide Events',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 10:
        return HeaderBanner(
          title: 'My Salary & Payslips',
          subtitle: 'Monthly Compensation Breakdown & Official Payslip Vouchers',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      case 11:
        return HeaderBanner(
          title: 'ITD Case Management & Ticketing',
          subtitle: 'Intelligent Technology Development • End-to-End Resolution Workflow & Activity Timers',
          onBack: () => _onNavigate(0),
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
      default:
        return HeaderBanner(
          title: 'Dashboard',
          isDashboard: true,
          onMarkAttendance: _showMarkAttendanceDialog,
          onRequestLeave: _showApplyLeaveDialog,
          onRegularization: () => _onNavigate(6),
          onManageProfile: () => _onNavigate(3),
          onProfileTap: () => setState(() => _isProfileMenuOpen = !_isProfileMenuOpen),
        );
    }
  }

  Widget _buildCurrentScreen() {
    switch (_selectedNavIndex) {
      case 0:
        return DashboardScreen(
          onNavigateToScreen: _onNavigate,
          onOpenLeaveDialog: _showApplyLeaveDialog,
        );
      case 1:
        return ApprovalsScreen(onBack: () => _onNavigate(0));
      case 2:
        return EmployeeDirectoryScreen(
          onSelectEmployeeForProfile: (emp) {
            setState(() {
              _selectedProfileEmployee = emp;
              _selectedNavIndex = 3;
            });
          },
        );
      case 3:
        return EmployeeProfileScreen(employee: _selectedProfileEmployee);
      case 4:
        return const CalendarScreen();
      case 5:
        return const RosterRecordScreen();
      case 6:
        return const AttendanceRecordScreen();
      case 7:
        return const GeneralInfoScreen();
      case 8:
        return LeaveApplicationsScreen(onOpenApplyLeave: _showApplyLeaveDialog);
      case 9:
        return const CalendarScreen();
      case 10:
        return const MyPayslipScreen();
      case 11:
        return TicketingScreen(currentUserCode: AuthService().employeeCode);
      default:
        return DashboardScreen(
          onNavigateToScreen: _onNavigate,
          onOpenLeaveDialog: _showApplyLeaveDialog,
        );
    }
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'LOGILEAD ENTERPRISE WORKFORCE INTELLIGENCE • ALL RIGHTS RESERVED © 2026',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.presentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Live Cloud Sync Connected • v2.5.0',
                style: GoogleFonts.poppins(
                  fontSize: 10,
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
}
