import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wefaq/main.dart';

void main() {
  testWidgets('shows Arabic right-to-left landing screen', (tester) async {
    await tester.pumpWidget(const WefaqApp());
    await tester.pumpAndSettle();
    expect(find.text('حوار يقرّب الفهم'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('هذه نسخة أولية قيد التطوير.'), findsOneWidget);
    final direction = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.text('حوار يقرّب الفهم'),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(direction.textDirection, TextDirection.rtl);
  });
}
