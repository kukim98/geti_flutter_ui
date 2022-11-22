import 'dart:ui';

import 'package:intel_geti_api/intel_geti_api.dart';

extension RectangleAnnotationShapeUI on RectangleAnnotationShape {
  void setDimensionWithRect(Rect rect) {
    x = rect.left;
    y = rect.top;
    height = rect.height;
    width = rect.width;
  }

  Rect toRect() => Rect.fromLTWH(x.toDouble(), y.toDouble(), width.toDouble(), height.toDouble());
}