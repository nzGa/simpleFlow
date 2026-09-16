import "package:flow/widgets/analytics/sankey_diagram.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  const Color income = Color(0xFF0F766E);
  const Color expense = Color(0xFFC2410C);
  const Color net = Color(0xFF0E7490);
  const Color surplus = Color(0xFF32CC70);
  const Color deficit = Color(0xFFC42525);
  const Color tax = Color(0xFF9F1239);

  SankeyDatum node(String label, double value, Color color) =>
      SankeyDatum(label: label, value: value, color: color);

  BudgetSankeyLayout layout({
    List<SankeyDatum> income = const [],
    List<SankeyDatum> expenses = const [],
    List<SankeyDatum> taxes = const [],
  }) {
    return buildBudgetSankeyLayout(
      income: income,
      expenses: expenses,
      taxes: taxes,
      netColor: net,
      surplusColor: surplus,
      deficitColor: deficit,
      taxColor: tax,
      grossLabel: "Ingresos brutos",
      netLabel: "Ingreso neto",
      surplusLabel: "Sobrante",
      fromReservesLabel: "De reservas",
      taxesLabel: "Impuestos",
    );
  }

  group("classic budget Sankey", () {
    test("peels taxes and fans the rest to expenses plus surplus", () {
      final BudgetSankeyLayout chart = layout(
        income: [node("Nómina", 80, income), node("Extra", 20, income)],
        taxes: [node("Impuestos", 15, expense)],
        expenses: [node("Vivienda", 30, expense), node("Comida", 20, expense)],
      );

      expect(chart.isClassic, isTrue);
      expect(chart.leftColumnLabel, "Ingresos brutos");
      expect(chart.left, hasLength(2));
      expect(sankeySum(chart.left), 100);

      expect(chart.taxes?.label, "Impuestos");
      expect(chart.taxes?.value, 15);
      expect(chart.taxes?.color, tax);

      expect(chart.net?.label, "Ingreso neto");
      expect(chart.net?.value, 85);

      expect(chart.right.map((d) => d.label), [
        "Vivienda",
        "Comida",
        "Sobrante",
      ]);
      expect(chart.right.firstWhere((d) => d.label == "Sobrante").value, 35);
      expect(chart.right.any((d) => d.label == "Impuestos"), isFalse);
    });

    test("skips the tax node when nothing was withheld", () {
      final BudgetSankeyLayout chart = layout(
        income: [node("Nómina", 100, income)],
        expenses: [node("Alquiler", 40, expense)],
      );

      expect(chart.taxes, isNull);
      expect(chart.net?.value, 100);
      expect(chart.right.map((d) => d.label), ["Alquiler", "Sobrante"]);
    });

    test("does not invent a surplus when spending matches net", () {
      final BudgetSankeyLayout chart = layout(
        income: [node("Nómina", 100, income)],
        taxes: [node("Impuestos", 20, expense)],
        expenses: [node("Alquiler", 80, expense)],
      );

      expect(chart.net?.value, 80);
      expect(chart.right, hasLength(1));
      expect(chart.right.single.label, "Alquiler");
    });
  });

  group("deficit / zero-income fallback", () {
    test("zero income is from-reserves into expenses, not a fake net", () {
      final BudgetSankeyLayout chart = layout(
        expenses: [node("Alquiler", 50, expense), node("Comida", 30, expense)],
      );

      expect(chart.isClassic, isFalse);
      expect(chart.leftColumnLabel, isNull);
      expect(chart.net, isNull);
      expect(chart.taxes, isNull);
      expect(chart.left, hasLength(1));
      expect(chart.left.single.label, "De reservas");
      expect(chart.left.single.value, 80);
      expect(chart.right.map((d) => d.label), ["Alquiler", "Comida"]);
    });

    test("spending above income keeps taxes on the right", () {
      final BudgetSankeyLayout chart = layout(
        income: [node("Nómina", 40, income)],
        taxes: [node("Impuestos", 10, expense)],
        expenses: [node("Alquiler", 50, expense)],
      );

      expect(chart.isClassic, isFalse);
      expect(chart.net, isNull);
      expect(chart.left.map((d) => d.label), ["Nómina", "De reservas"]);
      expect(chart.left.last.value, 20);
      expect(chart.right.map((d) => d.label), ["Impuestos", "Alquiler"]);
    });
  });
}
