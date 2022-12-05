import 'package:flutter/material.dart';

/// Handy method to return a clickable [CircleAvatar] shaped button.
GestureDetector defaultIconButton({
  required Icon icon,
  required void Function() onTapFunc,
  double size = 20,
  Color? iconBackgroundColor,
}){
  return GestureDetector(
    onTap: onTapFunc,
    child: CircleAvatar(
      backgroundColor: iconBackgroundColor,
      child: icon
    )
  );
}