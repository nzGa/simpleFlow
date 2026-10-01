import "package:auto_size_text/auto_size_text.dart";
import "package:spendly/data/money.dart";
import "package:spendly/widgets/general/money_text_builder.dart";
import "package:spendly/widgets/general/money_text_raw.dart";
import "package:flutter/material.dart";

class MoneyText extends StatelessWidget {
  final Money? money;

  /// Ignored. Amounts are never abbreviated.
  final bool initiallyAbbreviated;

  /// Ignored. Tapping does not compact the amount.
  final bool tapToToggleAbbreviation;

  final VoidCallback? onTap;

  final bool displayAbsoluteAmount;
  final bool omitCurrency;

  /// Ignored. ISO codes (ARS, EUR, USD) are always used.
  final bool? overrideUseCurrencySymbol;

  /// When true, renders [AutoSizeText]
  ///
  /// When false, renders [Text]
  final bool autoSize;

  /// Pass an [AutoSizeGroup] to synchronize
  /// fontSize among multiple [AutoSizeText]s
  final AutoSizeGroup? autoSizeGroup;

  /// Set this to [true] to make it always unobscured
  ///
  /// Set this to [false] to make it always obscured
  ///
  /// Set this to [null] to use the default behavior
  final bool? overrideObscure;

  final int maxLines;

  final TextAlign? textAlign;
  final TextStyle? style;

  const MoneyText(
    this.money, {
    super.key,
    this.tapToToggleAbbreviation = false,
    this.autoSize = false,
    this.initiallyAbbreviated = false,
    this.displayAbsoluteAmount = false,
    this.omitCurrency = false,
    this.maxLines = 1,
    this.overrideUseCurrencySymbol,
    this.overrideObscure,
    this.autoSizeGroup,
    this.style,
    this.textAlign,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MoneyTextBuilder(
      money: money,
      abbreviate: false,
      overrideObscure: overrideObscure,
      overrideUseCurrencySymbol: false,
      displayAbsoluteAmount: displayAbsoluteAmount,
      omitCurrency: omitCurrency,
      builder: (context, text, money) {
        return MoneyTextRaw(
          text: text,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          onTap: onTap,
          autoSizeGroup: autoSizeGroup,
          autoSize: autoSize,
        );
      },
    );
  }
}
