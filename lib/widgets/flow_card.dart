import "package:auto_size_text/auto_size_text.dart";
import "package:spendly/data/money.dart";
import "package:spendly/entity/transaction.dart";
import "package:spendly/theme/theme.dart";
import "package:spendly/widgets/general/surface.dart";
import "package:flutter/material.dart";

class FlowCard extends StatelessWidget {
  final AutoSizeGroup? autoSizeGroup;

  final TransactionType type;
  final Money flow;

  const FlowCard({
    super.key,
    required this.flow,
    required this.type,
    this.autoSizeGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Surface(
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).textScaler.scale(
              context.textTheme.displaySmall!.height! *
                      context.textTheme.displaySmall!.fontSize! +
                  24.0,
            ),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: AutoSizeText(
            flow.abs().formatted,
            style: context.textTheme.displaySmall?.copyWith(
              color: type.color(context),
            ),
            minFontSize: 10.0,
            maxLines: 1,
            group: autoSizeGroup,
          ),
        );
      },
    );
  }
}
