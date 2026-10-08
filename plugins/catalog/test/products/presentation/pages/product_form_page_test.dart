import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/products/domain/entities/product.dart';
import 'package:gasione_plugin_catalog/src/features/products/presentation/pages/product_form_page.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';

void main() {
  testWidgets(
    'stays on the form while submitting then replaces it with result',
    (tester) async {
      ProductDraft? submittedDraft;
      final submission = Completer<ProductSubmissionResult>();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            CatalogLocalizations.delegate,
          ],
          supportedLocales: {
            ...AppLocalizations.supportedLocales,
            ...CatalogLocalizations.supportedLocales,
          }.toList(),
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => ProductFormPage(
                        pickerLauncher: const _PickerLauncher(),
                        onSubmit: (draft) {
                          submittedDraft = draft;
                          return submission.future;
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open form'));
      await tester.pumpAndSettle();

      expect(find.byType(ProductFormPage), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Keyboard');
      await tester.enterText(fields.at(1), 'Mechanical keyboard');
      await _selectCategory(tester);
      await tester.enterText(fields.at(2), '99.90');
      await tester.enterText(fields.at(3), '12');

      final submitButton = find.widgetWithText(FilledButton, 'Add');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.byType(ProductFormPage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(submittedDraft?.title, 'Keyboard');
      expect(submittedDraft?.price, 99.90);
      expect(submittedDraft?.stock, 12);

      submission.complete(
        const ProductSubmissionResult(success: true, message: 'Product added.'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProductFormPage), findsNothing);
      expect(find.byType(AppResultPage), findsOneWidget);
      expect(find.text('Product added.'), findsOneWidget);

      await tester.tap(find.text('Back to products'));
      await tester.pumpAndSettle();
      expect(find.text('Open form'), findsOneWidget);
    },
  );

  testWidgets('binds known errors and shows unknown errors in a snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          CatalogLocalizations.delegate,
        ],
        supportedLocales: {
          ...AppLocalizations.supportedLocales,
          ...CatalogLocalizations.supportedLocales,
        }.toList(),
        home: ProductFormPage(
          pickerLauncher: const _PickerLauncher(),
          onSubmit: (_) async => const ProductSubmissionResult(
            success: false,
            message: 'Product is invalid.',
            failure: ValidationFailure(
              errors: [
                ErrorDetail(
                  code: 'invalid_title',
                  field: 'title',
                  message: 'Title already exists',
                ),
                ErrorDetail(
                  code: 'invalid_product',
                  message: 'Product cannot be saved',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await _fillValidProductForm(tester);
    final submitButton = find.widgetWithText(FilledButton, 'Add');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.byType(ProductFormPage), findsOneWidget);
    expect(find.byType(AppResultPage), findsNothing);
    expect(find.text('Title already exists'), findsOneWidget);
    expect(find.text('Product cannot be saved'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'New title');
    await tester.pump();
    expect(find.text('Title already exists'), findsNothing);
  });
}

Future<void> _fillValidProductForm(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Keyboard');
  await tester.enterText(fields.at(1), 'Mechanical keyboard');
  await _selectCategory(tester);
  await tester.enterText(fields.at(2), '99.90');
  await tester.enterText(fields.at(3), '12');
}

Future<void> _selectCategory(WidgetTester tester) async {
  final picker = tester.widget<InkWell>(
    find.descendant(
      of: find.byType(AppPickerFormField<PickerValue>),
      matching: find.byType(InkWell),
    ),
  );
  picker.onTap!();
  await tester.pump();
}

class _PickerLauncher implements PickerLauncher {
  const _PickerLauncher();

  @override
  Future<T?> open<T>(
    BuildContext context,
    PickerKey<T> key, {
    PickerRequest<T>? request,
  }) async {
    return PickerValue(id: 'accessories', label: 'Accessories') as T;
  }
}
