import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_client/hrms_client.dart';

void main() {
  test('Phase 5: Employee Directory & Dynamic Profile Flow Test', () async {
    final client = Client('http://localhost:8080/')..connectivityMonitor = null;
    try {
      // 1. Fetch all employees
      final initialEmployees = await client.hrms.getEmployees();
      expect(initialEmployees, isNotEmpty);
      expect(initialEmployees.length, greaterThanOrEqualTo(8));
      
      final hrc01 = initialEmployees.firstWhere((e) => e.code == 'HRC01');
      expect(hrc01.name, isNotEmpty);
      expect(hrc01.email, isNotEmpty);

      // 2. Fetch employee by code
      final fetchedEmp = await client.hrms.getEmployeeByCode('HRC01');
      expect(fetchedEmp, isNotNull);
      expect(fetchedEmp!.code, equals('HRC01'));
      expect(fetchedEmp.department, equals('Engineering'));

      // 3. Update employee profile
      final updatedEmp = fetchedEmp.copyWith(
        position: 'Lead Flutter Architect',
        branchLocation: 'Mumbai Innovation Center',
        bloodGroup: 'O+',
      );
      final updatedResult = await client.hrms.updateEmployee(updatedEmp);
      expect(updatedResult, isNotNull);
      expect(updatedResult!.position, equals('Lead Flutter Architect'));

      // 4. Verify update was persisted in PostgreSQL
      final reFetched = await client.hrms.getEmployeeByCode('HRC01');
      expect(reFetched, isNotNull);
      expect(reFetched!.position, equals('Lead Flutter Architect'));
      expect(reFetched.branchLocation, equals('Mumbai Innovation Center'));
      expect(reFetched.bloodGroup, equals('O+'));

      // 5. Add a new employee
      final testCode = 'TEST_${DateTime.now().millisecondsSinceEpoch % 10000}';
      final newEmp = EmployeeRecord(
        code: testCode,
        name: 'Siddheshwar Jadhav',
        initials: 'SJ',
        role: 'DevOps Specialist',
        department: 'Engineering',
        email: 'siddheshwar.$testCode@example.com',
        position: 'DevOps Specialist',
        mobile: '+91 99220 11223',
        joinedOn: '23-10-2026',
        branchLocation: 'Pune Branch',
        gender: 'Male',
        maritalStatus: 'Single',
        bloodGroup: 'A+',
      );

      final addedResult = await client.hrms.addEmployee(newEmp);
      expect(addedResult, isNotNull);
      expect(addedResult.code, equals(testCode));

      // 6. Verify newly added employee is in getEmployees list
      final allAfterAdd = await client.hrms.getEmployees();
      final addedFound = allAfterAdd.any((e) => e.code == testCode);
      expect(addedFound, isTrue);
    } finally {
      client.close();
    }
  });
}
