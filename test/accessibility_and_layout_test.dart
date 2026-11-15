import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/app_theme.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/home/home_screen.dart';
import 'package:wefaq/features/sessions/session_data.dart';
import 'package:wefaq/features/sessions/session_screen.dart';
import 'package:wefaq/features/sessions/session_setup_screen.dart';
import 'package:wefaq/main.dart';

Widget createTestApp(
  Widget home, {
  double textScaleFactor = 1.0,
  Size size = const Size(360, 640),
}) {
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: AppTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: home,
    ),
  );
}

void main() {
  group('Small Screen Responsiveness (320x568)', () {
    const smallScreenSize = Size(320, 568);

    testWidgets('HomeScreen renders without overflow on narrow 320px screen', (
      tester,
    ) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(const HomeScreen(), size: smallScreenSize),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
      expect(find.text(AppStrings.startPrototypeSession), findsOneWidget);
    });

    testWidgets('SessionSetupScreen renders without overflow on 320px screen', (
      tester,
    ) async {
      tester.view.physicalSize = smallScreenSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createTestApp(const SessionSetupScreen(), size: smallScreenSize),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.setupTitle), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AppStrings.startSessionButton),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(AppStrings.startSessionButton), findsOneWidget);
    });

    testWidgets(
      'SessionScreen renders dialogue card and actions on 320px screen',
      (tester) async {
        tester.view.physicalSize = smallScreenSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            const SessionScreen(
              questions: ['سؤال تجريبي لاختبار التجاوب مع الشاشات الصغيرة'],
              mode: ConversationMode.together,
            ),
            size: smallScreenSize,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text(AppStrings.sessionCardTitle), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text(AppStrings.finishSessionButton),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(AppStrings.finishSessionButton), findsOneWidget);
      },
    );
  });

  group('Accessibility & Text Scaling (1.5x)', () {
    testWidgets('HomeScreen scales text without crashing or overflowing', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(const HomeScreen(), textScaleFactor: 1.5),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
      expect(find.text(AppStrings.startPrototypeSession), findsOneWidget);
    });

    testWidgets('SessionSetupScreen supports 1.5x text scale factor', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(const SessionSetupScreen(), textScaleFactor: 1.5),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.setupHeader), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(AppStrings.startSessionButton),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(AppStrings.startSessionButton), findsOneWidget);
    });

    testWidgets('SessionScreen supports 1.5x text scale factor', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const SessionScreen(
            questions: ['سؤال تجريبي بخط مكبر'],
            mode: ConversationMode.phone,
          ),
          textScaleFactor: 1.5,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.sessionCardTitle), findsOneWidget);
    });
  });

  group('Semantics & Right-to-Left (RTL)', () {
    testWidgets('all screens use RTL TextDirection', (tester) async {
      await tester.pumpWidget(const WefaqApp());
      await tester.pumpAndSettle();

      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('Mode cards have accessible button semantics', (tester) async {
      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(AppStrings.modeTogetherTitle)),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(RegExp.escape(AppStrings.modePhoneTitle))),
        findsOneWidget,
      );
    });

    testWidgets('Session progress header provides informative semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(
          const SessionScreen(
            questions: ['سؤال أول', 'سؤال ثاني'],
            mode: ConversationMode.together,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(AppStrings.questionProgress(1, 2))),
        ),
        findsOneWidget,
      );
    });
  });
}
