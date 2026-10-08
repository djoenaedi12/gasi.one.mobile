import 'package:flutter/material.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/domain/entities/category.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';

typedef CategoryFormSubmit = Future<CategorySubmissionResult> Function(
  CategoryDraft draft,
);

@immutable
class CategorySubmissionResult {
  const CategorySubmissionResult({
    required this.success,
    required this.message,
    this.failure,
  });

  final bool success;
  final String message;
  final Failure? failure;
}

class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({required this.onSubmit, this.category, super.key});

  final Category? category;
  final CategoryFormSubmit onSubmit;

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  static const _fields = {'code', 'name', 'description'};

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  bool _isSubmitting = false;
  Map<String, String> _fieldErrors = const {};

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _codeController = TextEditingController(text: category?.code);
    _nameController = TextEditingController(text: category?.name);
    _descriptionController = TextEditingController(text: category?.description);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);

    late final CategorySubmissionResult result;
    try {
      result = await widget.onSubmit(
        CategoryDraft(
          code: _codeController.text.trim(),
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
        ),
      );
    } on Object {
      result = CategorySubmissionResult(
        success: false,
        message: coreLocalizations.unknownError,
      );
    }
    if (!mounted) {
      return;
    }

    if (!result.success) {
      _handleFailure(result);
      return;
    }

    await Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(
        builder: (resultContext) => AppResultPage(
          status: AppResultStatus.success,
          title: coreLocalizations.operationSuccessful,
          message: result.message,
          primaryActionLabel: localizations.backToCategories,
          onPrimaryAction: () => Navigator.of(resultContext).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);

    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isEditing ? localizations.editCategory : localizations.addCategory,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextFormField(
                        controller: _codeController,
                        label: coreLocalizations.code,
                        requiredIndicator: true,
                        enabled: !_isSubmitting,
                        autofocus: true,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                        errorText: _fieldErrors['code'],
                        onChanged: (_) => _clearFieldError('code'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: _nameController,
                        label: coreLocalizations.name,
                        requiredIndicator: true,
                        enabled: !_isSubmitting,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                        errorText: _fieldErrors['name'],
                        onChanged: (_) => _clearFieldError('name'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: _descriptionController,
                        label: coreLocalizations.description,
                        enabled: !_isSubmitting,
                        minLines: 3,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        errorText: _fieldErrors['description'],
                        onChanged: (_) => _clearFieldError('description'),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton.primary(
                        label: _isEditing
                            ? coreLocalizations.save
                            : coreLocalizations.add,
                        onPressed: _submit,
                        isLoading: _isSubmitting,
                        expand: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context).requiredField;
    }
    return null;
  }

  void _handleFailure(CategorySubmissionResult result) {
    final failure = result.failure;
    final fieldErrors = <String, String>{};
    for (final field in _fields) {
      final message = failure?.fieldError(field);
      if (message != null) {
        fieldErrors[field] = message;
      }
    }
    final snackbarMessage = failure == null
        ? result.message
        : failure.unboundErrorMessage(
            knownFields: _fields,
            fallbackMessage: result.message,
          );

    setState(() {
      _isSubmitting = false;
      _fieldErrors = fieldErrors;
    });

    if (snackbarMessage != null) {
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(snackbarMessage)));
    }
  }

  void _clearFieldError(String field) {
    if (!_fieldErrors.containsKey(field)) {
      return;
    }
    setState(() {
      _fieldErrors = Map.of(_fieldErrors)..remove(field);
    });
  }
}
