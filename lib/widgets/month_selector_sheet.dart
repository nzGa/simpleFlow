import "package:spendly/l10n/flow_localizations.dart";
import "package:spendly/widgets/general/button.dart";
import "package:spendly/widgets/general/modal_overflow_bar.dart";
import "package:spendly/widgets/general/modal_sheet.dart";
import "package:spendly/widgets/sheets/month_selector_sheet/month_button.dart";
import "package:spendly/widgets/year_selector_bar.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";

class MonthSelectorSheet extends StatefulWidget {
  final DateTime? initialDate;

  const MonthSelectorSheet({super.key, this.initialDate});

  @override
  State<MonthSelectorSheet> createState() => _MonthSelectorSheetState();
}

class _MonthSelectorSheetState extends State<MonthSelectorSheet> {
  late int year;
  late int month;

  @override
  void initState() {
    super.initState();

    final DateTime current = widget.initialDate ?? DateTime.now();
    year = current.year;
    month = current.month;
  }

  @override
  Widget build(BuildContext context) {
    return ModalSheet(
      title: Text("select.time.select.month".t(context)),
      trailing: ModalOverflowBar(
        alignment: .end,
        children: [
          TextButton(
            onPressed: () => setState(() {
              final DateTime now = DateTime.now();
              year = now.year;
              month = now.month;
            }),
            child: Text("select.time.now".t(context)),
          ),
          Button(onTap: pop, child: Text("general.done".t(context))),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YearSelectorBar(year: year, onUpdate: updateYear),
          const SizedBox(height: 16.0),
          MonthsGrid(
            onTap: updateMonth,
            currentMonth: month,
            currentYear: year,
          ),
        ],
      ),
    );
  }

  void updateYear(int newYear) {
    setState(() {
      year = newYear;
    });
  }

  void updateMonth(int newMonth) {
    assert(month >= 1 && month <= 12);

    setState(() {
      month = newMonth;
    });
  }

  void pop() {
    context.pop(DateTime(year, month));
  }
}

class MonthsGrid extends StatelessWidget {
  final int currentYear;
  final int currentMonth;
  final Function(int) onTap;

  const MonthsGrid({
    super.key,
    required this.onTap,
    required this.currentYear,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in [1, 4, 7, 10]) ...[
          if (row != 1) const SizedBox(height: 12.0),
          Row(
            children: [
              for (int i = row; i < row + 3; i++) ...[
                if (i != row) const SizedBox(width: 12.0),
                Expanded(
                  child: MonthButton(
                    currentDate: DateTime(currentYear, currentMonth),
                    month: DateTime(currentYear, i),
                    onTap: () => onTap(i),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
