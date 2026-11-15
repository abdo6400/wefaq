import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/core/strings/app_strings.dart';
import 'package:wefaq/features/licensing/licensing_data.dart';
import 'package:wefaq/main.dart';
import 'package:wefaq/features/sessions/session_data.dart';

class UnavailableLicenseRepository implements LicenseRepository {
  @override
  Future<ActivationResult> activateCode(String code) =>
      throw StateError('Unexpected activation');
  @override
  Future<bool> consumeSessionQuota(String idempotencyKey) =>
      throw StateError('Unexpected quota check');
  @override
  Future<LicenseEntitlement> getEntitlement() =>
      throw StateError('Unexpected license check');
  @override
  Future<InstallationIdentity> getInstallationIdentity() =>
      throw StateError('Unexpected identity check');
}

void main() {
  testWidgets('sessions stay available without a licensing service', (
    tester,
  ) async {
    await tester.pumpWidget(
      WefaqApp(
        licenseRepository: UnavailableLicenseRepository(),
        questionRepository: InMemoryQuestionRepository(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.licenseStatusTitle), findsNothing);
    await tester.tap(find.text(AppStrings.startPrototypeSession));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.scrollUntilVisible(
        find.text(AppStrings.startSessionButton),
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text(AppStrings.startSessionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.startSessionButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('السؤال 1 من'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.exitSessionAction));
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });
}
