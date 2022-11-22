import 'dart:ui';

Color getContrastingColor(Color color) {
  int d = 0;
  // Counting the perceptive luminance - human eye favors green color...
  double luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
  if (luminance > 0.5){
    // bright colors - black font
    d = 0;
  }else {
    // dark colors - white font
    d = 255;
  }
  return Color.fromARGB(color.alpha, d, d, d);
}

Color hexStringInterpreter(String color){
  String r = color.substring(1, 3);
  String g = color.substring(3, 5);
  String b = color.substring(5, 7);
  String a = color.substring(7, 9);
  return Color.fromARGB(int.parse(a, radix: 16), int.parse(r, radix: 16), int.parse(g, radix: 16), int.parse(b, radix: 16));
}

/// Return a vertex number if point touched is within delta range of one of the verticies.
/// 
/// The function checks if [point] is within the +/- [delta] range of one of the verticies
/// of [rect]. If yes, [int] representative of one of the 4 corners is returned and -1 otherwise.
/// TopLeft = 0
/// TopRight = 1
/// BottomRight = 2
/// BottomLeft = 3
int touchPointWithinDeltaOfVertex({required Offset point, required Rect rect, double delta = 5.0}) {
  List<Offset> verticies = [rect. topLeft, rect.topRight, rect.bottomRight, rect.bottomLeft];
  for (int i = 0; i < verticies.length; i++) {
    Offset vertex = verticies[i];
    Rect region = Rect.fromCenter(center: vertex, width: delta * 2, height: delta * 2);
    if (region.contains(point)){
      return i;
    }
  }
  return -1;
}

Offset? deltaFromTopLeftWithinAnnotation({required Offset uiPoint, required Rect uiAnnotation}){
  return (!uiAnnotation.contains(uiPoint)) ? null : Offset(uiPoint.dx - uiAnnotation.left, uiPoint.dy - uiAnnotation.top);
}

Offset? diagonallyOppositePointInRect(int i, Rect rect) {
  switch (i) {
    case 0:
      return rect.bottomRight;
    case 1:
      return rect.bottomLeft;
    case 2:
      return rect.topLeft;
    case 3:
      return rect.topRight;
    default:
      return null;
  }
}

Offset convertOffsetUiToGeti({required Offset point, required Size uiImageSize, required Size actualImageSize}) {
  return Offset(
    point.dx / uiImageSize.width * actualImageSize.width,
    point.dy / uiImageSize.height * actualImageSize.height
  );
}

Offset convertOffsetGetiToUi({required Offset point, required Size uiImageSize, required Size actualImageSize}) {
  return Offset(
    point.dx / actualImageSize.width * uiImageSize.width,
    point.dy / actualImageSize.height * uiImageSize.height
  );
}

Rect convertRectUiToGeti({required Offset a, required Offset b, required Size uiImageSize, required Size actualImageSize}) {
  Rect rect = Rect.fromPoints(a, b);
  return Rect.fromLTRB(
    rect.topLeft.dx / uiImageSize.width * actualImageSize.width,
    rect.topLeft.dy / uiImageSize.height * actualImageSize.height,
    rect.bottomRight.dx / uiImageSize.width * actualImageSize.width,
    rect.bottomRight.dy / uiImageSize.height * actualImageSize.height
  );
}

Rect convertRectGetiToUi({required Offset a, required Offset b, required Size uiImageSize, required Size actualImageSize}) {
  Rect rect = Rect.fromPoints(a, b);
  return Rect.fromLTRB(
    rect.topLeft.dx / actualImageSize.width * uiImageSize.width,
    rect.topLeft.dy / actualImageSize.height * uiImageSize.height,
    rect.bottomRight.dx / actualImageSize.width * uiImageSize.width,
    rect.bottomRight.dy / actualImageSize.height * uiImageSize.height
  );
}
