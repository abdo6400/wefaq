import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/activities/activity_data.dart';
import 'package:wefaq/features/home/home_screen.dart';
import 'package:wefaq/features/sessions/session_data.dart';

Widget createTestApp(Widget home) => MaterialApp(
  home: Directionality(textDirection: TextDirection.rtl, child: home),
);

void main() {
  group('Activity Domain Model', () {
    test('serializes and deserializes scenario activity faithfully', () {
      const original = Activity(
        id: 'act_test_01',
        type: ActivityType.scenario,
        topic: Topic.communication,
        title: 'موقف تجريبي',
        situation: 'وصف تفصيلي للموقف',
        prompts: ['سؤال نقاش 1', 'سؤال نقاش 2'],
        isDevelopmentOnly: true,
      );

      final json = original.toJson();
      final reconstructed = Activity.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.type, original.type);
      expect(reconstructed.topic, original.topic);
      expect(reconstructed.title, original.title);
      expect(reconstructed.situation, original.situation);
      expect(reconstructed.prompts, original.prompts);
      expect(reconstructed.options, isEmpty);
      expect(reconstructed.isDevelopmentOnly, isTrue);
    });

    test(
      'serializes and deserializes priorityOrdering activity with options',
      () {
        const original = Activity(
          id: 'act_test_prio',
          type: ActivityType.priorityOrdering,
          topic: Topic.dailyLife,
          title: 'ترتيب أولويات',
          situation: 'اختر الأولويات',
          options: ['أولوية أ', 'أولوية ب'],
          prompts: ['محور 1'],
          isDevelopmentOnly: false,
        );

        final json = original.toJson();
        final reconstructed = Activity.fromJson(json);

        expect(reconstructed.id, original.id);
        expect(reconstructed.type, ActivityType.priorityOrdering);
        expect(reconstructed.options, ['أولوية أ', 'أولوية ب']);
        expect(reconstructed.isDevelopmentOnly, isFalse);
      },
    );

    test('rejects empty id with FormatException', () {
      expect(
        () => Activity.fromJson({'id': '  ', 'title': 'لا يوجد معرف'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('InMemoryActivityRepository Invariants', () {
    final repo = InMemoryActivityRepository();

    test('all prototype activities are marked as development only', () {
      for (final activity in InMemoryActivityRepository.prototypes) {
        expect(
          activity.isDevelopmentOnly,
          isTrue,
          reason: 'Activity ${activity.id} must be marked isDevelopmentOnly',
        );
      }
    });

    test('filters activities by topic', () async {
      final commActivities = await repo.getActivities(
        topic: Topic.communication,
      );
      expect(commActivities, isNotEmpty);
      for (final act in commActivities) {
        expect(act.topic, Topic.communication);
      }
    });

    test('filters activities by type', () async {
      final scenarios = await repo.getActivities(type: ActivityType.scenario);
      expect(scenarios, isNotEmpty);
      for (final act in scenarios) {
        expect(act.type, ActivityType.scenario);
      }

      final priorities = await repo.getActivities(
        type: ActivityType.priorityOrdering,
      );
      expect(priorities, isNotEmpty);
      for (final act in priorities) {
        expect(act.type, ActivityType.priorityOrdering);
      }
    });

    test('applies limit correctly', () async {
      final limited = await repo.getActivities(limit: 1);
      expect(limited.length, 1);
    });

    test('retrieves activity by ID and handles missing ID', () async {
      final found = await repo.getActivityById('act_scen_comm_01');
      expect(found, isNotNull);
      expect(found?.title, contains('زيارة عائلية'));

      final missing = await repo.getActivityById('non_existent_id');
      expect(missing, isNull);
    });
  });

  group('ActivityCard Widget', () {
    testWidgets('renders scenario card with RTL directionality and prompts', (
      tester,
    ) async {
      const activity = Activity(
        id: 'widget_scen_test',
        type: ActivityType.scenario,
        topic: Topic.communication,
        title: 'موقف نقاش عائلي',
        situation: 'هذا نص الموقف للتجربة والتأكد من العرض السليم.',
        prompts: ['ما رأيك في الموقف؟', 'كيف نتصرف معًا؟'],
        isDevelopmentOnly: true,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: ActivityCard(activity: activity)),
          ),
        ),
      );

      expect(find.text('سيناريو للنقاش'), findsOneWidget);
      expect(find.text('موقف نقاش عائلي'), findsOneWidget);
      expect(
        find.text('هذا نص الموقف للتجربة والتأكد من العرض السليم.'),
        findsOneWidget,
      );
      expect(find.text('محاور لتبادل الرأي:'), findsOneWidget);
      expect(find.text('ما رأيك في الموقف؟'), findsOneWidget);
      expect(find.text('كيف نتصرف معًا؟'), findsOneWidget);
      expect(find.text('نشاط تجريبي قيد المراجعة والاستكشاف'), findsOneWidget);

      // Invariant check: zero text fields or input captures
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('renders priorityOrdering card with options', (tester) async {
      const activity = Activity(
        id: 'widget_prio_test',
        type: ActivityType.priorityOrdering,
        topic: Topic.dailyLife,
        title: 'ترتيب أولويات مشتركة',
        situation: 'تأمل النقاط التالية ورتبها مع شريكك:',
        options: ['النقطة الأولى', 'النقطة الثانية'],
        prompts: ['كيف نصل إلى تفاهم؟'],
        isDevelopmentOnly: false,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: ActivityCard(activity: activity)),
          ),
        ),
      );

      expect(find.text('ترتيب أولويات مشتركة'), findsAtLeastNWidgets(1));
      expect(find.text('النقاط المقترحة للنقاش:'), findsOneWidget);
      expect(find.text('النقطة الأولى'), findsOneWidget);
      expect(find.text('النقطة الثانية'), findsOneWidget);
      expect(find.text('كيف نصل إلى تفاهم؟'), findsOneWidget);
      expect(find.text('نشاط تجريبي قيد المراجعة والاستكشاف'), findsNothing);
    });
  });

  group('Games and navigation', () {
    testWidgets('opens scenario cards one at a time', (tester) async {
      await tester.pumpWidget(createTestApp(const ActivitiesScreen()));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.playScenarios), findsOneWidget);
      await tester.tap(find.text(AppStrings.playScenarios));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.playProgress(1, 5)), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(AppStrings.playNext),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text(AppStrings.playNext));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.playNext));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(AppStrings.playProgress(2, 5)),
        -250,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(AppStrings.playProgress(2, 5)), findsOneWidget);
    });
    testWidgets('shows empty state for a game with no cards', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          ActivitiesScreen(repository: InMemoryActivityRepository(const [])),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.playScenarios));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.playNoCards), findsOneWidget);
    });
    testWidgets('bottom navigation opens games and returns home', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.navPlay));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.playTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.navHome));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.welcomeTitle), findsOneWidget);
    });
  });
}
