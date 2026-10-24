import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hrms_client/hrms_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import '../models/company_policy.dart';
import '../models/ticket_models.dart';

class ServerpodService {
  static final ServerpodService _instance = ServerpodService._internal();
  factory ServerpodService() => _instance;

  late Client client;
  bool _initialized = false;

  ServerpodService._internal() {
    init();
  }

  void init() {
    if (_initialized) return;
    client = Client(
      'http://localhost:8080/',
    )..connectivityMonitor = kIsWeb ? null : FlutterConnectivityMonitor();
    _initialized = true;
  }

  // ==================== AUTHENTICATION ====================

  Future<AuthResponse> login({
    required String emailOrCode,
    required String password,
  }) async {
    return await client.hrms.login(emailOrCode, password);
  }

  Future<AuthResponse> getCurrentUser(String token) async {
    return await client.hrms.getCurrentUser(token);
  }

  Future<bool> logout(String token) async {
    return await client.hrms.logout(token);
  }

  // ==================== ATTENDANCE ====================

  Future<AttendanceEntry> markCheckIn({
    required String employeeCode,
    required String inTime,
    required String dateStr,
  }) async {
    return await client.hrms.markCheckIn(
      employeeCode,
      inTime,
      dateStr,
    );
  }

  Future<AttendanceEntry?> markCheckOut({
    required String employeeCode,
    required String outTime,
    required String dateStr,
    required String workingHours,
  }) async {
    return await client.hrms.markCheckOut(
      employeeCode,
      outTime,
      dateStr,
      workingHours,
    );
  }

  Future<List<AttendanceEntry>> getAttendanceHistory({
    required String employeeCode,
  }) async {
    return await client.hrms.getAttendanceHistory(employeeCode);
  }

  Future<AttendanceEntry?> getTodayAttendance({
    required String employeeCode,
    required String dateStr,
  }) async {
    return await client.hrms.getTodayAttendance(employeeCode, dateStr);
  }

  // ==================== LEAVE ====================

  Future<LeaveRecord> applyLeave({
    required String employeeCode,
    required String category,
    required String startDate,
    required String endDate,
    required double totalDays,
    String? reason,
  }) async {
    return await client.hrms.applyLeave(
      employeeCode,
      category,
      startDate,
      endDate,
      totalDays,
      reason,
    );
  }

  Future<List<LeaveRecord>> getLeaveApplications({
    required String employeeCode,
  }) async {
    return await client.hrms.getLeaveApplications(employeeCode);
  }

  Future<List<LeaveSummary>> getLeaveSummaries({
    required String employeeCode,
  }) async {
    return await client.hrms.getLeaveSummaries(employeeCode);
  }

  Future<bool> cancelLeave({
    required int leaveId,
    required String employeeCode,
  }) async {
    return await client.hrms.cancelLeave(leaveId, employeeCode);
  }

  Future<List<LeaveRecord>> getAllLeaveApplications() async {
    return await client.hrms.getAllLeaveApplications();
  }

  Future<List<LeaveRecord>> getPendingApprovals() async {
    return await client.hrms.getPendingApprovals();
  }

  Future<bool> approveLeave(int leaveId, {String? comment}) async {
    return await client.hrms.approveLeave(leaveId, comment);
  }

  Future<bool> rejectLeave(int leaveId, String reason) async {
    return await client.hrms.rejectLeave(leaveId, reason);
  }

  // ==================== EMPLOYEES ====================

  Future<List<EmployeeRecord>> getEmployees() async {
    return await client.hrms.getEmployees();
  }

  Future<EmployeeRecord> addEmployee(EmployeeRecord employee) async {
    return await client.hrms.addEmployee(employee);
  }

  Future<EmployeeRecord?> updateEmployee(EmployeeRecord employee) async {
    return await client.hrms.updateEmployee(employee);
  }

  Future<EmployeeRecord?> getEmployeeByCode(String code) async {
    return await client.hrms.getEmployeeByCode(code);
  }

  // ==================== HOLIDAYS ====================

  Future<List<HolidayEntry>> getHolidays() async {
    return await client.hrms.getHolidays();
  }

  Future<HolidayEntry> addHoliday(HolidayEntry holiday) async {
    return await client.hrms.addHoliday(holiday);
  }

  Future<bool> deleteHoliday(int holidayId) async {
    return await client.hrms.deleteHoliday(holidayId);
  }

  // ==================== POLICIES ====================

  Future<List<CompanyPolicy>> getPolicies() async {
    try {
      final jsonStr = await client.hrms.getPolicies();
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => CompanyPolicy.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting policies: $e');
      return [];
    }
  }

  // ==================== FEEDS ====================

  Future<List<FeedEntry>> getFeeds() async {
    return await client.hrms.getFeeds();
  }

  Future<FeedEntry> postFeed({
    required String author,
    required String authorInitials,
    required String content,
    required String postedTime,
  }) async {
    return await client.hrms.postFeed(
      author,
      authorInitials,
      content,
      postedTime,
    );
  }

  Future<FeedEntry?> likeFeed(int feedId) async {
    return await client.hrms.likeFeed(feedId);
  }

  // ==================== ENTERPRISE TICKETING ====================

