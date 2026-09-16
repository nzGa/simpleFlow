import "package:flow/data/setup/default_categories.dart";
import "package:flow/entity/category.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Category category({required String name, required String uuid}) {
    return Category.preset(name: name, iconCode: "icon", uuid: uuid);
  }

  test("detects Impuestos and Taxes by name", () {
    expect(isTaxCategoryName("Impuestos"), isTrue);
    expect(isTaxCategoryName("impuesto"), isTrue);
    expect(isTaxCategoryName("Taxes"), isTrue);
    expect(isTaxCategoryName("Tax"), isTrue);
    expect(isTaxCategoryName("Steuern"), isTrue);
    expect(isTaxCategoryName("Compra"), isFalse);
    expect(isTaxCategoryName("Taxi"), isFalse);
  });

  test("preset UUID is treated as tax even with another name", () {
    final Category renamed = category(
      name: "Hacienda",
      uuid: taxesCategoryUuid,
    );
    final Category groceries = category(
      name: "Compra",
      uuid: "9ee43092-34bb-4647-ba43-59b23ba69afe",
    );

    expect(categoryIsTax(renamed), isTrue);
    expect(categoryIsTax(groceries), isFalse);
    expect(categoryIsTax(null), isFalse);
  });
}
