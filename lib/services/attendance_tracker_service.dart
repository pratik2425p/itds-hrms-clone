import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'serverpod_service.dart';

class AttendanceTrackerService extends ChangeNotifier {
  static final AttendanceTrackerService _instance = AttendanceTrackerService._internal();
  factory AttendanceTrackerService() => _instance;
  AttendanceTrackerService._internal();

  bool _isLoading = false;
  bool _isCheckedIn = false;
  bool _isCheckedOut = false;
  String? _inTime;
  String? _outTime;
  String? _workingHours;
  DateTime? _checkInTime;
  String _elapsedDurationStr = '00:00:00';
  Timer? _tickerTimer;

  bool get isLoading => _isLoading;
  bool get isCheckedIn => _isCheckedIn;
  bool get isCheckedOut => _isCheckedOut;
  String? get inTime => _inTime;
  String? get outTime => _outTime;
  String? get workingHours => _workingHours;
  String get elapsedDurationStr => _elapsedDurationStr;

  /// Load today's attendance state from Serverpod backend
  Future<void> initTodayAttendance(String employeeCode) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      final altDateStr = DateFormat('dd-MM-yyyy').format(now);

      // Check both formats
      var entry = await ServerpodService().getTodayAttendance(
        employeeCode: employeeCode,
        dateStr: dateStr,
      );
      entry ??= await ServerpodService().getTodayAttendance(
        employeeCode: employeeCode,
        dateStr: altDateStr,
      );

      if (entry != null) {
        _inTime = entry.inTime;
        _outTime = entry.outTime;
        _workingHours = entry.workingHours;

        if (entry.outTime != null && entry.outTime!.trim().isNotEmpty && entry.outTime != '--') {
          _isCheckedIn = true;
          _isCheckedOut = true;
          _stopTimer();
        } else if (entry.inTime != null && entry.inTime!.trim().isNotEmpty) {
          _isCheckedIn = true;
          _isCheckedOut = false;
          _checkInTime = entry.timestamp;
          _startTimer();
        }
      }
    } catch (e) {
      debugPrint('Error loading today attendance: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark check-in
  Future<void> checkIn({
    required String employeeCode,
    required String inTime,
    required String dateStr,
    DateTime? checkInDateTime,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ServerpodService().markCheckIn(
        employeeCode: employeeCode,
        inTime: inTime,
        dateStr: dateStr,
      );

      _isCheckedIn = true;
      _isCheckedOut = false;
      _inTime = inTime;
      _checkInTime = checkInDateTime ?? DateTime.now();
      _startTimer();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark check-out
  Future<void> checkOut({
    required String employeeCode,
    required String outTime,
    required String dateStr,
    required String workingHours,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ServerpodService().markCheckOut(
        employeeCode: employeeCode,
        outTime: outTime,
        dateStr: dateStr,
        workingHours: workingHours,
      );

      _isCheckedOut = true;
      _outTime = outTime;
      _workingHours = workingHours;
      _stopTimer();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startTimer() {
    _stopTimer();
    _updateElapsed();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  void _stopTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  void _updateElapsed() {
    if (_checkInTime == null) {
      _elapsedDurationStr = '00:00:00';
      notifyListeners();
      return;
    }

    final diff = DateTime.now().difference(_checkInTime!);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    _elapsedDurationStr = '$hours:$minutes:$seconds';
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
