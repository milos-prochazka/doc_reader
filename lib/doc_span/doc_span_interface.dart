import 'package:doc_reader/doc_span/document_word.dart';

import 'paint_parameters.dart';

abstract class IDocumentSpan
{
  double height(PaintParameters params);
  double width(PaintParameters params);
  void paint(PaintParameters parameters, double xOffset, double yOffset);
  void calcSize(PaintParameters parameters);
  double correctYPosition(double yPosition, bool alignTop);
  void getSpanWords(List<DocumentWordInfo> words, PaintParameters parameters, int id, bool speech);
  int get id;
}

class DocumentSpanContainer
{
  IDocumentSpan span;
  double yPosition = 0.0;
  double xPosition = 0.0;

  DocumentSpanContainer(this.span);
}