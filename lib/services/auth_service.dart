import 'package:flutter/foundation.dart';
import 'package:hrms_client/hrms_client.dart';
import 'serverpod_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserAccount? _currentUser;
  EmployeeRecord? _currentEmployee;
  String? _sessionToken;

  UserAccount? get currentUser => _currentUser;
  EmployeeRecord? get currentEmployee => _currentEmployee;
  String? get sessionToken => _sessionToken;
  bool get isLoggedIn => _currentUser != null;

  String get displayName => _currentEmployee?.name ?? _currentUser?.name ?? 'Pratik Nikam';
  String get employeeCode => _currentEmployee?.code ?? _currentUser?.employeeCode ?? 'HRC06';
  String get role => _currentUser?.role ?? 'Employee';
  String get email => _currentUser?.email ?? 'pratik@codeqube.ai';
  String get initials => _currentEmployee?.initials ?? 'PN';

  Future<AuthResponse> login({
    required String emailOrCode,
    required String password,
  }) async {
    try {
      final res = await ServerpodService().login(
        emailOrCode: emailOrCode,
        password: password,
      );

      if (res.success && res.user != null) {
        _currentUser = res.user;
        _currentEmployee = res.employee;
        _sessionToken = res.token;
        notifyListeners();
      }
      return res;
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Connection error: $e',
      );
    }
  }

  Future<void> logout() async {
    if (_sessionToken != null) {
      try {
        await ServerpodService().logout(_sessionToken!);
      } catch (_) {}
    }
    _currentUser = null;
    _currentEmployee = null;
    _sessionToken = null;
    notifyListeners();
  }
}