  /// Fetch list of client tickets
  Future<List<ClientTicket>> getTickets({
    String? statusFilter,
    String? assignedTo,
  }) async {
    try {
      final jsonStr = await client.callServerEndpoint<String>(
        'hrms',
        'getTickets',
        {
          'statusFilter': statusFilter,
          'assignedTo': assignedTo,
        },
      );
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((item) => ClientTicket.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error getting tickets: $e');
      return [];
    }
  }

  /// Fetch full ticket details (ticket, timeline events, comments)
  Future<Map<String, dynamic>> getTicketDetails(int ticketId) async {
    try {
      final jsonStr = await client.callServerEndpoint<String>(
        'hrms',
        'getTicketDetails',
        {
          'ticketId': ticketId,
        },
      );
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (data['success'] == true) {
        final ticket = ClientTicket.fromJson(data['ticket'] as Map<String, dynamic>);
        final timelineRaw = (data['timeline'] as List<dynamic>?) ?? [];
        final commentsRaw = (data['comments'] as List<dynamic>?) ?? [];

        final timeline = timelineRaw.map((e) => TicketTimelineEvent.fromJson(e as Map<String, dynamic>)).toList();
        final comments = commentsRaw.map((c) => TicketComment.fromJson(c as Map<String, dynamic>)).toList();

        return {
          'success': true,
          'ticket': ticket,
          'timeline': timeline,
          'comments': comments,
        };
      }
      return {'success': false, 'message': data['message'] ?? 'Failed to load details'};
    } catch (e) {
      debugPrint('Error getting ticket details: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Create a new client ticket
  Future<Map<String, dynamic>> createClientTicket(Map<String, dynamic> ticketData) async {
    try {
      final jsonStr = await client.callServerEndpoint<String>(
        'hrms',
        'createClientTicket',
        {
          'ticketJson': jsonEncode(ticketData),
        },
      );
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error creating client ticket: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Manager assigns ticket to CS Person
  Future<bool> assignTicketByManager(
    int ticketId,
    String csPersonCode,
    String csPersonName,
    String? managerComment,
  ) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'assignTicketByManager',
        {
          'ticketId': ticketId,
          'csPersonCode': csPersonCode,
          'csPersonName': csPersonName,
          'managerComment': managerComment,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error in assignTicketByManager: $e');
      return false;
    }
  }

  /// CS Person understands requirements and assigns to Developer
  Future<bool> assignTicketByCs(
    int ticketId,
    String developerCode,
    String developerName,
    String? csComment,
  ) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'assignTicketByCs',
        {
          'ticketId': ticketId,
          'developerCode': developerCode,
          'developerName': developerName,
          'csComment': csComment,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error in assignTicketByCs: $e');
      return false;
    }
  }

  /// Developer starts work (Starts active timer)
  Future<bool> startDevWork(int ticketId, String devCode) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'startDevWork',
        {
          'ticketId': ticketId,
          'devCode': devCode,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error in startDevWork: $e');
      return false;
    }
  }

  /// Developer finishes work (Stops timer and hands over to QA Tester)
  Future<bool> completeDevWorkAndSendToTesting(
    int ticketId,
    String devCode,
    String testerCode,
    String testerName,
    String? devComment,
  ) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'completeDevWorkAndSendToTesting',
        {
          'ticketId': ticketId,
          'devCode': devCode,
          'testerCode': testerCode,
          'testerName': testerName,
          'devComment': devComment,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error in completeDevWorkAndSendToTesting: $e');
      return false;
    }
  }

  /// Tester starts testing (Starts active timer)
  Future<bool> startTestingWork(int ticketId, String testerCode) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'startTestingWork',
        {
          'ticketId': ticketId,
          'testerCode': testerCode,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error in startTestingWork: $e');
      return false;
    }
  }

  /// Tester completes testing (Passed -> for deployment, or Failed -> back to Dev)
  Future<bool> completeTestingWork(
    int ticketId,
    String testerCode,
    bool passed,
    String? qaComment,
  ) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'completeTestingWork',
        {
          'ticketId': ticketId,
          'testerCode': testerCode,
          'passed': passed,
          'qaComment': qaComment,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error in completeTestingWork: $e');
      return false;
    }
  }

  /// Developer deploys fix to production
  Future<bool> markDeployedByDeveloper(
    int ticketId,
    String devCode,
    String? deployNotes,
  ) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'markDeployedByDeveloper',
        {
          'ticketId': ticketId,
          'devCode': devCode,
          'deployNotes': deployNotes,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error in markDeployedByDeveloper: $e');
      return false;
    }
  }

  /// CS Person verifies deployment and updates Client
  Future<bool> closeTicketByCs(
    int ticketId,
    String csCode,
    String? clientUpdateNote,
  ) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'closeTicketByCs',
        {
          'ticketId': ticketId,
          'csCode': csCode,
          'clientUpdateNote': clientUpdateNote,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error in closeTicketByCs: $e');
      return false;
    }
  }

  /// Add comment to ticket
  Future<bool> addTicketComment(
    int ticketId,
    String authorCode,
    String authorName,
    String authorRole,
    String message, {
    String? attachmentName,
  }) async {
    try {
      final res = await client.callServerEndpoint<bool>(
        'hrms',
        'addTicketComment',
        {
          'ticketId': ticketId,
          'authorCode': authorCode,
          'authorName': authorName,
          'authorRole': authorRole,
          'message': message,
        },
      );
      return res;
    } catch (e) {
      debugPrint('Error adding ticket comment: $e');
      return false;
    }
  }
}

