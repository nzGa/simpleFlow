import "dart:math";

import "package:spendly/data/flow_button_type.dart";
import "package:spendly/entity/user_preferences.dart";
import "package:spendly/l10n/named_enum.dart";
import "package:spendly/services/user_preferences.dart";
import "package:spendly/theme/navbar_theme.dart";
import "package:spendly/theme/theme.dart";
import "package:spendly/utils/extensions/directionality.dart";
import "package:flutter/material.dart" hide Flow;
import "package:material_symbols_icons_flow/symbols.dart";
import "package:pie_menu/pie_menu.dart";

class NewTransactionButton extends StatefulWidget {
  final Function(FlowButtonType type) onActionTap;

  const NewTransactionButton({super.key, required this.onActionTap});

  @override
  State<NewTransactionButton> createState() => _NewTransactionButtonState();
}

class _NewTransactionButtonState extends State<NewTransactionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final _bounceAnimation = Tween(begin: 0.0, end: (45.0 / 180) * pi)
      .animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
          reverseCurve: Curves.easeIn,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final NavbarTheme navbarTheme = Theme.of(context).extension<NavbarTheme>()!;

    return AnimatedBuilder(
      animation: UserPreferencesService().valueNotifier,
      builder: (context, _) {
        final UserPreferences userPreferences = UserPreferencesService().value;

        final List<FlowButtonType> buttonOrder =
            (context.isLtr
                    ? userPreferences.transactionButtonOrder
                    : userPreferences.transactionButtonOrder.reversed)
                .where(
                  (type) =>
                      type != FlowButtonType.eny &&
                      type != FlowButtonType.transfer,
                )
                .toList();

        return PieMenu(
          theme: context.pieTheme.copyWith(
            customAngle: 90.0,
            customAngleDiff: 48.0,
            radius: 108.0,
            customAngleAnchor: PieAnchor.center,
            leftClickShowsMenu: true,
            rightClickShowsMenu: true,
            regularPressShowsMenu: true,
            childBounceEnabled: false,
            pieBounceDuration: .zero,
            longPressDuration: .zero,
            longPressShowsMenu: true,
          ),
          onToggle: onToggle,
          actions: buttonOrder
              .map(
                (transactionType) => PieAction(
                  tooltip: Text(transactionType.localizedNameContext(context)),
                  onSelect: () => widget.onActionTap(transactionType),
                  child: Icon(transactionType.icon, weight: 800.0),
                  buttonTheme: PieButtonTheme(
                    backgroundColor: transactionType.actionBackgroundColor(
                      context,
                    ),
                    iconColor: transactionType.actionColor(context),
                  ),
                ),
              )
              .toList(),
          child: Material(
            color: navbarTheme.transactionButtonBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: .circular(32.0)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _bounceAnimation.value,
                    child: child,
                  );
                },
                child: Icon(
                  Symbols.add_rounded,
                  fill: 0.0,
                  color: navbarTheme.transactionButtonForegroundColor,
                  weight: 600.0,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void onToggle(bool toggled) {
    if (toggled) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
}
