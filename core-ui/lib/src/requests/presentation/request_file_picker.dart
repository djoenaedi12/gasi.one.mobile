import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:mime/mime.dart';

import '../localization/request_localizations.dart';

class RequestFilePicker extends StatefulWidget {
  const RequestFilePicker({super.key, required this.title});
  final String title;
  @override
  State<RequestFilePicker> createState() => _RequestFilePickerState();
}

class _RequestFilePickerState extends State<RequestFilePicker> {
  bool _busy = false;
  bool _failed = false;
  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final file = await FilePicker.pickFile();
      if (!mounted) return;
      if (file?.path != null) {
        Navigator.pop(
          context,
          RequestAttachmentSelection(
            path: file!.path!,
            name: file.name,
            contentType:
                lookupMimeType(file.name) ?? 'application/octet-stream',
          ),
        );
      } else {
        setState(() => _busy = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = RequestLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_failed) Text(strings.failed),
            FilledButton(
              onPressed: _busy ? null : _pick,
              child: _busy
                  ? const CircularProgressIndicator()
                  : Text(strings.chooseFile),
            ),
          ],
        ),
      ),
    );
  }
}
