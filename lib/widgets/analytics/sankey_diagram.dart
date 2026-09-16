import "dart:math" as math;

import "package:flow/theme/theme.dart";
import "package:flutter/material.dart";

/// One node on a [SankeyDiagram] column.
class SankeyDatum {
  final String label;

  /// Positive magnitude in the diagram's currency.
  final double value;

  final Color color;

  const SankeyDatum({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Classic budget Sankey: gross on the left, optional tax peel, net in
/// the middle, and expense categories (+ surplus) on the right.
///
/// When [net] is null the painter falls back to a two-column flow
/// (deficit / "From reserves") so a month with no income stays readable.
class BudgetSankeyLayout {
  final List<SankeyDatum> left;
  final List<SankeyDatum> right;

  /// Label for the whole left column ("Gross income"). Null means each
  /// left node keeps its own label (deficit stacks).
  final String? leftColumnLabel;

  final SankeyDatum? taxes;
  final SankeyDatum? net;

  const BudgetSankeyLayout({
    required this.left,
    required this.right,
    this.leftColumnLabel,
    this.taxes,
    this.net,
  });

  bool get isClassic => net != null;

  bool get isEmpty => left.isEmpty || right.isEmpty;
}

/// Builds the closest classic budget Sankey the numbers support.
///
/// * Surplus month: left = income stacks labeled as gross, optional tax
///   peel, net in the middle, expenses + surplus on the right.
/// * Deficit / zero income: no net bar. Left is income (if any) plus
///   "From reserves"; taxes stay with the other expenses on the right.
BudgetSankeyLayout buildBudgetSankeyLayout({
  required List<SankeyDatum> income,
  required List<SankeyDatum> expenses,
  required List<SankeyDatum> taxes,
  required Color netColor,
  required Color surplusColor,
  required Color deficitColor,
  required Color taxColor,
  required String grossLabel,
  required String netLabel,
  required String surplusLabel,
  required String fromReservesLabel,
  required String taxesLabel,
}) {
  final double incomeSum = sankeySum(income);
  final double taxSum = sankeySum(taxes);
  final double expenseSum = sankeySum(expenses) + taxSum;
  final double largest = incomeSum > expenseSum ? incomeSum : expenseSum;
  final double threshold = largest * 0.001;

  if (incomeSum <= 0 && expenseSum <= 0) {
    return const BudgetSankeyLayout(left: [], right: []);
  }

  final SankeyDatum? taxNode = _combineTaxes(taxes, taxesLabel, taxColor);

  final bool hasIncome = incomeSum > threshold;
  final bool inDeficit = expenseSum > incomeSum + threshold;

  if (!hasIncome || inDeficit) {
    final List<SankeyDatum> left = [...income];
    final double gap = expenseSum - incomeSum;
    if (gap > threshold) {
      left.add(
        SankeyDatum(label: fromReservesLabel, value: gap, color: deficitColor),
      );
    }
    return BudgetSankeyLayout(left: left, right: [?taxNode, ...expenses]);
  }

  final double netValue = incomeSum - taxSum;
  final List<SankeyDatum> right = [...expenses];
  final double surplus = netValue - sankeySum(expenses);
  if (surplus > threshold) {
    right.add(
      SankeyDatum(label: surplusLabel, value: surplus, color: surplusColor),
    );
  }

  if (netValue <= threshold) {
    return BudgetSankeyLayout(
      left: income,
      leftColumnLabel: grossLabel,
      right: [?taxNode, ...right],
    );
  }

  return BudgetSankeyLayout(
    left: income,
    leftColumnLabel: grossLabel,
    taxes: taxSum > threshold ? taxNode : null,
    net: SankeyDatum(label: netLabel, value: netValue, color: netColor),
    right: right,
  );
}

SankeyDatum? _combineTaxes(
  List<SankeyDatum> taxes,
  String fallbackLabel,
  Color color,
) {
  if (taxes.isEmpty) return null;
  final double value = sankeySum(taxes);
  if (value <= 0) return null;
  return SankeyDatum(
    label: taxes.length == 1 ? taxes.first.label : fallbackLabel,
    value: value,
    color: color,
  );
}

/// Teal/cyan family for income sources (left bars).
///
/// Chart-only override: category icon colors often collide across sides
/// (a green income vs surplus, a mauve income vs rent). Surplus
/// ("Sobrante") must use the theme income color instead — it is not in
/// this list.
List<Color> sankeyIncomePalette(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const [
      Color(0xFF2DD4BF),
      Color(0xFF22D3EE),
      Color(0xFF60A5FA),
      Color(0xFF2E90B8),
    ];
  }
  return const [
    Color(0xFF0F766E),
    Color(0xFF0E7490),
    Color(0xFF1D4ED8),
    Color(0xFF155E75),
  ];
}

/// Warm red/orange family for expense categories (right bars).
///
/// Distinct from [sankeyIncomePalette] so left vs right reads at a
/// glance. Surplus is not in this list either.
List<Color> sankeyExpensePalette(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const [
      Color(0xFFFB923C),
      Color(0xFFF87171),
      Color(0xFFEAB308),
      Color(0xFFF97316),
      Color(0xFFEF4444),
      Color(0xFFD97706),
    ];
  }
  return const [
    Color(0xFFC2410C),
    Color(0xFFB91C1C),
    Color(0xFFB45309),
    Color(0xFFDC2626),
    Color(0xFF9A3412),
    Color(0xFFCA8A04),
  ];
}

/// Color for the middle net-income bar. Matches the first income swatch
/// so a single paycheck still reads as one continuous stream.
Color sankeyNetColor(Brightness brightness) =>
    sankeyIncomePalette(brightness).first;

/// Withholding / taxes peel — rose, kept out of both palettes.
Color sankeyTaxColor(Brightness brightness) {
  if (brightness == Brightness.dark) {
    return const Color(0xFFFB7185);
  }
  return const Color(0xFF9F1239);
}

/// A two- or three-column cash-flow Sankey.
///
/// Pass [net] (and optional [taxes]) for the classic budget layout:
/// stacked gross on the left, tax peel, net in the middle, expenses
/// fanning out on the right. Omit [net] for a two-column flow used
/// when income is missing or spending exceeds income.
class SankeyDiagram extends StatelessWidget {
  final List<SankeyDatum> sources;
  final List<SankeyDatum> targets;
  final String? sourceColumnLabel;
  final SankeyDatum? taxes;
  final SankeyDatum? net;
  final double height;

