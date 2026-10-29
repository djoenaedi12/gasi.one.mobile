import 'package:flutter/material.dart';
import 'package:gasione_core_api/gasione_core_api.dart';

import '../localization/request_localizations.dart';

/// Custom fields keep their installed string wire values. The feature owns the
/// draft map, so errors and rebuilds do not discard entered values.
class RequestCustomFieldsSection extends StatelessWidget {
  const RequestCustomFieldsSection({
    super.key,
    required this.fields,
    required this.values,
    required this.onChanged,
    this.editing = false,
  });
  final List<CustomFieldDefinition> fields;
  final Map<int, String?> values;
  final void Function(int, String?) onChanged;
  final bool editing;
  String? _validate(
    BuildContext context,
    CustomFieldDefinition field,
    String? value,
  ) {
    final strings = RequestLocalizations.of(context);
    if (value == null || value.isEmpty) {
      return field.required ? strings.requiredField : null;
    }
    if (field.minLength != null && value.length < field.minLength! ||
        field.maxLength != null && value.length > field.maxLength!) {
      return strings.invalidValue;
    }
    if (field.type == 'INT' && int.tryParse(value) == null ||
        field.type == 'DOUBLE' && double.tryParse(value) == null) {
      return strings.invalidValue;
    }
    if (field.type == 'DATE') {
      final parsed = DateTime.tryParse(value);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
          parsed == null ||
          parsed.toIso8601String().substring(0, 10) != value) {
        return strings.invalidValue;
      }
    }
    if (field.type == 'TIME' &&
        !RegExp(r'^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$').hasMatch(value)) {
      return strings.invalidValue;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final field in fields)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _field(context, field),
        ),
    ],
  );
  Widget _field(BuildContext context, CustomFieldDefinition field) {
    final value = values.containsKey(field.id)
        ? values[field.id]
        : field.defaultValue;
    final enabled = !editing || field.editable;
    final options = field.type == 'BOOL'
        ? [
            CustomFieldOption('1', RequestLocalizations.of(context).yes),
            CustomFieldOption('0', RequestLocalizations.of(context).no),
          ]
        : field.options;
    if (const ['BOOL', 'LIST', 'ENUMERATION'].contains(field.type)) {
      return DropdownButtonFormField<String>(
        key: ValueKey(field.id),
        initialValue: value,
        decoration: InputDecoration(labelText: field.name),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option.value, child: Text(option.label)),
        ],
        onChanged: enabled ? (v) => onChanged(field.id, v) : null,
        validator: enabled ? (v) => _validate(context, field, v) : null,
        onSaved: (v) => onChanged(field.id, v),
      );
    }
    return TextFormField(
      key: ValueKey(field.id),
      initialValue: value,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: field.name,
        hintText: field.type == 'DATE'
            ? 'yyyy-MM-dd'
            : field.type == 'TIME'
            ? 'HH:mm'
            : null,
      ),
      maxLines: field.type == 'TEXT_AREA' ? 4 : 1,
      keyboardType: const ['INT', 'DOUBLE'].contains(field.type)
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      onChanged: (v) => onChanged(field.id, v),
      onSaved: (v) => onChanged(field.id, v),
      validator: (v) => _validate(context, field, v),
    );
  }
}

class RequestAttachmentsField extends StatefulWidget {
  const RequestAttachmentsField({
    super.key,
    required this.repository,
    required this.pickers,
    required this.attachments,
    required this.onChanged,
  });
  final AttachmentRepository repository;
  final PickerLauncher pickers;
  final List<RequestAttachment> attachments;
  final ValueChanged<List<RequestAttachment>> onChanged;
  @override
  State<RequestAttachmentsField> createState() =>
      _RequestAttachmentsFieldState();
}

class _RequestAttachmentsFieldState extends State<RequestAttachmentsField> {
  bool _busy = false;
  bool _failed = false;
  Future<void> _add() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final file = await widget.pickers.open(
        context,
        RequestPickerKeys.attachment,
      );
      if (!mounted) return;
      if (file != null) {
        final result = await widget.repository.upload(
          path: file.path,
          name: file.name,
          contentType: file.contentType,
        );
        if (!mounted) return;
        if (result case Success<RequestAttachment>(:final data)) {
          widget.onChanged([
            ...widget.attachments.where((item) => item.id != data.id),
            data,
          ]);
        } else {
          _failed = true;
        }
      }
    } catch (_) {
      _failed = true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final attachment in widget.attachments)
        ListTile(
          title: Text(attachment.name),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _busy
                ? null
                : () => widget.onChanged(
                    widget.attachments
                        .where((item) => item.id != attachment.id)
                        .toList(),
                  ),
          ),
        ),
      if (_failed) Text(RequestLocalizations.of(context).failed),
      TextButton.icon(
        onPressed: _busy ? null : _add,
        icon: _busy
            ? const CircularProgressIndicator()
            : const Icon(Icons.attach_file),
        label: Text(RequestLocalizations.of(context).addAttachment),
      ),
    ],
  );
}
