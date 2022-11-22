import 'package:flutter/material.dart';

/// An [AppBar] with two states.
/// When [isOn] is true, [onAppbar] gets displayed and [offAppbar] when [isOn] is false
/// [BimodalDynamicAppBar.]
///
/// [@author	Kwangeon Kim]
/// [ @since	v0.0.1 ]
/// [@version	v1.0.0	Thursday, July 7th, 2022]
/// [@see		StatefulWidget]
/// [@global]
///
class BimodalDynamicAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueNotifier<bool> isOn;
  final AppBar onAppbar;
  final AppBar offAppbar;

  const BimodalDynamicAppBar({Key? key, required this.isOn, required this.onAppbar, required this.offAppbar}) : super(key: key);

  @override
  State<BimodalDynamicAppBar> createState() => _BimodalDynamicAppBarState();
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BimodalDynamicAppBarState extends State<BimodalDynamicAppBar> {
  @override
  Widget build(BuildContext context){
    return ValueListenableBuilder(
      valueListenable: widget.isOn,
      builder: (BuildContext context, bool value, Widget? child) => (value) ? widget.onAppbar : widget.offAppbar
    );
  }
}
