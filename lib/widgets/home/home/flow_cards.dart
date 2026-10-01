import "package:auto_size_text/auto_size_text.dart";
import "package:spendly/data/money.dart";
import "package:spendly/entity/transaction.dart";
import "package:spendly/l10n/named_enum.dart";
import "package:spendly/theme/theme.dart";
import "package:spendly/widgets/general/money_text.dart";
import "package:spendly/widgets/home/home/info_card.dart";
import "package:flutter/cupertino.dart";

class FlowCards extends StatefulWidget {
  final Money? totalIncome;
  final Money? totalExpense;

  const FlowCards({
    super.key,
    required this.totalExpense,
    required this.totalIncome,
  });

  @override
  State<FlowCards> createState() => _FlowCardsState();
}

class _FlowCardsState extends State<FlowCards> {
  final AutoSizeGroup autoSizeGroup = AutoSizeGroup();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InfoCard(
            title: TransactionType.income.localizedNameContext(context),
            icon: Icon(
              TransactionType.income.icon,
              color: TransactionType.income.color(context),
            ),
            money: styledMoney(widget.totalIncome, context),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: InfoCard(
            title: TransactionType.expense.localizedNameContext(context),
            icon: Icon(
              TransactionType.expense.icon,
              color: TransactionType.expense.color(context),
            ),
            money: styledMoney(widget.totalExpense, context),
          ),
        ),
      ],
    );
  }

  Widget styledMoney(Money? amount, BuildContext context) {
    return Container(
      height: MediaQuery.of(context).textScaler.scale(
        context.textTheme.displaySmall!.fontSize! *
            context.textTheme.displaySmall!.height!,
      ),
      alignment: AlignmentDirectional.centerStart,
      child: MoneyText(
        amount,
        style: context.textTheme.displaySmall,
        autoSizeGroup: autoSizeGroup,
        autoSize: true,
      ),
    );
  }
}
