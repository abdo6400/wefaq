import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/home/home_screen.dart';
import 'package:wefaq/features/licensing/licensing_data.dart';
import 'package:wefaq/features/support/presentation/support_screen.dart';

void main() {
  group('SupportScreen UI & Concierge Workflow', () {
    testWidgets('renders support without an installation ID', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = DefaultLicenseRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SupportScreen(licenseRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.supportTitle), findsOneWidget);
      expect(find.text(AppStrings.installationIdLabel), findsNothing);
      expect(find.text(AppStrings.copyInstallationIdButton), findsNothing);
      expect(find.text(AppStrings.contactSectionTitle), findsOneWidget);
      expect(find.text(AppStrings.openWhatsAppSupport), findsOneWidget);
      expect(find.text(AppStrings.faqSectionTitle), findsOneWidget);

      // Verify privacy assurance banner
      expect(find.text(AppStrings.privacyTermsSummaryBody), findsOneWidget);
    });

    testWidgets('expands FAQ accordion on tap and reveals answers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = DefaultLicenseRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SupportScreen(licenseRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstFaq = find.text(
        'هل التطبيق بيسجل إجاباتنا أو كلامنا في المكالمة؟',
      );
      expect(firstFaq, findsOneWidget);

      await tester.tap(firstFaq);
      await tester.pumpAndSettle();

      expect(find.textContaining('لا يطلب إذن الميكروفون'), findsOneWidget);
    });

    testWidgets('shows WhatsApp dialog with prepared message template on tap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = DefaultLicenseRepository();

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SupportScreen(licenseRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.openWhatsAppSupport));
      await tester.pumpAndSettle();

      expect(find.text('التواصل مع الدعم عبر واتساب'), findsOneWidget);
      expect(find.textContaining('معرف التثبيت:'), findsNothing);
      expect(find.text('نسخ الرسالة والمتابعة'), findsOneWidget);

      await tester.tap(find.text('نسخ الرسالة والمتابعة'));
      await tester.pumpAndSettle();

      expect(find.text('تم نسخ نص الرسالة للحافظة بنجاح.'), findsOneWidget);
    });

    testWidgets('HomeScreen mode card navigates to SupportScreen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(AppStrings.navHelp));
      await tester.pumpAndSettle();

      expect(find.byType(SupportScreen), findsOneWidget);
      expect(find.text(AppStrings.supportSubtitle), findsOneWidget);
    });
  });
}
