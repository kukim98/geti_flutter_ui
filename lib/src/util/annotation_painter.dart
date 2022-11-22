import 'package:flutter/material.dart';
import 'package:intel_geti_api/intel_geti_api.dart';
import 'package:intel_geti_ui/src/helper/ui_logic.dart';

class AnnotationPainter extends CustomPainter {
  Media media;
  List<Annotation> annotations;
  bool isResizeMode;
  Annotation? selectedAnnotation;
  String kind;
  // Size canvasSize;
  // UI Attributes
  double borderWidth;
  double textFactor;
  TextStyle labelTextStyle;

  AnnotationPainter({
    required this.media,
    required this.annotations,
    this.isResizeMode = false,
    this.selectedAnnotation,
    this.kind = 'annotation',
    // required this.canvasSize,
    this.borderWidth = 5,
    this.textFactor = 100,
    this.labelTextStyle = const TextStyle(fontWeight: FontWeight.w600)
  });

  @override
  void paint(Canvas canvas, Size size){
    num imageWidth = media.mediaInformation.width;
    num imageHeight = media.mediaInformation.height;

    // For each annotation, spill out the labels.
    for (Annotation item in annotations) {
      // For each label associated with an annotation, prepare the ink.
      for (AnnotationLabel label in item.labels) {
        switch (item.shape.runtimeType) {
          case RectangleAnnotationShape:
            // Get UI representation of annotation
            RectangleAnnotationShape annotationShape = item.shape as RectangleAnnotationShape;
            Rect uiRectangle = Rect.fromLTWH(
              (annotationShape.x / imageWidth) * size.width,
              (annotationShape.y / imageHeight) * size.height,
              (annotationShape.width / imageWidth) * size.width,
              (annotationShape.height / imageHeight) * size.height
            );
            // Prepare the ink
            Color labelColor = hexStringInterpreter(label.label.color);
            Paint labelColorPaint = Paint()
              ..color = labelColor
              ..strokeCap = StrokeCap.round
              ..strokeWidth = borderWidth;
            Paint labelFillPaint = Paint()
              ..color = labelColor.withOpacity(0.4)
              ..style = PaintingStyle.fill
              ..strokeCap = StrokeCap.round
              ..strokeWidth = borderWidth;
            // Set text style for label name
            labelTextStyle = labelTextStyle.copyWith(
              color: getContrastingColor(labelColor),
              fontSize: 25.0
            );
            String text = '';
            if (label.label.name == '') {
              text = '';
            }
            else if (kind == 'annotation') {
              text = label.label.name;
            }
            else {
              text = '${label.label.name} ${(label.probability * 100).round()}%';
            }
            TextSpan textSpan = TextSpan(text: text, style: labelTextStyle);
            TextPainter textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
            textPainter.layout();
            // Draw annotation rectangle
            canvas.drawRect(uiRectangle, labelColorPaint..style = PaintingStyle.stroke);
            if (label.label.name != '') {
              // Fill annotation if labeled
              canvas.drawRect(uiRectangle, labelFillPaint);
              // Draw annotation label name and border
              Rect uiLabelRectangle = Rect.fromLTWH(
                uiRectangle.left,
                uiRectangle.top - textPainter.height,
                textPainter.width + borderWidth,
                textPainter.height
              );
              canvas.drawRect(uiLabelRectangle, labelColorPaint..style = PaintingStyle.stroke);
              canvas.drawRect(uiLabelRectangle, labelColorPaint..style = PaintingStyle.fill);
              textPainter.paint(
                canvas,
                Offset(
                  uiRectangle.left + (uiLabelRectangle.width - textPainter.width) / 2,
                  uiRectangle.top - uiLabelRectangle.height + (uiLabelRectangle.height - textPainter.height) / 2
                )
              );
            }
            // If resize mode or if an annotation is selected, add a dot at each corner.
            if (isResizeMode || (selectedAnnotation != null && selectedAnnotation!.id == item.id)){
              Paint white = Paint()
                ..color = Colors.white
                ..style = PaintingStyle.fill;
              BorderSide border = BorderSide(
                color: labelColor,
                width: borderWidth
              );
              double doubleWidth = borderWidth * 2;
              double tripleWidth = borderWidth * 3;
              for (Offset vertex in [uiRectangle.topLeft, uiRectangle.topRight, uiRectangle.bottomLeft, uiRectangle.bottomRight]){
                // Paint label-colored resize anchors
                paintBorder(canvas, Rect.fromCenter(center: vertex, width: tripleWidth, height: tripleWidth), top: border, bottom: border, left: border, right: border);
                // Paint white resize anchors
                canvas.drawRect(Rect.fromCenter(center: vertex, width: doubleWidth, height: doubleWidth), white);
              }
            }
            break;
          default:
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
