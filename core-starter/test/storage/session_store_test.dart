import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';

import '../helpers/memory_token_storage.dart';

void main() {
  test(
    'logout invalidates refresh and serializes deletion behind writes',
    () async {
      final storage = _DelayedStorage();
      final sessions = SessionStore(storage);
      final saving = sessions.saveTokens(
        version: sessions.version,
        accessToken: 'access',
        refreshToken: 'refresh',
      );
      await storage.started.future;
      final clearing = sessions.clearTokens();
      storage.proceed.complete();
      expect(await saving, isFalse);
      await clearing;
      expect(storage.accessToken, isNull);
      expect(await sessions.readAccessToken(), isNull);
    },
  );
  test('failed deletion blocks reads and can be retried', () async {
    final storage = _FailingClearStorage()..accessToken = 'old';
    final sessions = SessionStore(storage);
    final version = sessions.version;
    await expectLater(sessions.clearTokens(), throwsStateError);
    expect(storage.accessToken, 'old');
    expect(await sessions.readAccessToken(), isNull);
    expect(
      await sessions.saveTokens(
        version: version,
        accessToken: 'late',
        refreshToken: 'late',
      ),
      isFalse,
    );
    storage.fail = false;
    await sessions.clearTokens();
    expect(storage.accessToken, isNull);
  });
  test('stale login cannot save tokens or expire a newer session', () async {
    final sessions = SessionStore(MemoryTokenStorage());
    final old = sessions.beginSession();
    final current = sessions.beginSession();
    expect(
      await sessions.saveTokens(
        version: current,
        accessToken: 'current',
        refreshToken: 'current',
      ),
      isTrue,
    );
    expect(
      await sessions.saveTokens(
        version: old,
        accessToken: 'old',
        refreshToken: 'old',
      ),
      isFalse,
    );
    expect(await sessions.expire(old), isFalse);
    expect(await sessions.readAccessToken(), 'current');
  });
}

class _DelayedStorage extends MemoryTokenStorage {
  final started = Completer<void>();
  final proceed = Completer<void>();
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    started.complete();
    await proceed.future;
    await super.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}

class _FailingClearStorage extends MemoryTokenStorage {
  bool fail = true;
  @override
  Future<void> clearTokens() async {
    if (fail) throw StateError('Storage unavailable');
    await super.clearTokens();
  }
}
