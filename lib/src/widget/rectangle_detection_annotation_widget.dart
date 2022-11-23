import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intel_geti_api/intel_geti_api.dart';
import 'package:intel_geti_ui/src/helper/annotation_helper.dart';
import 'package:intel_geti_ui/src/helper/ui_logic.dart';
import 'package:intel_geti_ui/src/util/annotation_painter.dart';
import 'package:zoom_widget/zoom_widget.dart';

import 'widget.dart';

class DetectionAnnotationWidget extends StatefulWidget {
  // Appbar attributes
  final String onAppbarTitle;
  final Widget? onAppbarLeading;
  final List<Widget>? onAppbarActions;
  final Color? onAppbarColor;
  final String offAppbarTitle;
  final Widget? offAppbarLeading;
  final List<Widget>? offAppbarActions;
  final Color? offAppbarColor;
  // Widgets
  final Uint8List imageBytes;
  final int resizeHitPointRadius;
  final double maxZoom;
  // Bridges
  final ValueNotifier<bool> appBarOnOffStatus;
  final ValueNotifier<String> modeStatus;
  final StreamController<List<Annotation>> annotationsStatus;
  final StreamController<Annotation> selectedAnnotationStatus;
  // GETi
  final Project project;
  final Media media;
  final String kind;
  // Initial Settings
  final List<Annotation> initialAnnotations;
  // Annotation Toolbar Settings
  final Icon editIcon;
  final Icon addLabelIcon;
  final Icon deleteAnnotationIcon;


  const DetectionAnnotationWidget({
    Key? key,
    this.onAppbarTitle = 'Annotation',
    this.onAppbarLeading,
    this.onAppbarActions,
    this.onAppbarColor,
    this.offAppbarTitle = 'Edit Mode',
    this.offAppbarLeading,
    this.offAppbarActions,
    this.offAppbarColor = Colors.white10,
    required this.imageBytes,
    this.resizeHitPointRadius = 100,
    this.maxZoom = 2.0,
    required this.appBarOnOffStatus,
    required this.modeStatus,
    required this.annotationsStatus,
    required this.selectedAnnotationStatus,
    required this.project,
    required this.media,
    this.kind = 'annotation',
    this.initialAnnotations = const [],
    this.editIcon = const Icon(Icons.edit),
    this.addLabelIcon = const Icon(Icons.new_label),
    this.deleteAnnotationIcon = const Icon(Icons.delete)
  }) : super(key: key);


  @override
  State<DetectionAnnotationWidget> createState() => DetectionAnnotationWidgetState();
}

class DetectionAnnotationWidgetState extends State<DetectionAnnotationWidget> {
  final GlobalKey _imageKey = GlobalKey();

