import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/picker/category_picker.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';

typedef ProductFormSubmit = Future<ProductSubmissionResult> Function(
  ProductDraft draft,
);

@immutable
class ProductSubmissionResult {
  const ProductSubmissionResult({
    required this.success,
    required this.message,
    this.failure,
  });

  final bool success;
  final String message;
  final Failure? failure;
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    required this.onSubmit,
    required this.pickerLauncher,
    this.product,
    super.key,
  });

  final Product? product;
  final ProductFormSubmit onSubmit;
  final PickerLauncher pickerLauncher;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  static const _fields = {'title', 'description', 'category', 'price', 'stock'};

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  PickerValue? _category;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  bool _isSubmitting = false;
  Map<String, String> _fieldErrors = const {};

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _titleController = TextEditingController(text: product?.title);
    _descriptionController = TextEditingController(text: product?.description);
    _category = product == null
        ? null
        : PickerValue(id: product.category, label: product.category);
    _priceController = TextEditingController(
      text: product?.price.toStringAsFixed(2),
    );
    _stockController = TextEditingController(text: product?.stock.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final localizations = CatalogLocalizations.of(context);
    final coreLocalizations = AppLocalizations.of(context);
    final draft = ProductDraft(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category!.label,
      price: double.parse(_priceController.text),
      stock: int.parse(_stockController.text),
    );

    late final ProductSubmissionResult result;
    try {
      result = await widget.onSubmit(draft);
    } on Object {
      result = ProductSubmissionResult(
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
          primaryActionLabel: localizations.backToProducts,
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
            _isEditing ? localizations.editProduct : localizations.addProduct,
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
                        controller: _titleController,
                        label: coreLocalizations.title,
                        requiredIndicator: true,
                        enabled: !_isSubmitting,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        validator: _requiredValidator,
                        errorText: _fieldErrors['title'],
                        onChanged: (_) => _clearFieldError('title'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: _descriptionController,
                        label: coreLocalizations.description,
                        requiredIndicator: true,
                        enabled: !_isSubmitting,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        validator: _requiredValidator,
                        errorText: _fieldErrors['description'],
                        onChanged: (_) => _clearFieldError('description'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppPickerFormField<PickerValue>(
                        label: localizations.category,
                        value: _category,
                        labelOf: (category) => category.label,
                        requiredIndicator: true,
                        enabled: !_isSubmitting,
                        hint: localizations.selectCategory,
                        onPick: _pickCategory,
                        onChanged: (category) {
                          setState(() => _category = category);
                          _clearFieldError('category');
                        },
                        validator: (category) => category == null
                            ? coreLocalizations.requiredField
                            : null,
                        errorText: _fieldErrors['category'],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: _priceController,
                        label: localizations.price,
                        requiredIndicator: true,
                        enabled: !_isSubmitting,
                        prefixText: r'$ ',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        textInputAction: TextInputAction.next,
                        validator: _priceValidator,
                        errorText: _fieldErrors['price'],
                        onChanged: (_) => _clearFieldError('price'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: _stockController,
                        label: localizations.stock,
                        requiredIndicator: true,
                        enabled: !_isSubmitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: _stockValidator,
                        errorText: _fieldErrors['stock'],
                        onChanged: (_) => _clearFieldError('stock'),
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

  Future<PickerValue?> _pickCategory(BuildContext context) {
    return widget.pickerLauncher.open(
      context,
      CatalogPickerKeys.category,
      request: PickerRequest(
        title: CatalogLocalizations.of(context).selectCategory,
        initialValue: _category,
      ),
    );
  }

  String? _priceValidator(String? value) {
    final price = double.tryParse(value ?? '');
    if (price == null || price <= 0) {
      return CatalogLocalizations.of(context).validPrice;
    }
    return null;
  }

  String? _stockValidator(String? value) {
    final stock = int.tryParse(value ?? '');
    if (stock == null || stock < 0) {
      return CatalogLocalizations.of(context).validStock;
    }
    return null;
  }

  void _handleFailure(ProductSubmissionResult result) {
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
