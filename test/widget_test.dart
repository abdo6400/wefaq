import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/main.dart';

void main() {
  testWidgets('shows Arabic right-to-left landing screen', (tester) async {
    await tester.pumpWidget(const WefaqApp());
    await tester.pumpAndSettle();

    expect(find.text('حوار يقرّب الفهم'), findsOneWidget);

    final direction = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.text('حوار يقرّب الفهم'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(direction.textDirection, TextDirection.rtl);

    await tester.scrollUntilVisible(
      find.textContaining('الأسئلة تجريبية'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('الأسئلة تجريبية'), findsOneWidget);
  });
}
