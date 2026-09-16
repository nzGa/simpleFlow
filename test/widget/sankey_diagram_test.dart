import "package:flow/theme/flow_custom_colors.dart";
import "package:flow/widgets/analytics/sankey_diagram.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  group("Sankey chart palettes", () {
    test("income and expense families do not overlap", () {
      for (final Brightness brightness in Brightness.values) {
        final Set<int> income = sankeyIncomePalette(
          brightness,
        ).map((c) => c.toARGB32()).toSet();
        final Set<int> expense = sankeyExpensePalette(
          brightness,
        ).map((c) => c.toARGB32()).toSet();

        expect(income.intersection(expense), isEmpty);
        expect(income, isNot(contains(sankeyTaxColor(brightness).toARGB32())));
        expect(expense, isNot(contains(sankeyTaxColor(brightness).toARGB32())));
      }
    });

    test("surplus theme greens are not reused as income bars", () {
      const List<Color> reserved = [
        Color(0xFF32CC70),
        Color(0xFF15803D),
        Color(0xFFA6E3A1),
      ];

      for (final Brightness brightness in Brightness.values) {
        final Set<int> income = sankeyIncomePalette(
          brightness,
        ).map((c) => c.toARGB32()).toSet();
        final Set<int> expense = sankeyExpensePalette(
          brightness,
        ).map((c) => c.toARGB32()).toSet();

        for (final Color color in reserved) {
          expect(income, isNot(contains(color.toARGB32())));
          expect(expense, isNot(contains(color.toARGB32())));
        }
      }
    });
  });

  group("Sankey layout helpers", () {
    test("budget columns keep three slim bars with ribbon gaps", () {
      const Size size = Size(400, 280);
      final columns = sankeyColumnXs(size.width, hasMiddle: true);

      expect(columns.left, sankeyLabelGutter(size.width));
      expect(columns.middle, isNotNull);
      expect(columns.left, lessThan(columns.middle!));
      expect(columns.middle!, lessThan(columns.right));
      expect(columns.middle! - columns.left - 12, greaterThan(40));
      expect(columns.right - columns.middle! - 12, greaterThan(40));
    });

    test("two-column flow has no middle bar", () {
      final columns = sankeyColumnXs(400, hasMiddle: false);
      expect(columns.middle, isNull);
    });

    test("label gutters leave room for names on both sides", () {
      expect(sankeyLabelGutter(400), 104.0);
      expect(sankeyLabelGutter(200), 72.0);
      expect(sankeyLabelGutter(800), 128.0);
    });

    test("a single source is a slim bar, not a half-width slab", () {
      const Size size = Size(400, 280);
      final double gutter = sankeyLabelGutter(size.width);
      final List<Rect> sources = stackSankeyNodes(
        values: const [100],
        total: 100,
        x: gutter,
        height: size.height,
      );
      final List<Rect> targets = stackSankeyNodes(
        values: const [40, 30, 20, 10],
        total: 100,
        x: size.width - gutter - 12,
        height: size.height,
      );

      expect(sources, hasLength(1));
      expect(sources.single.width, 12);
      expect(sources.single.left, gutter);
      expect(sources.single.right, lessThan(size.width * 0.4));
      expect(targets, hasLength(4));
      expect(
        targets.first.left - sources.single.right,
        greaterThan(size.width * 0.4),
      );
    });

    test("right-side nodes can sit in the net-income band", () {
      final List<Rect> netBand = stackSankeyNodes(
        values: const [20, 80],
        total: 100,
        x: 200,
        height: 280,
      );
      expect(netBand, hasLength(2));

      final List<Rect> targets = stackSankeyNodes(
        values: const [40, 40],
        total: 80,
        x: 300,
        y: netBand.last.top,
        height: netBand.last.height,
      );

      expect(targets.first.top, closeTo(netBand.last.top, 0.001));
      expect(targets.last.bottom, closeTo(netBand.last.bottom, 0.001));
    });
  });

  testWidgets("zero-income flow still paints labeled streams", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            FlowCustomColors(
              income: Color(0xFF32CC70),
              expense: Color(0xFFC42525),
              semi: Color(0xFF888888),
            ),
          ],
        ),
        home: const Scaffold(
          body: SizedBox(
            width: 400,
            child: SankeyDiagram(
              sources: [
                SankeyDatum(
                  label: "From reserves",
                  value: 100,
                  color: Color(0xFFC42525),
                ),
              ],
              targets: [
                SankeyDatum(label: "Rent", value: 50, color: Color(0xFF4ECDC4)),
                SankeyDatum(label: "Food", value: 30, color: Color(0xFFFF6B6B)),
                SankeyDatum(
                  label: "Transport",
                  value: 20,
                  color: Color(0xFFFFD93D),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SankeyDiagram), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets("classic budget layout paints without filling a hub", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [
            FlowCustomColors(
              income: Color(0xFF32CC70),
              expense: Color(0xFFC42525),
              semi: Color(0xFF888888),
            ),
          ],
        ),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: SankeyDiagram.fromLayout(
              layout: buildBudgetSankeyLayout(
                income: const [
                  SankeyDatum(
                    label: "Nómina",
                    value: 80,
                    color: Color(0xFF0F766E),
                  ),
                  SankeyDatum(
                    label: "Extra",
                    value: 20,
                    color: Color(0xFF0E7490),
                  ),
                ],
                expenses: const [
                  SankeyDatum(
                    label: "Vivienda",
                    value: 30,
                    color: Color(0xFFC2410C),
                  ),
                  SankeyDatum(
                    label: "Comida",
                    value: 20,
                    color: Color(0xFFB91C1C),
                  ),
                ],
                taxes: const [
                  SankeyDatum(
                    label: "Impuestos",
                    value: 15,
                    color: Color(0xFFB45309),
                  ),
                ],
                netColor: const Color(0xFF0F766E),
                surplusColor: const Color(0xFF32CC70),
                deficitColor: const Color(0xFFC42525),
                taxColor: const Color(0xFF9F1239),
                grossLabel: "Ingresos brutos",
                netLabel: "Ingreso neto",
                surplusLabel: "Sobrante",
                fromReservesLabel: "De reservas",
                taxesLabel: "Impuestos",
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SankeyDiagram), findsOneWidget);
  });
}
