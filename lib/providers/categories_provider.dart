import "dart:async";

import "package:flow/data/prefs/frecency_group.dart";
import "package:flow/data/setup/default_categories.dart";
import "package:flow/entity/category.dart";
import "package:flow/entity/transaction/type.dart";
import "package:flow/objectbox.dart";
import "package:flow/objectbox/objectbox.g.dart";
import "package:flow/prefs/transitive.dart";
import "package:flow/utils/extensions/iterables.dart";
import "package:flutter/material.dart";

class CategoriesProviderScope extends StatefulWidget {
  final Widget child;

  const CategoriesProviderScope({super.key, required this.child});

  @override
  State<CategoriesProviderScope> createState() =>
      _CategoriesProviderScopeState();
}

class _CategoriesProviderScopeState extends State<CategoriesProviderScope> {
  QueryBuilder<Category> _queryBuilder() => ObjectBox().box<Category>().query();
  late final StreamSubscription _subscription;

  List<Category>? _categories;

  @override
  void initState() {
    super.initState();
    _subscription = _queryBuilder()
        .watch(triggerImmediately: true)
        .listen(onData);
  }

  void onData(Query<Category> query) {
    setState(() {
      _categories = query.find();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CategoriesProvider(_categories, child: widget.child);
}

class CategoriesProvider extends InheritedWidget {
  final List<Category>? _categories;

  bool get ready => _categories != null;

  /// All categories sorted by combined (income + expense) frecency.
  /// Use [categoriesFor] when assigning a category to a transaction.
  List<Category> get categories => categoriesFor(null);

  /// Categories matching [type], sorted by frecency for that type.
  ///
  /// Income transactions only see [Category.isIncome] categories (Nómina
  /// and user-created income cats). Expenses hide those. Pass null for
  /// mixed/unknown (bulk edits) to list every category.
  List<Category> categoriesFor(TransactionType? type) {
    final List<Category> list = _categories ?? const [];
    if (list.isEmpty) return list;

    final List<Category> filtered = switch (type) {
      TransactionType.income => list.where(categoryIsIncome).toList(),
      TransactionType.expense =>
        list.where((category) => !categoryIsIncome(category)).toList(),
      _ => list,
    };
    if (filtered.isEmpty) return filtered;

    final List<String> frecencyKeys =
        TransitiveLocalPreferences.categoryFrecencyTypesFor(type);

    final FrecencyGroup frecencyGroup = FrecencyGroup(
      filtered
          .expand(
            (category) => frecencyKeys.map(
              (key) => TransitiveLocalPreferences().getFrecencyData(
                key,
                category.uuid,
              ),
            ),
          )
          .nonNulls
          .toList(),
    );

    return [...filtered]..sort(
      (a, b) => frecencyGroup
          .getScore(b.uuid)
          .compareTo(frecencyGroup.getScore(a.uuid)),
    );
  }

  List<String> get uuids =>
      categories.map((category) => category.uuid).toList();

  String? getName(dynamic id) => get(id)?.name;

  Category? get(dynamic id) => switch (id) {
    String uuid => _categories?.firstWhereOrNull(
      (category) => category.uuid == uuid,
    ),
    int id => _categories?.firstWhereOrNull((category) => category.id == id),
    Category category => _categories?.firstWhereOrNull(
      (element) => element.id == category.id,
    ),
    _ => null,
  };

  const CategoriesProvider(this._categories, {super.key, required super.child});

  static CategoriesProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CategoriesProvider>()!;

  @override
  bool updateShouldNotify(CategoriesProvider oldWidget) =>
      !identical(_categories, oldWidget._categories);
}