  const SankeyDiagram({
    super.key,
    required this.sources,
    required this.targets,
    this.sourceColumnLabel,
    this.taxes,
    this.net,
    this.height = 280.0,
  });

  factory SankeyDiagram.fromLayout({
    Key? key,
    required BudgetSankeyLayout layout,
    double height = 280.0,
  }) {
    return SankeyDiagram(
      key: key,
      sources: layout.left,
      targets: layout.right,
      sourceColumnLabel: layout.leftColumnLabel,
      taxes: layout.taxes,
      net: layout.net,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle labelStyle =
        context.textTheme.labelSmall?.copyWith(
          color: context.colorScheme.onSurface.withAlpha(0xcc),
        ) ??
        TextStyle(fontSize: 11.0, color: context.colorScheme.onSurface);

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SankeyPainter(
          sources: sources,
          targets: targets,
          sourceColumnLabel: sourceColumnLabel,
          taxes: taxes,
          net: net,
          labelStyle: labelStyle,
        ),
      ),
    );
  }
}

/// Horizontal gutter reserved for node labels on each side of the chart.
@visibleForTesting
double sankeyLabelGutter(double width) =>
    (width * 0.26).clamp(72.0, 128.0).toDouble();

/// X positions of the left / optional middle / right node columns.
@visibleForTesting
({double left, double? middle, double right}) sankeyColumnXs(
  double width, {
  required bool hasMiddle,
}) {
  final double gutter = sankeyLabelGutter(width);
  const double nodeWidth = 12.0;
  return (
    left: gutter,
    middle: hasMiddle ? (width - nodeWidth) / 2 : null,
    right: width - gutter - nodeWidth,
  );
}

