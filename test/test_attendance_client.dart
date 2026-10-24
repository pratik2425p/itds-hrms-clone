import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_client/hrms_client.dart';

void main() {
  test('Test serverpod attendance API integration', () async {
    final client = Client('http://localhost:8080/')..connectivityMonitor = null;
    try {
      await client.hrms.getTodayAttendance('HRC06', '2026-10-23');
      final mark = await client.hrms.markCheckIn('HRC06', '10:15 AM', '2026-10-23');
      expect(mark.inTime, equals('10:15 AM'));

      final today2 = await client.hrms.getTodayAttendance('HRC06', '2026-10-23');
      expect(today2?.inTime, equals('10:15 AM'));
    } finally {
      client.close();
    }
  });
}
