import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_client/hrms_client.dart';

void main() {
  test('Phase 6: Approvals, Feeds, Celebrations & Announcements Flow Test', () async {
    final client = Client('http://localhost:8080/')..connectivityMonitor = null;
    try {
      // 1. Fetch pending approvals (auto-seeds if empty)
      final pendingLeaves = await client.hrms.getPendingApprovals();
      expect(pendingLeaves, isNotEmpty);
      final firstPending = pendingLeaves.first;
      expect(firstPending.status, equals('Pending Approval'));
      expect(firstPending.id, isNotNull);

      // 2. Approve a leave request
      final approveSuccess = await client.hrms.approveLeave(
        firstPending.id!,
        'Approved by Engineering Manager',
      );
      expect(approveSuccess, isTrue);

      // Verify status changed to Approved in PostgreSQL
      final allLeaves = await client.hrms.getAllLeaveApplications();
      final approvedFound = allLeaves.firstWhere((l) => l.id == firstPending.id);
      expect(approvedFound.status, equals('Approved'));

      // 3. Create a new pending leave request to test rejection
      final testEmpCode = 'HRC05';
      final newPending = await client.hrms.applyLeave(
        testEmpCode,
        'Casual Leave',
        '2026-11-20',
        '2026-11-20',
        1.0,
        'Personal errands',
      );
      expect(newPending.id, isNotNull);
      expect(newPending.status, equals('Pending Approval'));

      // Reject the leave request
      final rejectSuccess = await client.hrms.rejectLeave(
        newPending.id!,
        'Critical sprint delivery on 20-Nov',
      );
      expect(rejectSuccess, isTrue);

      // Verify status is Rejected and rejection reason appended
      final refreshedAll = await client.hrms.getAllLeaveApplications();
      final rejectedFound = refreshedAll.firstWhere((l) => l.id == newPending.id);
      expect(rejectedFound.status, equals('Rejected'));
      expect(rejectedFound.reason, contains('Critical sprint delivery'));

      // 4. Test Company Feeds & Celebrations
      final feeds = await client.hrms.getFeeds();
      expect(feeds, isNotEmpty);
      final firstFeed = feeds.first;
      final initialLikes = firstFeed.likes;

      // Like the feed
      final updatedFeed = await client.hrms.likeFeed(firstFeed.id!);
      expect(updatedFeed, isNotNull);
      expect(updatedFeed!.likes, equals(initialLikes + 1));

      // 5. Post a new announcement / celebration
      final postedFeed = await client.hrms.postFeed(
        'Pratik Nikam',
        'PN',
        '🚀 Excited to announce our Q4 Hackathon starting next Monday! Stay tuned for rules and team signups.',
        'Just now',
      );
      expect(postedFeed.id, isNotNull);
      expect(postedFeed.author, equals('Pratik Nikam'));

      // Verify it appears in getFeeds
      final updatedFeeds = await client.hrms.getFeeds();
      final foundPost = updatedFeeds.any((f) => f.id == postedFeed.id);
      expect(foundPost, isTrue);
    } finally {
      client.close();
    }
  });
}