/// Stacks [values] into node rects along [height], leaving [gap] between
/// them. Each rect is [nodeWidth] wide at [x], starting at [y].
@visibleForTesting
List<Rect> stackSankeyNodes({
  required List<double> values,
  required double total,
  required double x,
  required double height,
  double y = 0.0,
  double nodeWidth = 12.0,
  double gap = 6.0,
}) {
  if (values.isEmpty || total <= 0 || height <= 0) {
    return const [];
  }

  final double usable = (height - (values.length - 1) * gap)
      .clamp(0.0, height)
      .toDouble();
  final double scale = usable / total;
  double cursor = y;
  final List<Rect> rects = <Rect>[];

  for (final double value in values) {
    final double nodeHeight = value * scale;
    rects.add(Rect.fromLTWH(x, cursor, nodeWidth, nodeHeight));
    cursor += nodeHeight + gap;
  }

  return rects;
}

@visibleForTesting
double sankeySum(List<SankeyDatum> data) =>
    data.fold(0.0, (sum, datum) => sum + datum.value);

/// Ribbons follow **destination** color on the outflow side so each
/// expense/surplus stream matches its right-hand bar. The tax peel uses
/// the tax color; the gross→net band uses the net color.
class _SankeyPainter extends CustomPainter {
  final List<SankeyDatum> sources;
  final List<SankeyDatum> targets;
  final String? sourceColumnLabel;
  final SankeyDatum? taxes;
  final SankeyDatum? net;
  final TextStyle labelStyle;

  static const double _nodeWidth = 12.0;
  static const double _gap = 6.0;
  static const int _ribbonAlpha = 0x99;

  _SankeyPainter({
    required this.sources,
    required this.targets,
    required this.sourceColumnLabel,
    required this.taxes,
    required this.net,
    required this.labelStyle,
  });

  bool get _isClassic => net != null;

  @override
  void paint(Canvas canvas, Size size) {
    final double sourceSum = sankeySum(sources);
    final double targetSum = sankeySum(targets);
    final double total = sourceSum > targetSum ? sourceSum : targetSum;

    if (total <= 0 || sources.isEmpty || targets.isEmpty) return;

    final double height = size.height;
    final columns = sankeyColumnXs(size.width, hasMiddle: _isClassic);
    final double sourceGap = sourceColumnLabel != null ? 0.0 : _gap;

    final List<Rect> sourceNodes = stackSankeyNodes(
      values: sources.map((s) => s.value).toList(),
      total: _isClassic ? sourceSum : total,
      x: columns.left,
      height: height,
      nodeWidth: _nodeWidth,
      gap: sourceGap,
    );

    if (sourceNodes.isEmpty) return;

    if (_isClassic) {
      _paintBudget(canvas, sourceNodes, columns, height);
      return;
    }

    final List<Rect> targetNodes = stackSankeyNodes(
      values: targets.map((t) => t.value).toList(),
      total: total,
      x: columns.right,
      height: height,
      nodeWidth: _nodeWidth,
      gap: _gap,
    );
    if (targetNodes.isEmpty) return;

    _paintDirect(canvas, sourceNodes, targetNodes, sourceSum, targetSum);
    _drawStackedColumn(canvas, sourceNodes, sources);
    _drawNodes(canvas, targetNodes, targets);
    _drawSideLabels(
      canvas,
      sourceNodes,
      targetNodes,
      sankeyLabelGutter(size.width),
      height,
    );
  }