  List<Annotation> allAnnotations = [];
  Annotation? selectedAnnotation;

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
    allAnnotations = List<Annotation>.from(widget.initialAnnotations);
    super.initState();
  }

  Widget? uiModeWidgetSwitch(String mode) {
    switch (mode) {
      case 'NEW': {
        Offset? startPoint;
        Offset? endPoint;
        Annotation? newAnnotation;
        return GestureDetector(
          onPanStart: (DragStartDetails details) {
            // On drag start, create a new annotation and save the starting point.
            RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
            startPoint = renderBox.globalToLocal(details.globalPosition);
            newAnnotation = Annotation.dummy(type: 'RECTANGLE');
          },
          onPanUpdate: (DragUpdateDetails details) {
            /// While dragging...
            /// 1. Update the endpoint
            /// 2. Create a UI representation of the annotation in Rect
            /// 3. Convert the annotation from UI to Geti representation
            /// 4. Update new annotation with new dimensions
            /// 5. Draw updated annotation

            // Step I
            RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
            endPoint = renderBox.globalToLocal(details.globalPosition);
            // Step II & III
            Rect getiRect = convertRectUiToGeti(
              a: startPoint!,
              b: endPoint!,
              uiImageSize: renderBox.size,
              actualImageSize: actualImageSize
            );
            // Step IV
            (newAnnotation!.shape as RectangleAnnotationShape).setDimensionWithRect(getiRect);
            // Step V
            widget.selectedAnnotationStatus.add(newAnnotation!);
          },
          onPanEnd: (DragEndDetails details) {
            // On drag end, determine the validity of new annotation.
            if ((newAnnotation!.shape as RectangleAnnotationShape).isValid(imageHeight: widget.media.mediaInformation.height, imageWidth: widget.media.mediaInformation.width)) {
              // Keep new annotation if valid and switch to resize mode
              widget.modeStatus.value = 'RESIZE';
              widget.appBarOnOffStatus.value = false;
              selectedAnnotation = newAnnotation;
              widget.selectedAnnotationStatus.add(selectedAnnotation!);
            }
            else {
              // If invalid, repaint the canvas with a dummy annotation.
              widget.selectedAnnotationStatus.add(Annotation.dummy(type: newAnnotation!.shape.type));
            }
            // Clear settings
            startPoint = null;
            endPoint = null;
            newAnnotation = null;
          }
        );
      }
      case 'RESIZE': {
        /// Resize handles resizing and relocation of a selected annotation.
        /// When in this mode, we are guaranteed to have [selectedAnnotation].
        // PARENT VAR
        
        // RESIZE EVENT VAR
        Offset? startPoint;
        Offset? endPoint;
        bool? isResizeEvent;
        Annotation? original;
        return GestureDetector(
          onPanStart: (DragStartDetails details){
            /// On drag start...
            /// 1. Get the intial drag start point
            /// 2. Convert the selectedAnnotation to UI Rect represnetation
            /// 3. First check if this is a resize event.
            /// 4. If not, check if this is a relocate event.
            /// 5. Otherwise, do nothing.

            // Step I
            RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
            Offset point = renderBox.globalToLocal(details.globalPosition);
            // Step II
            Rect getiRectangle = (selectedAnnotation!.shape as RectangleAnnotationShape).toRect();
            Rect uiRectangle = convertRectGetiToUi(a: getiRectangle.topLeft, b: getiRectangle.bottomRight, uiImageSize: renderBox.size, actualImageSize: actualImageSize);
            // Step III
            int vertexIndex = touchPointWithinDeltaOfVertex(
              point: point,
              rect: uiRectangle,
              delta: 15.0
            );
            if (vertexIndex != -1) {
              /// Resize event handling
              /// startPoint = vertex diagonally opposite to the vertex to move (anchor)
              /// endPoint = vertex chosen to be moved around
              /// Goal is to construct Rect that encompasses both startPoint and endPoint
              original = Annotation.copyFrom(original: selectedAnnotation!);
              startPoint = diagonallyOppositePointInRect(vertexIndex, uiRectangle);
              endPoint = point;
              isResizeEvent = true;
            }
            else {
              // Step IV
              Offset? delta = deltaFromTopLeftWithinAnnotation(
                uiPoint: point,
                uiAnnotation: uiRectangle
              );
              if (delta != null){
                /// Relocate event handling
                /// startPoint = initial touch point
                /// endPoint = initial touch point
                /// Goal is to move the annotation around after calculating delta between endPoint and startPoint
                original = Annotation.copyFrom(original: selectedAnnotation!);
                startPoint = point;
                endPoint = point;
                isResizeEvent = false;
              }
              else {
                // Step V
                isResizeEvent = null;
              }
            }
          },
          onPanUpdate: (DragUpdateDetails details){
            // While dragging, handle events appropriately.
            if (isResizeEvent != null){
              // Step I - Update the end point
              RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
              endPoint = renderBox.globalToLocal(details.globalPosition);
              if (isResizeEvent!){
                /// Resize event handling
                /// Step II - Construct UI rect with startPoint and endPoint
                /// Step III - Convert UI rect to GETi rect
                /// Step IV - Update annotation with new rect
                /// Step V - Redraw annotation

                // Step II & III
                Rect getiRect = convertRectUiToGeti(
                  a: startPoint!,
                  b: endPoint!,
                  uiImageSize: renderBox.size,
                  actualImageSize: actualImageSize
                );
                // Step IV
                (selectedAnnotation!.shape as RectangleAnnotationShape).setDimensionWithRect(getiRect);
                // Step V
                widget.selectedAnnotationStatus.add(selectedAnnotation!);
              }else{
                /// Relocate event handling
                /// Step II - Calculate delta (offset) from the inital point
                /// Step III - Convert UI offset to GETi offset
                /// Step IV - Update annotation by applying offsets to x and y
                /// Step V - Redraw annotation

                // Step II
                Offset delta = Offset(endPoint!.dx - startPoint!.dx, endPoint!.dy - startPoint!.dy);
                // Step III
                Offset getiDelta = convertOffsetUiToGeti(point: delta, uiImageSize: renderBox.size, actualImageSize: actualImageSize);
                // Step IV
                (selectedAnnotation!.shape as RectangleAnnotationShape).x = (original!.shape as RectangleAnnotationShape).x + getiDelta.dx;
                (selectedAnnotation!.shape as RectangleAnnotationShape).y = (original!.shape as RectangleAnnotationShape).y + getiDelta.dy;
                // Step V
                widget.selectedAnnotationStatus.add(selectedAnnotation!);
              }
            }
          },
          onPanEnd: (DragEndDetails details){
            // On drag end, determine the validity of new annotation.
            if ((selectedAnnotation!.shape as RectangleAnnotationShape).isValid(imageHeight: widget.media.mediaInformation.height, imageWidth: widget.media.mediaInformation.width)) {
              // Do nothing
            }
            else {
              // If invalid, replace with annotation with the original. Then, redraw.
              selectedAnnotation = original;
              widget.selectedAnnotationStatus.add(selectedAnnotation!);
            }
            // Clear settings
            isResizeEvent = null;
            startPoint = null;
            endPoint = null;
            original = null;
          }
        );
      }
      case 'VIEW':
        return GestureDetector(
          onTapDown: (TapDownDetails details){
            // Check if inside Rect
            RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
            Offset touchPoint = renderBox.globalToLocal(details.globalPosition);
            Annotation? clickedAnnotation = pointInsideAnnotation(renderBox, touchPoint, allAnnotations, widget.media);
            // If yes, mark the rect
            if (clickedAnnotation != null){
              widget.modeStatus.value = 'RESIZE';
              widget.appBarOnOffStatus.value = false;
              selectedAnnotation = clickedAnnotation;
              allAnnotations.remove(clickedAnnotation);
              widget.annotationsStatus.add(allAnnotations);
              widget.selectedAnnotationStatus.add(clickedAnnotation);
            }
          },
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BimodalDynamicAppBar(
        isOn: widget.appBarOnOffStatus,
        onAppbar: AppBar(
          title: Text(widget.onAppbarTitle),
          leading: widget.onAppbarLeading,
          actions: widget.onAppbarActions,
          backgroundColor: widget.onAppbarColor
        ),
        offAppbar: AppBar(
          title: Text(widget.offAppbarTitle),
          leading: widget.offAppbarLeading ?? IconButton(
            onPressed: () {
              widget.appBarOnOffStatus.value = true;
              allAnnotations.add(selectedAnnotation!);
              selectedAnnotation = null;
              widget.modeStatus.value = 'VIEW';
              widget.annotationsStatus.add(allAnnotations);
              widget.selectedAnnotationStatus.add(Annotation.dummy(type: 'RECTANGLE'));
            },
            icon: const Icon(Icons.arrow_back)
          ),
          actions: widget.offAppbarActions,
          backgroundColor: widget.offAppbarColor
        )
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
                                initialData: allAnnotations,
                                stream: widget.annotationsStatus.stream,
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
                              ),
                              // Master edit painter layer - Responsible for painting selected annotation
                              StreamBuilder<Annotation>(
                                initialData: Annotation.dummy(type: 'RECTANGLE'),
                                stream: widget.selectedAnnotationStatus.stream,
                                builder: (context, snapshot) {
                                  return ValueListenableBuilder<double>(
                                    valueListenable: zoomController,
                                    builder: (context, zoomValue, child) {
                                      return CustomPaint(
                                        size: Size(size.width, size.height),
                                        painter: AnnotationPainter(
                                          media: widget.media,
                                          annotations: [snapshot.data!],
                                          kind: widget.kind,
                                          isResizeMode: widget.modeStatus.value == 'RESIZE'
                                        )
                                      );
                                    }
                                  );
                                },
                              ),
                              // User interaction layer
                              ValueListenableBuilder<String>(
                                valueListenable: widget.modeStatus,
                                builder: (BuildContext context, String modeValue, Widget? child) => uiModeWidgetSwitch(modeValue)!
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
          ValueListenableBuilder<bool>(
            valueListenable: widget.appBarOnOffStatus,
            builder: (BuildContext context, bool value, Widget? child){
              if (value){
                return Positioned(
                  top: 40.0,
                  right: 10.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      OnOffIconButton(
                        symbol: widget.editIcon,
                        onIconBackgroundColor: const Color(0xff8c8c8c),
                        offIconBackgroundColor: const Color(0xffd9d9d9),
                        onTapFunc: () {
                          if (widget.modeStatus.value == 'NEW'){
                            widget.modeStatus.value = 'VIEW';
                          } else {
                            widget.modeStatus.value = 'NEW';
                          }
                        },
                      )
                    ],
                  ),
                );
              } else {
                return Positioned(
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
                          if (!selectedAnnotation!.isDummy()){
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
                                selectedAnnotation!.labels = [AnnotationLabel(label: label, probability: 1.0, userId: '')];
                                allAnnotations.add(selectedAnnotation!);
                                // Reset view
                                widget.selectedAnnotationStatus.add(Annotation.dummy(type: selectedAnnotation!.shape.type));
                                selectedAnnotation = null;
                                widget.annotationsStatus.add(allAnnotations);
                                widget.appBarOnOffStatus.value = true;
                                widget.modeStatus.value = 'VIEW';
                              }
                            });
                          }
                        },
                        icon: widget.addLabelIcon
                      ),
                      const Divider(height: 10.0),
                      defaultIconButton(
                        onTapFunc: (){
                          if (!selectedAnnotation!.isDummy()){
                            showDialog(context: context, builder: (BuildContext context) => 
                              AlertDialog(
                                title: const Text('Annotation delete'),
                                content: const Text('Please confirm your delete.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm'))
                                ],
                              )
                            ).then((deleteApproved) {
                              if (deleteApproved){
                                widget.selectedAnnotationStatus.add(Annotation.dummy(type: selectedAnnotation!.shape.type));
                                selectedAnnotation = null;
                                widget.appBarOnOffStatus.value = true;
                                widget.modeStatus.value = 'VIEW';
                              }
                            });
                          }
                        },
                        icon: widget.deleteAnnotationIcon
                      )
                    ],
                  ),
                );
              }
            }
          )
        ],
      )
    );
  }
}