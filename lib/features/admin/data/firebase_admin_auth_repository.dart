import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/admin/domain/admin_models.dart';
import 'package:flexwolf/features/admin/domain/admin_repositories.dart';

/// Uses a separate Firebase auth instance so admin sign-in does not replace
/// the customer's app session on the same device.
class FirebaseAdminAuthRepository implements AdminAuthRepository {
  Future<FirebaseAuth> _auth() async {
    FirebaseApp app;
    try {
      app = Firebase.app('flexwolfAdmin');
    } on FirebaseException {
      app = await Firebase.initializeApp(
        name: 'flexwolfAdmin',
        options: Firebase.app().options,
      );
    }
    return FirebaseAuth.instanceFor(app: app);
  }

  Future<AdminSession> _session(User user) async {
    final result = await user.getIdTokenResult(true);
    if (result.claims?['admin'] != true) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'This Firebase account does not have admin access.',
        code: 'admin_claim_required',
      );
    }
    final token = result.token;
    if (token == null || token.isEmpty) {
      throw const AppException(
        kind: AppErrorKind.authentication,
        message: 'Admin token could not be created.',
        code: 'admin_token_missing',
      );
    }
    final rawRole = result.claims?['role'];
    final role =
        AdminRole.values.where((r) => r.name == rawRole).firstOrNull ??
        AdminRole.admin;
    return AdminSession(
      user: AdminUser(id: user.uid, email: user.email ?? '', role: role),
      accessToken: token,
      expiresAt:
          result.expirationTime ?? DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<AdminSession?> restoreSession() async {
    final auth = await _auth();
    final user = auth.currentUser;
    if (user == null) return null;
    try {
      return await _session(user);
    } on AppException {
      await auth.signOut();
      return null;
    }
  }

  @override
  Future<AdminSession> login(AdminCredentials credentials) async {
    final auth = await _auth();
    try {
      final result = await auth.signInWithEmailAndPassword(
        email: credentials.email.trim(),
        password: credentials.password,
      );
      final user = result.user;
      if (user == null) {
        throw const AppException(
          kind: AppErrorKind.authentication,
          message: 'Admin login failed.',
          code: 'admin_user_missing',
        );
      }
      try {
        return await _session(user);
      } on AppException {
        await auth.signOut();
        rethrow;
      }
    } on FirebaseAuthException catch (error) {
      throw AppException(
        kind: AppErrorKind.authentication,
        message: error.message ?? 'Admin login failed.',
        code: 'admin_firebase_${error.code}',
      );
    }
  }

  @override
  Future<void> logout() async => (await _auth()).signOut();

  @override
  Future<void> handleUnauthorized() => logout();
}
