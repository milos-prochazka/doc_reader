import 'dart:ui';
import 'package:doc_reader/doc_span/basic/basic_text_span.dart';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:flutter/material.dart';

class DocReader extends StatefulWidget
{
  @override
  State<DocReader> createState() => _DocReaderState();
}

class _DocReaderState extends State<DocReader>
{
  final List<DocumentSpanContainer> docSpans = <DocumentSpanContainer>[];

  @override
  Widget build(BuildContext context)
  {
    docSpans.clear();

    for (int i = 1; i < 100; i++)
    {
      docSpans.add(DocumentSpanContainer(BasicTextSpan
          (
            'Testovaci text $i sss djsdsdjsdj $i sdfjsdjsdjsd $i dfjdjdfjdf sdjsdjsd dssdsdh sdjhs sdsd sdsdsd ssdsd sdsdsd sdsdjsdsd sdsdsd sasdsdsd sdsdsdsd sdsdsdsd zozol'
          )));
    }
    _calcLayout(context);

    return CustomPaint
    (
      painter: ShapePainter(docSpans),
      child: Container(),
    );
  }

  void _calcLayout(BuildContext context)
  {
    final param = CalcSizeParameters(context);

    double y = 0;
    for (var container in docSpans)
    {
      container.yPosition = y;
      container.span.calcSize(param);
      y += container.span.height;
    }
  }
}

class ShapePainter extends CustomPainter
{
  final List<DocumentSpanContainer> docSpans;

  ShapePainter(this.docSpans);

  @override
  void paint(Canvas canvas, Size size)
  {
    /*var paint = Paint()
    ..color = Colors.teal
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;

    Offset startingPoint = Offset(0, size.height / 2);
    Offset endingPoint = Offset(size.width, size.height / 2);

    canvas.drawLine(startingPoint, endingPoint, paint);*/

    for (var container in docSpans)
    {
      container.span.paint(canvas, size, container.xPosition, container.yPosition);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate)
  {
    return false;
  }
}