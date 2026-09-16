import "package:flow/theme/flow_custom_colors.dart";
import "package:flow/widgets/stats/cash_flow/cash_flow_flow_bar.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: ThemeData(
      extensions: const [
        FlowCustomColors(
          income: Color(0xFF32CC70),
          expense: Color(0xFFC42525),
          semi: Color(0xFF888888),
        ),
      ],
    ),
    home: Scaffold(body: SizedBox(width: 200, height: 12, child: child)),
  );

  Finder segments() => find.descendant(
    of: find.byType(CashFlowFlowBar),
    matching: find.byType(ColoredBox),
  );

  testWidgets("zero income draws only the expense bar", (tester) async {
    await tester.pumpWidget(
      wrap(const CashFlowFlowBar(income: 0, expense: 1056.67)),
    );

    expect(segments(), findsOneWidget);
    expect(tester.getSize(segments()).width, moreOrLessEquals(200));
  });

  testWidgets("zero expense draws only the income bar", (tester) async {
    await tester.pumpWidget(
      wrap(const CashFlowFlowBar(income: 500, expense: 0)),
    );

    expect(segments(), findsOneWidget);
  });

  testWidgets("both sides draw two segments", (tester) async {
    await tester.pumpWidget(
      wrap(const CashFlowFlowBar(income: 40, expense: 60)),
    );

    expect(segments(), findsNWidgets(2));
  });
}
