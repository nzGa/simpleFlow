import "package:flow/data/setup/default_categories.dart";
import "package:flow/entity/category.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Category category({
    required String name,
    required String uuid,
    bool isIncome = false,
  }) {
    return Category.preset(
      name: name,
      iconCode: "icon",
      uuid: uuid,
      isIncome: isIncome,
    );
  }

  test("detects Nómina, Paycheck, and Salary as income names", () {
    expect(isIncomeCategoryName("Nómina"), isTrue);
    expect(isIncomeCategoryName("nomina"), isTrue);
    expect(isIncomeCategoryName("Paycheck"), isTrue);
    expect(isIncomeCategoryName("Paychecks"), isTrue);
    expect(isIncomeCategoryName("Salary"), isTrue);
    expect(isIncomeCategoryName("Compra"), isFalse);
    expect(isIncomeCategoryName("Servicios"), isFalse);
  });

  test("marks paycheck UUID and Nómina name as income", () {
    final Category groceries = category(
      name: "Compra",
      uuid: "9ee43092-34bb-4647-ba43-59b23ba69afe",
    );
    final Category paycheck = category(
      name: "Paycheck",
      uuid: paycheckCategoryUuid,
    );
    final Category imported = category(
      name: "Nómina",
      uuid: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    );

    markIncomeCategories([groceries, paycheck, imported]);

    expect(groceries.isIncome, isFalse);
    expect(paycheck.isIncome, isTrue);
    expect(imported.isIncome, isTrue);
    expect(categoryIsIncome(groceries), isFalse);
    expect(categoryIsIncome(imported), isTrue);
  });

  test("paycheck preset is flagged as income", () {
    final Category paycheck = category(
      name: "Nómina",
      uuid: paycheckCategoryUuid,
      isIncome: true,
    );

    expect(paycheck.isIncome, isTrue);
  });

  test("treats unmigrated Nómina as income by name", () {
    final Category imported = category(
      name: "Nómina",
      uuid: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    );

    expect(imported.isIncome, isFalse);
    expect(categoryIsIncome(imported), isTrue);
  });
}
