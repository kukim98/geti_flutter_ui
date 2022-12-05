import 'package:flutter/material.dart';

class OnOffIconButton extends StatefulWidget {
  final dynamic symbol;
  final void Function() onTapFunc;
  final double size;
  final Color? iconColor;
  final Color? onIconBackgroundColor;
  final Color? offIconBackgroundColor;

  const OnOffIconButton({
    super.key, 
    required this.symbol,
    required this.onTapFunc,
    this.size = 20,
    this.iconColor = Colors.white,
    this.onIconBackgroundColor,
    this.offIconBackgroundColor
  });

  @override
  State<OnOffIconButton> createState() => _OnOffIconButtonState();
}

class _OnOffIconButtonState extends State<OnOffIconButton> {
  ValueNotifier<bool> onOffController = ValueNotifier(false);

  Widget iconBuilder() {
    if (widget.symbol is IconData) {
      return Icon(
        widget.symbol,
        size: widget.size,
        color: widget.iconColor
      );
    }
    else if (widget.symbol is Widget) {
      return widget.symbol;
    }
    else {
      throw const FormatException('symbol must be of type IconData or Icon');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: onOffController,
      child: iconBuilder(),
      builder: (context, value, child) {
        return GestureDetector(
          onTap: () {
            widget.onTapFunc();
            onOffController.value = !onOffController.value;
          },
          child: CircleAvatar(
            backgroundColor: (value) ? widget.onIconBackgroundColor : widget.offIconBackgroundColor,
            child: child
          )
        );
      },
    );
  }
}
