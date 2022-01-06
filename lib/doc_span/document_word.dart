import 'dart:ui';

class DocumentWordInfo
{
  String? text;
  Rect rect = Rect.zero;
  int id = -1;

  translate(double xOffset, double yOffset)
  {
    rect = rect.translate(xOffset, yOffset);
  }
}