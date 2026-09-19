# Dependency And License Register

Direct third-party packages introduced/retained in Phase 2.

| Package | Pubspec Constraint | Resolved Version | Purpose | License | Required |
| --- | --- | --- | --- | --- | --- |
| flutter_riverpod | ^3.4.2 | 3.4.2 | State management and dependency overrides | MIT, verified from local package LICENSE | Yes |
| go_router | ^18.0.0 | 18.0.0 | Centralized routing, future deep links/auth route support | BSD-style Flutter Authors license, verified from local package LICENSE | Yes |
| cupertino_icons | ^1.0.8 | 1.0.9 | Standard Cupertino icon font support from Flutter template | MIT, verified from local package LICENSE | Yes |
| firebase_core | ^4.14.0 | 4.14.0 | Firebase app initialization boundary for FCM readiness | BSD-style Firebase/FlutterFire license, verify during final release audit | Client dependency for live Firebase project |
| firebase_messaging | ^16.6.0 | 16.6.0 | Firebase Cloud Messaging client boundary | BSD-style Firebase/FlutterFire license, verify during final release audit | Client dependency for live Firebase project |

No paid Flutter package was added in Phase 2. Phase 8 retained FlutterFire client packages for FCM readiness; live Firebase usage remains a CLIENT DEPENDENCY until FLEXWOLF-owned production Firebase access and platform files are supplied.

A full transitive dependency/license review is required before production
release and final handover.
