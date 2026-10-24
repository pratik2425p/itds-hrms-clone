import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_client/hrms_client.dart';

void main() {
  test('End-to-End Leave Application, Balance & Cancellation Test', () async {
    final client = Client('http://localhost:8080/')..connectivityMonitor = null;
    try {
      const empCode = 'HRC06';

      // 1. Initial balances
      final initialBalances = await client.hrms.getLeaveSummaries(empCode);
      expect(initialBalances, isNotEmpty);
      final clInitial = initialBalances.firstWhere((s) => s.category.contains('Casual'));

      // 2. Apply for Casual Leave (1 day)
      final applied = await client.hrms.applyLeave(
        empCode,
        'Casual Leave',
        '2026-11-05',
        '2026-11-05',
        1.0,
        'Personal work and doctor appointment',
      );
      expect(applied.id, isNotNull);
      expect(applied.status, equals('Pending Approval'));
      expect(applied.category, equals('Casual Leave'));

      // 3. Fetch applications
      final applications = await client.hrms.getLeaveApplications(empCode);
      final found = applications.firstWhere((a) => a.id == applied.id);
      expect(found.reason, equals('Personal work and doctor appointment'));

      // 4. Check that balance reflects the pending request
      final updatedBalances = await client.hrms.getLeaveSummaries(empCode);
      final clUpdated = updatedBalances.firstWhere((s) => s.category.contains('Casual'));
      expect(clUpdated.consumed, equals(clInitial.consumed + 1.0));

      // 5. Cancel the leave
      final cancelResult = await client.hrms.cancelLeave(applied.id!, empCode);
      expect(cancelResult, isTrue);

      // 6. Verify cancelled status
      final afterCancelApps = await client.hrms.getLeaveApplications(empCode);
      final cancelledApp = afterCancelApps.firstWhere((a) => a.id == applied.id);
      expect(cancelledApp.status, equals('Cancelled'));
    } finally {
      client.close();
    }
  });
}
