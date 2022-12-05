import 'package:flutter/material.dart';

/// [AppBar] with dynamic title based on the length of [items].
/// 
/// The widget is **Bimodal** because it has 2 "modes" - when [items] is empty and when it is not.
/// And the widget displays the appropriate title, leading widget, and action widgets
/// with respect to the current mode.
/// 
/// Because of Dart's lack of dynamic string interpolation, the default titles for the two modes is
/// `titles[0]` when [items] is empty and `"${list.length} ${widget.titles[1]}"` when [items] is not empty.
/// For example, assuming [items].length is `4` and [titles] = `("Gallery", "Images Selected")`,
/// the app bar's title will display `"4 Images Selected"`.
/// 
/// The switch functions can be overriden and customized.
/// [BimodalNumericTitleAppBar.]
///
/// [@author	Kwangeon Kim]
/// [ @since	v0.0.1 ]
/// [@version	v1.0.0	Thursday, July 7th, 2022]
/// [@see		StatefulWidget]
/// [@global]
///
class BimodalNumericTitleAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ValueNotifier<List> items;
  final List<String> titles;
  final List<Widget?> leadings;
  final List<List<Widget>> actionWidgets;
  final List<Color?> colors;

  const BimodalNumericTitleAppBar({
    Key? key,
    required this.items,
    this.titles = const ['', ''],
    this.leadings = const [null, null],
    this.actionWidgets = const [[], []],
    this.colors = const [null, null]
  }) : super(key: key);

  @override
  State<BimodalNumericTitleAppBar> createState() => _BimodalNumericTitleAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BimodalNumericTitleAppBarState extends State<BimodalNumericTitleAppBar> {
  Text titleSwitch(List list) => Text((list.isEmpty) ? widget.titles[0] : '${list.length} ${widget.titles[1]}');
  Widget? leadingWidgetSwitch(List list) => (list.isEmpty) ? widget.leadings[0] : widget.leadings[1];
  List<Widget> toolSwitch(List list) => (list.isEmpty) ? widget.actionWidgets[0] : widget.actionWidgets[1];
  Color? bgSwitch(List list) => (list.isEmpty) ? widget.colors[0] : widget.colors[1];

  @override
  Widget build(BuildContext context){
    return ValueListenableBuilder(
      valueListenable: widget.items,
      builder: (BuildContext context, List items, Widget? child){
        return AppBar(
          title: titleSwitch(items),
          leading: leadingWidgetSwitch(items),
          actions: toolSwitch(items),
          backgroundColor: bgSwitch(items)
        );
      }
    );
  }
}


/// [BimodalNumericTitleAppBar] for multiselecting images.
/// 
/// This was specifically designed for DatasetMediaPage.
/// [MultiSelectImageAppBar.]
///
/// [@author	Kwangeon Kim]
/// [ @since	v0.0.1 ]
/// [@version	v1.0.0	Thursday, July 7th, 2022]
/// [@see		BimodalNumericTitleAppBar]
/// [@global]
///
class MultiSelectImageAppBar extends BimodalNumericTitleAppBar {
  final String projectName;
  final List<Widget> regularTools;
  final List<Widget> selectTools;
  final void Function() clear;

  MultiSelectImageAppBar({Key? key, required super.items, this.projectName = '', required this.regularTools, required this.selectTools, required this.clear})
    : super(key: key,
      titles: [projectName, 'Images Selected'],
      leadings: [null, IconButton(onPressed: () => clear(), icon: const Icon(Icons.arrow_back))],
      actionWidgets: [regularTools, selectTools]
    );
}
