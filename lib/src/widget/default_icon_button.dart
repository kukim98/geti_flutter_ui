import 'package:flutter/material.dart';

/// Handy method to return a clickable [CircleAvatar] shaped button.
GestureDetector defaultIconButton({
  required IconData symbol,
  required void Function() onTapFunc,
  double size = 20,
  Color? iconBackgroundColor,
}){
  return GestureDetector(
    onTap: onTapFunc,
    child: CircleAvatar(
      backgroundColor: iconBackgroundColor,
      child: Icon(
        symbol,
        size: size,
        color: const Color(0xff000000)
      )
    )
  );
}