import 'dart:io';

import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/notifications/domain/notification_center.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/features/sharing/domain/social_sharing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 14.2 audit records every required contract item once', () {
    final audit = File('docs/PHASE_14_2_CONTRACT_COMPLIANCE_AUDIT.md')
        .readAsStringSync();

    const requiredItems = <String>[
      'Recently Viewed',
      'Product Recommendations',
      'Push Notifications',
      'Automated Push Notifications',
      'Push Notification Admin',
      'Notification Preferences',
      'In-App Notification Center',
      'Klaviyo Integration',
      'Deep Links',
      'Back In Stock',
      'Price Drop Notifications',
      'App-only Offers',
      'Early Access',
      'Drop System',
      'Sale & Discount System',
      'Countdown Timer',
      'Reviews',
      'Creator / UGC',
      'Shoppable Videos',
      'Complete The Look',
      'Personalization',
      'Customer Preferences',
      'App Onboarding',
      'Customer Support',
      'Social Sharing',
      'International Support',
      'Analytics',
      'Business Metrics',
      'Meta Tracking',
      'Attribution Readiness',
      'Firebase',
      'Crashlytics',
      'Remote Config',
    ];
    const allowedStatuses = <String>{
      'COMPLETE',
      'PARTIAL',
      'CLIENT DEPENDENCY',
      'MISSING',
    };

    for (final item in requiredItems) {
      final matches = RegExp(
        r'^\| ' + RegExp.escape(item) + r' \| ([A-Z ]+) \|',
        multiLine: true,
      ).allMatches(audit).toList();
      expect(matches, hasLength(1), reason: item);
      expect(allowedStatuses, contains(matches.single.group(1)), reason: item);
    }
  });

  test(
    'in-app notification center stores bounded unread notifications',
    () async {
      final repository = LocalNotificationCenterRepository(
        InMemoryLocalStorage(),
      );

      for (var i = 0; i < notificationCenterLimit + 5; i += 1) {
        await repository.saveReceived(
          NotificationPayload(id: 'n$i', title: 'Drop $i', deepLink: '/shop'),
        );
      }

      final snapshot = await repository.load();
      expect(snapshot.items, hasLength(notificationCenterLimit));
      expect(snapshot.items.first.id, 'n54');
      expect(snapshot.unreadCount, notificationCenterLimit);

      final read = await repository.markRead('n54');
      expect(read.unreadCount, notificationCenterLimit - 1);
      expect(read.items.first.isRead, isTrue);
    },
  );

  test(
    'social sharing foundation validates safe HTTPS share requests',
    () async {
      const gateway = PreparedSocialShareGateway();

      final result = await gateway.share(
        SocialShareRequest(
          title: '365 Crew Tee',
          url: Uri.parse('https://flexwolf.co/products/365-crew-tee'),
        ),
      );

      expect(result.status, SocialShareStatus.prepared);

      await expectLater(
        gateway.share(
          SocialShareRequest(
            title: 'Unsafe',
            url: Uri.parse('http://flexwolf.co/products/unsafe'),
          ),
        ),
        throwsA(isA<AppException>()),
      );
    },
  );
}
