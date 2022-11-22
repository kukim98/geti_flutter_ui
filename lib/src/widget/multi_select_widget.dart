import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intel_geti_api/intel_geti_api.dart';
import 'package:intel_geti_ui/src/helper/ui_logic.dart';

BorderRadius rounded = BorderRadius.circular(8.0);

/// [Widget] with multiselection.
/// 
/// [MultiSelectWidget] allow multiselection among each other given they share the same [listener].
/// To initiate multiselection, user long-presses a [MultiSelectWidget].
/// This then allows the selection/deselection of other [MultiSelectWidget] with a tap.
/// The selected items are tracked by [listener], which controls gesture behavior of [MultiSelectWidget].
/// [item] is a metadata of the widget [child].
/// [MultiSelectWidget.]
///
/// [@author	Unknown]
/// [ @since	v0.0.1 ]
/// [@version	v1.0.0	Thursday, July 7th, 2022]
/// [@global]
///
class MultiSelectWidget<T> extends StatefulWidget {
  final ValueNotifier<List<MultiSelectWidget<T>>> listener;
  final T item;
  final Widget child;
  final void Function() onTap;
  final ValueNotifier<bool> isSelectedListener = ValueNotifier(false);

  MultiSelectWidget({Key? key, required this.listener, required this.item, required this.child, required this.onTap}) : super(key: key);

  @override
  State<MultiSelectWidget<T>> createState() => _MultiSelectWidgetState<T>();
}

class _MultiSelectWidgetState<T> extends State<MultiSelectWidget<T>> with AutomaticKeepAliveClientMixin {

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder(
      valueListenable: widget.isSelectedListener,
      child: widget.child,
      builder: (BuildContext context, bool isSelected, Widget? child){
        return GestureDetector(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: rounded
            ),
            child: Opacity(
              opacity: (isSelected) ? 0.5 : 1.0,
              child: child!,
            ),
          ),
          onTap: (){
            // If previously selected items exist, select/deselect on tap.
            if (widget.listener.value.isNotEmpty){
              if (isSelected){
                widget.listener.value = List<MultiSelectWidget<T>>.from(widget.listener.value..remove(widget));
                widget.isSelectedListener.value = false;
              }else{
                widget.listener.value = List<MultiSelectWidget<T>>.from(widget.listener.value..add(widget));
                widget.isSelectedListener.value = true;
              }
            }
            // Else, execute the widget's onTap function.
            else {
              widget.onTap();
            }
          },
          onLongPress: (){
            // Long-press events are processed for initial selection only.
            if (widget.listener.value.isEmpty){
              widget.listener.value = List<MultiSelectWidget<T>>.from(widget.listener.value..add(widget));
              widget.isSelectedListener.value = true;
            }
          },
        );
      }
    );
  }
  
  @override
  bool get wantKeepAlive => true;
}

class MultiSelectThumbnail<T> extends MultiSelectWidget<T> {
  final Uint8List thumbnail;

  MultiSelectThumbnail({Key? key, required super.listener, required super.item, required super.child, required super.onTap, required this.thumbnail}) : super(key: key);
  
  factory MultiSelectThumbnail.withDecoration({
    required ValueNotifier<List<MultiSelectWidget<T>>> listener,
    required T item,
    required void Function() onTap,
    required Uint8List thumbnail,
    List<Widget> stackedWidgets = const []
  }) {
    return MultiSelectThumbnail(
      listener: listener,
      item: item,
      onTap: onTap,
      thumbnail: thumbnail,
      child: Stack(
        children: [
          // Allows for stacked widget decorations to be placed over image.
          Positioned.fill(child: Image.memory(thumbnail, fit: BoxFit.cover)),
          ...stackedWidgets
        ]
      )
    );
  }

  static Widget thumbnailDecorations({required Future<AnnotationScene?> Function() getAnnotationDetail, bool isClassification = false}) {
    return FutureBuilder<AnnotationScene?>(
      future: getAnnotationDetail(),
      builder: (BuildContext context, AsyncSnapshot<AnnotationScene?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData){
          if (snapshot.data != null) {
            if (isClassification) {
              List <Widget> labelWidgets = [];
              for (Annotation annotation in snapshot.data!.annotations) {
                for (AnnotationLabel label in annotation.labels){
                  Color labelColor = hexStringInterpreter(label.label.color);
                  labelWidgets.add(Chip(
                    backgroundColor: labelColor,
                    label: Text(label.label.name, style: TextStyle(backgroundColor: labelColor, color: getContrastingColor(labelColor)))
                  ));
                }
              }
              return Positioned(left: 2, top: 2, child: Row(children: labelWidgets));
            }
          }
          return const SizedBox.shrink();
        }
        else if (snapshot.hasError) {
          return const Positioned(child: Icon(Icons.question_mark, color: Colors.red));
        }
        else {
          return const Positioned(child: CircularProgressIndicator());
        }
      }
    );
  }
}
