import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/app_theme.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/activities/activity_data.dart';
import 'package:wefaq/features/disc/disc_screen.dart';
import 'package:wefaq/features/favorites/data/favorites_storage.dart';
import 'package:wefaq/features/favorites/presentation/favorites_screen.dart';
import 'package:wefaq/features/home/home_screen.dart';
import 'package:wefaq/features/sessions/session_data.dart';
import 'package:wefaq/features/sessions/session_screen.dart';
import 'package:wefaq/features/sessions/session_setup_screen.dart';
import 'package:wefaq/features/support/presentation/support_screen.dart';

Widget _wrapApp(
  Widget child, {
  double textScale = 1.0,
  Size size = const Size(390, 844),
}) => MaterialApp(
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(size: size, textScaler: TextScaler.linear(textScale)),
    child: child,
  ),
);

void main() {
  testWidgets(
    'SessionSetupScreen keeps start button pinned and visible without scrolling',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrapApp(SessionSetupScreen(repository: InMemoryQuestionRepository())),
      );
      await tester.pumpAndSettle();

      final startFinder = find.widgetWithText(
        FilledButton,
        AppStrings.startSessionButton,
      );
      expect(startFinder, findsOneWidget);
      final buttonRect = tester.getRect(startFinder);
      expect(buttonRect.bottom, lessThanOrEqualTo(844));
    },
  );

  testWidgets(
    'SessionScreen keeps primary navigation buttons pinned during active session',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrapApp(
          const SessionScreen(
            questions: [
              'سؤال طويل نسبيًا للتأكد من بقاء أزرار التحكم ظاهرة طوال الوقت دون الحاجة للتمرير المتكرر أثناء الجلسة.',
              'السؤال الثاني',
            ],
            clarifications: [
              'توضيح إضافي يساعد الزوجين على فهم القصد من السؤال بهدوء واحترام.',
              null,
            ],
            mode: ConversationMode.together,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.nextButton), findsOneWidget);
      expect(find.text(AppStrings.skipButton), findsOneWidget);
      expect(find.text(AppStrings.previousButton), findsOneWidget);
      expect(
        tester.getRect(find.text(AppStrings.nextButton)).bottom,
        lessThanOrEqualTo(844),
      );
    },
  );

  testWidgets(
    'HomeScreen Quick Spark sheet displays random question and navigates to topic setup',
    (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrapApp(
          HomeScreen(questionRepository: InMemoryQuestionRepository()),
          size: const Size(420, 900),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('سؤال سريع'));
      await tester.pumpAndSettle();

      expect(find.text('سؤال سريع للحوار'), findsOneWidget);
      expect(find.text('سؤال عشوائي آخر'), findsOneWidget);
      expect(find.text('جلسة في المحور'), findsOneWidget);

      await tester.tap(find.text('سؤال عشوائي آخر'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('جلسة في المحور'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionSetupScreen), findsOneWidget);
    },
  );

  testWidgets(
    'FavoritesScreen filters by search with clear button and opens card deck view',
    (tester) async {
      final storage = InMemoryFavoritesStorage();
      await storage.toggleFavorite('comm-intro-1');
      await storage.toggleFavorite('daily-intro-1');
      await storage.toggleFavorite('fin-intro-1');

      await tester.pumpWidget(
        _wrapApp(
          FavoritesScreen(
            storage: storage,
            repository: InMemoryQuestionRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'يومك');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.reviewFavoritesAsCards), findsOneWidget);

      await tester.tap(find.text(AppStrings.reviewFavoritesAsCards));
      await tester.pumpAndSettle();
      expect(find.byType(SessionScreen), findsOneWidget);
    },
  );

  testWidgets(
    'ActivitiesScreen and ActivityPlayScreen priority ordering rank and reset cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrapApp(const ActivitiesScreen(), size: const Size(320, 568)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.playScenarios), findsOneWidget);
      expect(find.text(AppStrings.discTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.playPriorities));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.playProgress(1, 5)), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(AppStrings.playReset),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(AppStrings.playReset), findsOneWidget);
    },
  );

  testWidgets(
    'SupportScreen, FavoritesScreen, and DiscScreen support 1.5x text scale without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrapApp(
          const SupportScreen(),
          textScale: 1.5,
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final favStorage = InMemoryFavoritesStorage();
      await favStorage.toggleFavorite('comm-intro-1');
      await tester.pumpWidget(
        _wrapApp(
          FavoritesScreen(
            storage: favStorage,
            repository: InMemoryQuestionRepository(),
          ),
          textScale: 1.5,
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _wrapApp(
          const DiscScreen(),
          textScale: 1.5,
          size: const Size(360, 640),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'HomeScreen mode tiles expose tap action and pass accessibility guidelines',
    (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrapApp(HomeScreen(questionRepository: InMemoryQuestionRepository())),
      );
      await tester.pumpAndSettle();

      final togetherSemantics = tester.getSemantics(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(AppStrings.modeTogetherTitle)),
        ),
      );
      expect(
        togetherSemantics.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );
      handle.dispose();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    },
  );

  testWidgets(
    'Core screens pass Android/iOS tap target, label, and contrast guidelines',
    (tester) async {
      for (final screen in [
        SessionSetupScreen(repository: InMemoryQuestionRepository()),
        SessionScreen(
          questions: const ['سؤال للحوار'],
          topicLabels: const ['التواصل'],
          depthLabels: const ['تمهيدي'],
          mode: ConversationMode.together,
          favoritesStorage: InMemoryFavoritesStorage(),
        ),
        const ActivitiesScreen(),
        FavoritesScreen(
          storage: InMemoryFavoritesStorage(),
          repository: InMemoryQuestionRepository(),
        ),
        const SupportScreen(),
      ]) {
        await tester.pumpWidget(_wrapApp(screen));
        await tester.pumpAndSettle();

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
    },
  );
}
