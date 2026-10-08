import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_api/gasione_core_api.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  testWidgets('text field uses native Form validation error state', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Form(
            key: formKey,
            child: AppTextFormField(
              controller: controller,
              label: 'Username',
              validator: (value) => value == null || value.isEmpty
                  ? 'Username is required'
                  : null,
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Username is required'), findsOneWidget);
  });

  testWidgets('text field keeps its label above the input by default', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppTextFormField(
            controller: controller,
            label: 'Username',
            hint: 'Enter username',
          ),
        ),
      ),
    );

    final decorator = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    expect(decorator.decoration.label, isNull);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Enter username'), findsOneWidget);
  });

  testWidgets('checkbox integrates with Form validation', (tester) async {
    final formKey = GlobalKey<FormState>();
    var accepted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Form(
              key: formKey,
              child: AppCheckboxFormField(
                label: 'Accept terms',
                value: accepted,
                requiredIndicator: true,
                onChanged: (value) => setState(() => accepted = value),
                validator: (value) => value == true ? null : 'Required',
              ),
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    expect(accepted, isTrue);
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('radio group reports the selected generic value', (tester) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => AppRadioGroup<String>(
              label: 'Priority',
              value: selected,
              options: const [
                AppChoiceOption(value: 'low', label: 'Low'),
                AppChoiceOption(value: 'high', label: 'High'),
              ],
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('High'));
    await tester.pump();

    expect(selected, 'high');
  });

  testWidgets('select exposes generic options and selection callback', (
    tester,
  ) async {
    String? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSelectFormField<String>(
            label: 'Category',
            value: selected,
            options: const [
              AppChoiceOption(value: 'phone', label: 'Phone'),
              AppChoiceOption(value: 'laptop', label: 'Laptop'),
            ],
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    final field = tester.widget<DropdownMenuFormField<String>>(
      find.byWidgetPredicate(
        (widget) => widget is DropdownMenuFormField<String>,
      ),
    );
    expect(field.dropdownMenuEntries, hasLength(2));

    field.onSelected?.call('laptop');
    expect(selected, 'laptop');
  });

  testWidgets(
    'picker opens a new page callback and reports its selected value',
    (tester) async {
      PickerValue? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPickerFormField<PickerValue>(
              label: 'Category',
              value: selected,
              labelOf: (value) => value.label,
              onPick: (_) async =>
                  const PickerValue(id: 'office', label: 'Office'),
              onChanged: (value) => selected = value,
            ),
          ),
        ),
      );

    final picker = tester.widget<InkWell>(find.byType(InkWell));
    picker.onTap!();
    await tester.pump();

      expect(selected?.id, 'office');
      expect(selected?.label, 'Office');
    },
  );

  testWidgets('date and time fields open Material picker dialogs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              AppDateFormField(
                label: 'Date',
                value: null,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                onChanged: (_) {},
              ),
              AppTimeFormField(label: 'Time', value: null, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.calendar_today_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.schedule_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });
}
