import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intel_geti_api/intel_geti_api.dart';
import 'package:intel_geti_ui/src/helper/ui_logic.dart';
import 'package:intel_geti_ui/src/util/annotation_painter.dart';
import 'package:zoom_widget/zoom_widget.dart';

import 'components/components.dart';


class ClassificationAnnotationWidget extends StatefulWidget {
  // Appbar attributes
  final String appbarTitle;
  final List<Widget>? appbarActions;
  final Color? appbarColor;
  // Widgets
  final Uint8List imageBytes;
  final int resizeHitPointRadius;
  final double maxZoom;
  // GETi
  final Project project;
  final Media media;
  final String kind;
  // Initial Settings
  final Annotation? initialAnnotation;
  // Annotation Toolbar Settings
  final Icon addLabelIcon;


  const ClassificationAnnotationWidget({
    Key? key,
    this.appbarTitle = 'Annotation',
    this.appbarActions,
    this.appbarColor,
    required this.imageBytes,
    this.resizeHitPointRadius = 100,
    this.maxZoom = 2.0,
    required this.project,
    required this.media,
    this.kind = 'annotation',
    this.initialAnnotation,
    this.addLabelIcon = const Icon(Icons.new_label)
  }) : super(key: key);


  @override
  State<ClassificationAnnotationWidget> createState() => ClassificationAnnotationWidgetState();
}

class ClassificationAnnotationWidgetState extends State<ClassificationAnnotationWidget> {
  final GlobalKey _imageKey = GlobalKey();

  late Annotation annotation;
  final StreamController<List<Annotation>> annotationsStatus = StreamController.broadcast();

  Annotation newAnnotation = Annotation.dummy(type: 'RECTANGLE');

  ValueNotifier<double> zoomController = ValueNotifier(0.0);
  Label? selectedLabel;

  late Size actualImageSize;

  @override
  void initState() {
    actualImageSize = Size(
      widget.media.mediaInformation.width.toDouble(),
      widget.media.mediaInformation.height.toDouble()
    );
    Annotation dummy = Annotation.dummy(type: 'RECTANGLE');
    (dummy.shape as RectangleAnnotationShape).width = actualImageSize.width;
    (dummy.shape as RectangleAnnotationShape).height = actualImageSize.height;
    dummy.labels.first.label.color = "#ffffff00";
    annotation = widget.initialAnnotation ?? dummy;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appbarTitle),
        actions: widget.appbarActions,
        backgroundColor: widget.appbarColor,
      ),
      body: Stack(
        children: [
          // Zoomables
          Zoom(
            backgroundColor: Colors.white,
            maxZoomWidth: MediaQuery.of(context).size.width,
            maxZoomHeight: MediaQuery.of(context).size.height,
            doubleTapZoom: true,
            initScale: 1,
            maxScale: widget.maxZoom,
            onScaleUpdate: (double scale, double zoom){
              zoom = min(zoom, widget.maxZoom);
              zoom = max(zoom, 1);
              zoomController.value = (zoom - 1) / (widget.maxZoom - 1);
            },
            child: Stack(
              children: [
                // Image Widget
                Center(
                  child: Image.memory(
                    key: _imageKey,
                    widget.imageBytes
                  )
                ),
                // UI Widgets - These widgets must have the same dimension as the image widget
                FutureBuilder(
                  future: Future.doWhile(() async {
                    await Future.delayed(const Duration(seconds: 1));
                    return _imageKey.currentContext == null || _imageKey.currentContext!.size == null || _imageKey.currentContext!.size!.isEmpty;
                  }),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done){
                      Size size = (_imageKey.currentContext!.findRenderObject() as RenderBox).size;
                      return Center(
                        child: SizedBox(
                          width: size.width,
                          height: size.height,
                          child: Stack(
                            children: [
                              // Master painter layer - Responsible for painting all annotations
                              StreamBuilder<List<Annotation>>(
                                initialData: [annotation],
                                stream: annotationsStatus.stream,
                                builder: (context, snapshot) {
                                  return ValueListenableBuilder<double>(
                                    valueListenable: zoomController,
                                    builder: (context, zoomValue, child) {
                                      return CustomPaint(
                                        size: Size(size.width, size.height),
                                        painter: AnnotationPainter(
                                          media: widget.media,
                                          annotations: snapshot.data!,
                                          kind: widget.kind
                                        )
                                      );
                                    }
                                  );
                                },
                              )
                            ]
                          )
                        )
                      );
                    }
                    return const SizedBox.shrink();
                  },
                )
              ]
            ),
          ),
          // Toolbar layer
          Positioned(
            top: 40.0,
            right: 10.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                defaultIconButton(
                  onTapFunc: () {
                    List<Label> labels = [];
                    for (Task task in widget.project.tasks) {
                      if (task is TrainableTask){
                        labels.addAll(task.labels);
                      }
                    }
                    showDialog<Label?>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Apply label'),
                          content: StatefulBuilder(
                            builder: (BuildContext context, StateSetter dropDownState){
                              return DropdownButton(
                                value: selectedLabel,
                                onChanged: (Label? newValue){
                                  dropDownState(() {
                                    selectedLabel = newValue!;
                                  });
                                },
                                items: labels.map((Label e) => 
                                  DropdownMenuItem(
                                    value: e,
                                    child: Row(
                                      children: [
                                        Container(color: hexStringInterpreter(e.color)),
                                        Text(e.name)
                                      ]
                                    )
                                  )
                                ).toList()
                              );
                            }
                          ),
                          actions: [
                            // Cancel
                            TextButton(
                              onPressed: () => Navigator.pop(context, null),
                              child: const Text('Cancel')
                            ),
                            // Done
                            TextButton(
                              onPressed: () => Navigator.pop(context, selectedLabel),
                              child: const Text('Done')
                            )
                          ],
                        );
                      }
                    ).then((Label? label) {
                      if (label != null){
                        // Apply new label
                        annotation.labels = [AnnotationLabel(label: label, probability: 1.0, userId: '')];
                        // Reset view
                        annotationsStatus.add([annotation]);
                      }
                    });
                  },
                  icon: widget.addLabelIcon
                ),
              ],
            ),
          )
        ],
      )
    );
  }
}