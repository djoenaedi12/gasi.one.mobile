import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_starter/gasione_core_starter.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';
import 'package:gasione_plugin_catalog/src/features/categories/presentation/pages/category_form_page.dart';
import 'package:gasione_plugin_catalog/src/localization/l10n/catalog_localizations.dart';

void main() {
  testWidgets('binds API errors to category fields without a snackbar', (
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
        home: CategoryFormPage(
          onSubmit: (_) async => const CategorySubmissionResult(
            success: false,
            message: 'Category is invalid.',
            failure: ValidationFailure(
              errors: [
                ErrorDetail(
                  code: 'duplicate_code',
                  field: 'code',
                  message: 'Code already exists',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'CAT-01');
    await tester.enterText(fields.at(1), 'Accessories');

    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pump();

    expect(find.byType(CategoryFormPage), findsOneWidget);
    expect(find.byType(AppResultPage), findsNothing);
    expect(find.text('Code already exists'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