  void _paintBudget(
    Canvas canvas,
    List<Rect> sourceNodes,
    ({double left, double? middle, double right}) columns,
    double height,
  ) {
    final SankeyDatum netNode = net!;
    final double grossSum = sankeySum(sources);
    final double middleX = columns.middle!;

    final List<double> middleValues = [
      if (taxes != null) taxes!.value,
      netNode.value,
    ];
    final List<Rect> middleNodes = stackSankeyNodes(
      values: middleValues,
      total: grossSum,
      x: middleX,
      height: height,
      nodeWidth: _nodeWidth,
      gap: _gap,
    );
    if (middleNodes.isEmpty) return;

    int mid = 0;
    Rect? taxRect;
    if (taxes != null) {
      taxRect = middleNodes[mid++];
    }
    if (mid >= middleNodes.length) return;
    final Rect netRect = middleNodes[mid];

    final List<Rect> targetNodes = stackSankeyNodes(
      values: targets.map((t) => t.value).toList(),
      total: netNode.value,
      x: columns.right,
      y: netRect.top,
      height: netRect.height,
      nodeWidth: _nodeWidth,
      gap: _gap,
    );
    if (targetNodes.isEmpty) return;

    final Rect gross = _union(sourceNodes);
    double cursor = gross.top;
    if (taxRect != null && taxes != null) {
      final double slice = gross.height * (taxes!.value / grossSum);
      _drawRibbon(
        canvas,
        gross.right,
        taxRect.left,
        cursor,
        cursor + slice,
        taxRect.top,
        taxRect.bottom,
        taxes!.color,
      );
      cursor += slice;
    }
    _drawRibbon(
      canvas,
      gross.right,
      netRect.left,
      cursor,
      gross.bottom,
      netRect.top,
      netRect.bottom,
      netNode.color,
    );

    double netCursor = netRect.top;
    for (int i = 0; i < targets.length; i++) {
      final double slice = netRect.height * (targets[i].value / netNode.value);
      final Rect node = targetNodes[i];
      _drawRibbon(
        canvas,
        netRect.right,
        node.left,
        netCursor,
        netCursor + slice,
        node.top,
        node.bottom,
        targets[i].color,
      );
      netCursor += slice;
    }

    _drawStackedColumn(canvas, sourceNodes, sources);
    if (taxRect != null && taxes != null) {
      _drawNodes(canvas, [taxRect], [taxes!]);
    }
    _drawNodes(canvas, [netRect], [netNode]);
    _drawNodes(canvas, targetNodes, targets);

    final double leftGutter = columns.left;
    final double midGutter = (middleX - gross.right).clamp(48.0, 128.0);
    final double rightGutter = leftGutter;

    if (sourceColumnLabel != null) {
      _drawLabel(
        canvas,
        sourceColumnLabel!,
        gross,
        leftGutter,
        onLeft: true,
        boundsHeight: height,
      );
    } else {
      for (int i = 0; i < sources.length; i++) {
        _drawLabel(
          canvas,
          sources[i].label,
          sourceNodes[i],
          leftGutter,
          onLeft: true,
          boundsHeight: height,
        );
      }
    }

    if (taxRect != null && taxes != null) {
      _drawLabel(
        canvas,
        taxes!.label,
        taxRect,
        midGutter,
        onLeft: true,
        boundsHeight: height,
      );
    }
    _drawLabel(
      canvas,
      netNode.label,
      netRect,
      midGutter,
      onLeft: true,
      boundsHeight: height,
    );

    for (int i = 0; i < targets.length; i++) {
      _drawLabel(
        canvas,
        targets[i].label,
        targetNodes[i],
        rightGutter,
        onLeft: false,
        boundsHeight: height,
      );
    }
  }

  /// 1-to-many (or many-to-1): color ribbons by the fanning side so a
  /// single origin does not flood the chart with one slab of color.
  ///
  /// Many-to-many (income + from-reserves into several expenses) fans
  /// from the whole left column instead of a solid center hub.
  void _paintDirect(
    Canvas canvas,
    List<Rect> sourceNodes,
    List<Rect> targetNodes,
    double sourceSum,
    double targetSum,
  ) {
    if (targets.length == 1 && sources.length > 1) {
      final Rect sink = targetNodes.first;
      double cursor = sink.top;
      for (int i = 0; i < sources.length; i++) {
        final double slice = sink.height * (sources[i].value / targetSum);
        final Rect node = sourceNodes[i];
        _drawRibbon(
          canvas,
          node.right,
          sink.left,
          node.top,
          node.bottom,
          cursor,
          cursor + slice,
          sources[i].color,
        );
        cursor += slice;
      }
      return;
    }

    final Rect origin = _union(sourceNodes);
    double cursor = origin.top;
    for (int i = 0; i < targets.length; i++) {
      final double slice = origin.height * (targets[i].value / sourceSum);
      final Rect node = targetNodes[i];
      _drawRibbon(
        canvas,
        origin.right,
        node.left,
        cursor,
        cursor + slice,
        node.top,
        node.bottom,
        targets[i].color,
      );
      cursor += slice;
    }
  }

