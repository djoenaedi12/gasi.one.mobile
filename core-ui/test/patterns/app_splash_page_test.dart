import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gasione_core_ui/gasione_core_ui.dart';

void main() {
  for (final (locale, theme, palette, message, retryLabel) in [
    (
      const Locale('en'),
      AppTheme.light(),
      AppColors.light,
      'Unable to prepare the application. Please try again.',
      'Retry',
    ),
    (
      const Locale('id'),
      AppTheme.dark(),
      AppColors.dark,
      'Aplikasi belum dapat disiapkan. Silakan coba lagi.',
      'Coba lagi',
    ),
  ]) {
    testWidgets(
      'splash retains branding through ${locale.languageCode} failure and retry',
      (tester) async {
        var retries = 0;
        Widget app(Widget splash) => MaterialApp(
          theme: theme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: splash,
        );
        await tester.pumpWidget(
          app(const AppSplashPage.loading(version: '4.15.0')),
        );
        final splash = tester.element(find.byType(AppSplashPage));
        final logo = tester.element(find.byType(Image));
        await tester.pumpWidget(
          app(
            AppSplashPage.failure(version: '4.15.0', onRetry: () => retries++),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.element(find.byType(AppSplashPage)), same(splash));
        expect(tester.element(find.byType(Image)), same(logo));
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.textContaining('4.15.0'), findsOneWidget);
        expect(
          tester.widget<Text>(find.text(message)).style?.color,
          palette.destructive,
        );
        await tester.tap(find.text(retryLabel));
        expect(retries, 1);
        // The host, not the button, changes the startup state.
        expect(find.text(message), findsOneWidget);
        await tester.pumpWidget(
          app(const AppSplashPage.loading(version: '4.15.0')),
        );
        await tester.pumpAndSettle();
        expect(tester.element(find.byType(Image)), same(logo));
        expect(find.text(message), findsNothing);
        expect(find.text(retryLabel), findsNothing);
      },
    );
  }

  testWidgets(
    'failed splash keeps retry reachable with a short viewport and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: AppSplashPage.failure(
            version: '4.15.0',
            onRetry: () => retries++,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Retry'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
      expect(find.byType(AppSplashPage), findsOneWidget);
    },
  );

  testWidgets('splash owns branding and localizes available version metadata', (
    tester,
  ) async {
    Widget app(String? version) => MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AppSplashPage.loading(version: version),
    );
    await tester.pumpWidget(app(null));
    final logo = tester.widget<Image>(find.byType(Image));
    expect(
      (logo.image as AssetImage).keyName,
      'packages/gasione_core_ui/assets/branding/logo.png',
    );
    expect(logo.semanticLabel, 'GASI:One');
    expect(find.textContaining('Versi'), findsNothing);
    await tester.pumpWidget(app('4.15.0'));
    expect(find.text('Versi 4.15.0'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(AppButton), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    // Presentation has no timer or navigation; the host decides when to leave.
    expect(find.byType(AppSplashPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('splash scrolls on a short viewport and follows theme colors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const AppSplashPage.loading(version: '4.15.0'),
      ),
    );
    final text = tester.widget<Text>(find.text('Version 4.15.0'));
    expect(text.style?.color, AppColors.dark.mutedForeground);
    final context = tester.element(find.byType(AppSplashPage));
    expect(
      Theme.of(context).scaffoldBackgroundColor,
      AppColors.dark.background,
    );
    await tester.ensureVisible(find.text('Version 4.15.0'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
