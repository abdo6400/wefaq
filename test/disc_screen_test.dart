import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/disc/disc_screen.dart';

void main() {
  testWidgets(
    'exploration requires choices, accepts notes and calculates result',
    (tester) async {
      tester.view.physicalSize = const Size(900, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: DiscScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.discDisclaimer), findsOneWidget);
      await tester.tap(find.text(AppStrings.discStart));
      await tester.pumpAndSettle();
      var next = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.nextButton),
      );
      expect(next.onPressed, isNull);
      await tester.enterText(find.byType(TextField), 'ملاحظة شخصية');
      for (var i = 0; i < 8; i++) {
        await tester.tap(find.byType(OutlinedButton).first);
        await tester.pumpAndSettle();
        final label = i == 7 ? 'عرض النتيجة' : AppStrings.nextButton;
        await tester.ensureVisible(find.text(label));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
      expect(find.text(AppStrings.discResult), findsOneWidget);
      expect(find.textContaining('D — المبادرة والإنجاز: 8'), findsOneWidget);
      expect(find.text('ملاحظة شخصية'), findsNothing);
      await tester.ensureVisible(find.text(AppStrings.discAgain));
      await tester.tap(find.text(AppStrings.discAgain));
      await tester.pumpAndSettle();
      next = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, AppStrings.nextButton),
      );
      expect(next.onPressed, isNull);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );
  testWidgets('back warns that notes and answers will be deleted', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const Scaffold()),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const DiscScreen()),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(AppStrings.discStart),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text(AppStrings.discStart));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.discStart));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.discExitBody), findsOneWidget);
    await tester.tap(find.text(AppStrings.discStay));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byType(TextField), findsOneWidget);
  });
}
