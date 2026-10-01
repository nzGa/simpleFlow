import "package:spendly/l10n/extensions.dart";
import "package:spendly/theme/flow_color_scheme.dart";
import "package:spendly/theme/flow_theme_group.dart";
import "package:spendly/utils/optional.dart";
import "package:spendly/widgets/general/modal_overflow_bar.dart";
import "package:spendly/widgets/general/modal_sheet.dart";
import "package:spendly/widgets/theme_petal_selector.dart";
import "package:flutter/material.dart";
import "package:go_router/go_router.dart";
import "package:material_symbols_icons_flow/symbols.dart";

/// Pops with a [Optional<ColorScheme>].
class SelectColorSchemeSheet extends StatefulWidget {
  final FlowThemeGroup group;
  final String? initialScheme;

  const SelectColorSchemeSheet({
    super.key,
    required this.group,
    this.initialScheme,
  });

  @override
  State<SelectColorSchemeSheet> createState() => _SelectColorSchemeSheetState();
}

class _SelectColorSchemeSheetState extends State<SelectColorSchemeSheet> {
  @override
  Widget build(BuildContext context) {
    return ModalSheet.scrollable(
      trailing: ModalOverflowBar(
        alignment: .end,
        children: [
          TextButton.icon(
            onPressed: () => context.pop(const Optional<FlowColorScheme>(null)),
            icon: const Icon(Symbols.block_rounded, fill: 0.0),
            label: Text("select.color.clear".t(context)),
          ),
        ],
      ),
      child: ThemePetalSelector(
        groups: [widget.group],
        onChanged: (FlowColorScheme value) {
          context.pop(Optional<FlowColorScheme>(value));
        },
      ),
    );
  }
}
