import '../result/result.dart';

/// The next step required before entering the application's authenticated area.
enum AuthStatus {
  companyRequired,
  loginRequired,
  verificationRequired,
  verificationSetupRequired,
  authenticated,
}

/// Result of the credential exchange without exposing tenant tokens.
sealed class AuthSignInOutcome {
  const AuthSignInOutcome();
}

final class AuthSessionReady extends AuthSignInOutcome {
  const AuthSessionReady(this.nextStatus);

  final AuthStatus nextStatus;
}

final class AuthMfaRequired extends AuthSignInOutcome {
  const AuthMfaRequired({
    required this.transactionId,
    required this.receiver,
    this.expiresInSeconds,
  });

  final String transactionId;
  final String receiver;
  final int? expiresInSeconds;
}

/// FOUNDATION: shared auth boundary, independent of Flutter and API formats.
///
/// The implementation owns persisted company/session state. The host only uses
/// the returned status to choose a page; tenant tokens never leave this API.
abstract interface class AuthRestorer {
  /// Restores company/session and the context required by the next auth step.
  /// Concurrent calls must share an attempt. A failed attempt can be retried.
  /// Failures must complete with an error rather than grant authenticated access.
  Future<AuthStatus> restore();
}

abstract interface class AuthProvider implements AuthRestorer {
  /// Resolves and persists a company without creating a user session.
  Future<Result<void>> selectCompany(String code);

  /// Clears the active company/session while retaining saved account entries.
  Future<Result<void>> clearCompany();

  /// Exchanges user credentials and persists a successful session.
  Future<Result<AuthSignInOutcome>> signIn({
    required String username,
    required String password,
  });

  /// Completes an MFA challenge and commits the resulting user session.
  Future<Result<AuthSessionReady>> verifyOtp({
    required String transactionId,
    required String otp,
  });

  /// Requests another code for an active MFA transaction.
  Future<Result<void>> resendOtp(String transactionId);

  /// Requests password recovery instructions for a tenant username.
  Future<Result<void>> recoverPassword(String username);

  /// Re-checks credentials without replacing the current session.
  Future<Result<void>> verifyCredentials({
    required String username,
    required String password,
  });

  /// Revokes the current tenant session and removes its installed account copy.
  Future<Result<void>> signOut();

  /// Removes only the active session, for expiry or invalid local state.
  Future<Result<void>> clearSession();
}
