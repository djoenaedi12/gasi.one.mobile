import 'package:epeoplecare/config.dart';
import 'package:epeoplecare/model/client.dart';
import 'package:epeoplecare/provider/client_provider.dart';
import 'package:epeoplecare/provider/encoder_provider.dart';
import 'package:epeoplecare/repository/auth_repository.dart';
import 'package:epeoplecare/repository/client_repository.dart';

/// TRANSITION[LEGACY-AUTH]: replace these callbacks with auth-plugin transport
/// when the Pre-Home CR owns authentication. No tenant token enters core-api.
String get legacyDirectoryUrl =>
    'https://${EncoderProvider().decode(Config.baseUrl.replaceAll('https://', ''))}';

Future<String> legacyDirectoryToken() async {
  final repository = AuthRepository(
    legacyDirectoryUrl,
    '',
    '',
    Config.language,
  );
  final session = await repository.login(
    EncoderProvider().decode(Config.baseClientId),
    EncoderProvider().decode(Config.baseClientSecret),
    EncoderProvider().decode(Config.baseUsername),
    EncoderProvider().decode(Config.basePassword),
    '',
  );
  if (session == null) throw StateError('Directory authentication failed.');
  return session.accessToken;
}

Future<({String accessToken, String refreshToken})> refreshLegacyTokens(
  String token,
) async {
  final company = Config.client;
  if (company == null) throw StateError('No active company.');
  final repository = AuthRepository(company.url, '', '', Config.language);
  final session = await repository.refreshToken(
    company.clientId,
    company.clientSecret,
    token,
  );
  if (session == null) throw StateError('Session refresh failed.');
  return (accessToken: session.accessToken, refreshToken: session.refreshToken);
}

/// COMPAT[INSTALLED-COMPANY]: refresh old shared tenant URLs during restoration.
Future<Client> repairLegacyCompany(Client installed) async {
  if (!installed.url.contains('ewf-client')) return installed;
  try {
    final token = await legacyDirectoryToken();
    final repository = ClientRepository(legacyDirectoryUrl, Config.language);
    final company = await repository.getClient(installed.code, token);
    if (company == null) return installed;
    final decoder = ClientProvider();
    company.url = decoder.safeBase64Decode(company.url);
    company.clientId = decoder.safeBase64Decode(company.clientId);
    company.clientSecret = decoder.safeBase64Decode(company.clientSecret);
    await decoder.setClient(company, '');
    return company;
  } catch (_) {
    // Existing behavior retains installed company data when repair is offline.
    return installed;
  }
}
