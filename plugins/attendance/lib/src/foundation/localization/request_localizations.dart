import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

final class RequestLocalizations {
  const RequestLocalizations(this.locale);
  final Locale locale;
  bool get _id => locale.languageCode == 'id';
  String get chooseFile => _id ? 'Pilih berkas' : 'Choose file';
  String get addAttachment => _id ? 'Tambah lampiran' : 'Add attachment';
  String get requiredField => _id ? 'Wajib diisi' : 'Required';
  String get invalidValue => _id ? 'Nilai tidak valid' : 'Invalid value';
  String get yes => _id ? 'Ya' : 'Yes';
  String get no => _id ? 'Tidak' : 'No';
  String get submission => _id ? 'Pengajuan Saya' : 'My Submission';
  String get approval => _id ? 'Persetujuan Saya' : 'My Approval';
  String get search => _id ? 'Cari' : 'Search';
  String get retry => _id ? 'Coba lagi' : 'Retry';
  String get empty => _id ? 'Belum ada permintaan' : 'No requests yet';
  String get failed => _id ? 'Tidak dapat memuat data' : 'Could not load data';
  String get done => _id ? 'Selesai' : 'Done';
  String get approve => _id ? 'Setujui' : 'Approve';
  String get reject => _id ? 'Tolak' : 'Reject';
  String get selectAll => _id ? 'Pilih semua yang dimuat' : 'Select all loaded';
  String get filter => _id ? 'Filter' : 'Filter';
  String get sort => _id ? 'Urutkan' : 'Sort';
  String get remark => _id ? 'Catatan' : 'Remark';
  String get loadMore => _id ? 'Muat lagi' : 'Load more';
  String get cancel => _id ? 'Batal' : 'Cancel';
  String selected(int count) => _id ? '$count dipilih' : '$count selected';
  String bulkResult(int success, int failed) => _id
      ? '$success berhasil, $failed gagal'
      : '$success succeeded, $failed failed';
  String status(String wireValue) =>
      (_id ? _statusesId : _statusesEn)[wireValue] ?? wireValue;
  static RequestLocalizations of(BuildContext context) =>
      Localizations.of<RequestLocalizations>(context, RequestLocalizations) ??
      RequestLocalizations(Localizations.localeOf(context));
  static const delegate = _RequestDelegate();
}

const _statusesEn = {
  'PENDING': 'Pending',
  'DRAFTED': 'Draft',
  'SUBMITTED': 'Submitted',
  'APPROVED': 'Approved',
  'REJECTED': 'Rejected',
  'REVOKED': 'Revoked',
  'CANCELLED': 'Cancelled',
  'APPROVAL_PROCESS': 'In approval',
  'SENDBACKED': 'Sent back',
  'PULLBACKED': 'Pulled back',
};
const _statusesId = {
  'PENDING': 'Menunggu',
  'DRAFTED': 'Draf',
  'SUBMITTED': 'Diajukan',
  'APPROVED': 'Disetujui',
  'REJECTED': 'Ditolak',
  'REVOKED': 'Dicabut',
  'CANCELLED': 'Dibatalkan',
  'APPROVAL_PROCESS': 'Dalam persetujuan',
  'SENDBACKED': 'Dikembalikan',
  'PULLBACKED': 'Ditarik kembali',
};

final class _RequestDelegate
    extends LocalizationsDelegate<RequestLocalizations> {
  const _RequestDelegate();
  @override
  bool isSupported(Locale locale) =>
      const ['en', 'id'].contains(locale.languageCode);
  @override
  Future<RequestLocalizations> load(Locale locale) =>
      SynchronousFuture(RequestLocalizations(locale));
  @override
  bool shouldReload(_RequestDelegate old) => false;
}