  void _drawRibbon(
    Canvas canvas,
    double xLeft,
    double xRight,
    double topLeft,
    double bottomLeft,
    double topRight,
    double bottomRight,
    Color color,
  ) {
    final double midX = (xLeft + xRight) / 2;
    final Path path = Path()
      ..moveTo(xLeft, topLeft)
      ..cubicTo(midX, topLeft, midX, topRight, xRight, topRight)
      ..lineTo(xRight, bottomRight)
      ..cubicTo(midX, bottomRight, midX, bottomLeft, xLeft, bottomLeft)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color.withAlpha(_ribbonAlpha),
    );
  }

  void _drawStackedColumn(
    Canvas canvas,
    List<Rect> rects,
    List<SankeyDatum> nodes,
  ) {
    if (rects.isEmpty) return;
    if (rects.length == 1) {
      _drawNodes(canvas, rects, nodes);
      return;
    }

    final Rect bounds = _union(rects);
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(3.0)),
    );
    for (int i = 0; i < rects.length; i++) {
      canvas.drawRect(rects[i], Paint()..color = nodes[i].color);
    }
    canvas.restore();
  }

  void _drawNodes(Canvas canvas, List<Rect> rects, List<SankeyDatum> nodes) {
    for (int i = 0; i < rects.length; i++) {
      final RRect rounded = RRect.fromRectAndRadius(
        rects[i],
        const Radius.circular(3.0),
      );
      canvas.drawRRect(rounded, Paint()..color = nodes[i].color);
    }
  }

  void _drawSideLabels(
    Canvas canvas,
    List<Rect> sourceNodes,
    List<Rect> targetNodes,
    double gutter,
    double height,
  ) {
    if (sourceColumnLabel != null) {
      _drawLabel(
        canvas,
        sourceColumnLabel!,
        _union(sourceNodes),
        gutter,
        onLeft: true,
        boundsHeight: height,
      );
    } else {
      for (int i = 0; i < sources.length; i++) {
        _drawLabel(
          canvas,
          sources[i].label,
          sourceNodes[i],
          gutter,
          onLeft: true,
          boundsHeight: height,
        );
      }
    }
    for (int i = 0; i < targets.length; i++) {
      _drawLabel(
        canvas,
        targets[i].label,
        targetNodes[i],
        gutter,
        onLeft: false,
        boundsHeight: height,
      );
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Rect node,
    double gutter, {
    required bool onLeft,
    required double boundsHeight,
  }) {
    if (text.isEmpty || gutter <= 8.0) return;

    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: "…",
    )..layout(maxWidth: gutter - 8.0);

    final double y = (node.center.dy - painter.height / 2)
        .clamp(0.0, math.max(0.0, boundsHeight - painter.height))
        .toDouble();
    final double x = onLeft
        ? node.left - 6.0 - painter.width
        : node.right + 6.0;
    painter.paint(canvas, Offset(x, y));
  }

  Rect _union(List<Rect> rects) => Rect.fromLTRB(
    rects.first.left,
    rects.first.top,
    rects.last.right,
    rects.last.bottom,
  );

  @override
  bool shouldRepaint(covariant _SankeyPainter oldDelegate) {
    return oldDelegate.sources != sources ||
        oldDelegate.targets != targets ||
        oldDelegate.sourceColumnLabel != sourceColumnLabel ||
        oldDelegate.taxes != taxes ||
        oldDelegate.net != net ||
        oldDelegate.labelStyle != labelStyle;
  }
}
