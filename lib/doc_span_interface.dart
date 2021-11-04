import 'dart:ui';

abstract class IDocumentSpan
{
  double get height;
  void paint(Canvas canvas, Size size, double xOffset, double yOffset);
  void calcSize();
}

class DocumentSpanContainer
{
  IDocumentSpan span;
  double yPosition = 0.0;
  double xPosition = 0.0;

  DocumentSpanContainer(this.span);
}