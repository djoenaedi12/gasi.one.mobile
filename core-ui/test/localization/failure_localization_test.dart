import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  for (final (language, network, timeout, unauthorized) in [
    (
      'en',
      'Unable to connect. Check your internet connection.',
      'The request timed out. Please try again.',
      'Your session is no longer valid. Please sign in again.',
    ),
    (
      'id',
      'Tidak dapat terhubung. Periksa koneksi internet Anda.',
      'Waktu permintaan habis. Silakan coba lagi.',
      'Sesi Anda sudah tidak valid. Silakan masuk kembali.',
    ),
  ]) {
    test(
      '$language technical guidance replaces raw transport messages',
      () async {
        final strings = await AppLocalizations.delegate.load(Locale(language));
        expect(
          const NetworkFailure(message: 'SocketException: host unreachable')
              .localizedMessage(strings),
          network,
        );
        expect(
          const TimeoutFailure(message: 'Dio timeout after 30000ms')
              .localizedMessage(strings),
          timeout,
        );
        expect(
          const UnauthorizedFailure(message: 'JWT expired')
              .localizedMessage(strings),
          unauthorized,
        );
        expect(
          const ServerFailure(message: 'Database connection failed')
              .localizedMessage(strings),
          strings.serverError,
        );
        expect(
          const InvalidResponseFailure(message: 'FormatException')
              .localizedMessage(strings),
          strings.invalidResponseError,
        );
        expect(
          const UnknownFailure(message: 'StateError').localizedMessage(strings),
          strings.unknownError,
        );
        expect(
          const CancelledFailure().localizedMessage(strings),
          strings.requestCancelled,
        );
      },
    );
  }

  test(
    'business messages retain actionable API details and field errors',
    () async {
      final strings = await AppLocalizations.delegate.load(const Locale('en'));
      const failure = ValidationFailure(
        message: '  Choose an attendance date within the open period.  ',
        errors: [
          ErrorDetail(code: 'required', field: 'date', message: 'Pick a date'),
        ],
      );
      expect(
        failure.localizedMessage(strings),
        'Choose an attendance date within the open period.',
      );
      expect(failure.fieldError('date'), 'Pick a date');
      expect(
        const ConflictFailure(message: 'Already submitted')
            .localizedMessage(strings),
        'Already submitted',
      );
      expect(
        const ForbiddenFailure(message: 'Only a manager can approve')
            .localizedMessage(strings),
        'Only a manager can approve',
      );
    },
  );

  test('empty business messages fall back to localized guidance', () async {
    final strings = await AppLocalizations.delegate.load(const Locale('id'));
    expect(
      const ValidationFailure(message: ' \n ').localizedMessage(strings),
      strings.validationError,
    );
    expect(
      const NotFoundFailure().localizedMessage(strings),
      strings.notFoundError,
    );
    expect(
      const ConflictFailure().localizedMessage(strings),
      strings.conflictError,
    );
    expect(
      const RateLimitFailure().localizedMessage(strings),
      strings.rateLimitError,
    );
    expect(
      const HttpFailure().localizedMessage(strings),
      strings.operationFailed,
    );
    expect(
      const ForbiddenFailure().localizedMessage(strings),
      strings.forbiddenError,
    );
  });
}
