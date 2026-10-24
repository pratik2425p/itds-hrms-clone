import '../models/hrms_models.dart';

class MockData {
  /// Returns employee feeds (Empty by default)
  static List<FeedItem> getFeeds() {
    return [];
  }

  /// Returns dashboard weekly attendance records (Empty by default)
  static List<AttendanceRow> getDashboardAttendance() {
    return [];
  }

  /// Returns detailed monthly attendance logs (Empty by default)
  static List<AttendanceRow> getDetailedAttendance() {
    return [];
  }

  /// Returns employee directory records (Empty by default)
  static List<Employee> getEmployees() {
    return [];
  }

  /// Returns holidays list (Empty by default)
  static List<HolidayItem> getHolidays() {
    return [];
  }

  /// Returns roster day shift schedule (Empty by default)
  static List<RosterDay> getRosterDays() {
    return [];
  }
}
