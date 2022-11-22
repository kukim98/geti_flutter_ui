import 'package:flutter/material.dart';
import 'package:intel_geti_api/intel_geti_api.dart';



bool checkCornerHitHelper(Rect uiAnnotation, Offset corner, Offset point, int hitPointRadius){
  return RRect.fromRectXY(Rect.fromCenter(center: corner, width: hitPointRadius * 2, height: hitPointRadius * 2), hitPointRadius.toDouble(), hitPointRadius.toDouble()).contains(point);
}

List<Offset>? checkCornerHit(RenderBox box, Offset point, RectangleAnnotationShape annotationShape, int hitPointRadius){
  // Returns [dragstartpoint, dragendpoint]
  Rect uiAnnotation = Rect.fromLTWH(annotationShape.x.toDouble(), annotationShape.y.toDouble(), annotationShape.width.toDouble(), annotationShape.height.toDouble());
  if (checkCornerHitHelper(uiAnnotation, uiAnnotation.topLeft, point, hitPointRadius)){
    return [uiAnnotation.bottomRight, uiAnnotation.topLeft];
  } else if (checkCornerHitHelper(uiAnnotation, uiAnnotation.topRight, point, hitPointRadius)){
    return [uiAnnotation.bottomLeft, uiAnnotation.topRight];
  } else if (checkCornerHitHelper(uiAnnotation, uiAnnotation.bottomLeft, point, hitPointRadius)){
    return [uiAnnotation.topRight, uiAnnotation.bottomLeft];
  } else if (checkCornerHitHelper(uiAnnotation, uiAnnotation.bottomRight, point, hitPointRadius)){
    return [uiAnnotation.topLeft, uiAnnotation.bottomRight];
  } else {
    return null;
  }
}

Annotation? pointInsideAnnotation(RenderBox box, Offset point, List<Annotation> annotations, Media media){
  for (Annotation annotation in annotations){
    switch (annotation.shape.runtimeType) {
      case RectangleAnnotationShape:
        Offset? delta = checkWithinAnnotation(box, point, annotation.shape, media);
        if (delta != null){
          // If delta exists, then register the changes and the annotation and return false for resizing.
          return annotation;
        }
        break;
      default:
    }
  }
  return null;
}

Offset? checkWithinAnnotation(RenderBox renderBox, Offset point, AnnotationShape annotationShape, Media media){
  num imageWidth = media.mediaInformation.width;
  num imageHeight = media.mediaInformation.height;
  switch (annotationShape.runtimeType) {
    case RectangleAnnotationShape:
      Rect uiRectangle = Rect.fromLTRB(
        ((annotationShape as RectangleAnnotationShape).x / imageWidth) * renderBox.size.width,
        ((annotationShape).y / imageHeight) * renderBox.size.height,
        ((annotationShape).x / imageWidth) * renderBox.size.width + ((annotationShape).width / imageWidth) * renderBox.size.width,
        ((annotationShape).y / imageHeight) * renderBox.size.height + ((annotationShape).height / imageHeight) * renderBox.size.height
      );
      return (!uiRectangle.contains(point)) ? null : Offset(point.dx - uiRectangle.left, point.dy - uiRectangle.top);
    default:
      return null;
  }
}

List? checkIfResizeEventForSelected(RenderBox box, Offset point, Annotation selectedAnnotation, int hitPointRadius, Media media) {
  switch (selectedAnnotation.shape.runtimeType) {
    case RectangleAnnotationShape:
      // For RECTANGLE annotations, first check if the hitpoint is near the corner - user attempting resizing.
      List<Offset>? touchedCorner = checkCornerHit(box, point, selectedAnnotation.shape as RectangleAnnotationShape, hitPointRadius);
      if (touchedCorner != null){
        return [true, ...touchedCorner];
      }
      // If not, check if the hitpoint is within the annotation - user attempting relocating.
      Offset? delta = checkWithinAnnotation(box, point, selectedAnnotation.shape as RectangleAnnotationShape, media);
      if (delta != null){
        return [false, delta];
      }
      break;
    default:
  }
  // Return null for no registered event.
  return null;
}
