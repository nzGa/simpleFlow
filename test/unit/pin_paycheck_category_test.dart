import "package:flow/data/setup/default_categories.dart";
import "package:flow/entity/category.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  Category category({required String name, required String uuid}) {
    return Category.preset(name: name, iconCode: "icon", uuid: uuid);
  }

  test("pins the paycheck preset by uuid", () {
    final Category groceries = category(
      name: "Compra",
      uuid: "9ee43092-34bb-4647-ba43-59b23ba69afe",
    );
    final Category paycheck = category(
      name: "Nómina",
      uuid: paycheckCategoryUuid,
    );

    final List<Category> result = pinPaycheckCategory([groceries, paycheck]);

    expect(result.first.uuid, paycheckCategoryUuid);
    expect(result, hasLength(2));
  });

  test("pins a CSV-imported Nómina by localized name", () {
    final Category groceries = category(
      name: "Compra",
      uuid: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    );
    final Category imported = category(
      name: "Nómina",
      uuid: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    );

    final List<Category> result = pinPaycheckCategory([
      groceries,
      imported,
    ], localizedPaycheckName: "Nómina");

    expect(result.first, imported);
  });

  test("leaves the list alone when there is no paycheck category", () {
    final List<Category> categories = [
      category(name: "Compra", uuid: "9ee43092-34bb-4647-ba43-59b23ba69afe"),
    ];

    expect(pinPaycheckCategory(categories), categories);
  });
}
