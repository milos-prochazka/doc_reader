import 'package:flutter/widgets.dart';

import 'doc_span/doc_span_interface.dart';

class Document
{
  double position = 0.0;
  final docSpans = <DocumentSpanContainer>[];
  PaintParameters? paintParameters;

  PaintParameters getPaintParameters(Canvas canvas, Size size)
  {
    if (paintParameters?.size != size)
    {
      paintParameters = PaintParameters(canvas, size);
    }

    return paintParameters!;
  }
}