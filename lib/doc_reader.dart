import 'dart:ui';
import 'dart:math' as math;
import 'package:doc_reader/doc_span/basic/basic_text_span.dart';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:flutter/material.dart';

class DocReader extends StatefulWidget
{
  DocReader({Key? key}) : super(key: key ?? GlobalKey(debugLabel: 'DocReader'));

  @override
  State<DocReader> createState() => _DocReaderState();
}

class _DocReaderState extends State<DocReader>
{
  List<DocumentSpanContainer> docSpans = <DocumentSpanContainer>[];

  @override
  Widget build(BuildContext context)
  {
    var binder = PropertyBinder.of(context);
    docSpans = binder.getOrCreateProperty<List<DocumentSpanContainer>>('document', (binder) => docSpans);

    docSpans.clear();

    for (int i = 1; i < 1000; i++)
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

  int topIndex(double yOffset)
  {
    int result = 0;

    if (docSpans.length > 1 && yOffset > 0)
    {
      int step = docSpans.length ~/ 2;
      int i = step;

      while (true)
      {
        if ((docSpans[i].yPosition < yOffset) && (i >= docSpans.length || docSpans[i + 1].yPosition >= yOffset))
        {
          result = i;
          break;
        }
        else
        {
          step = (step > 1) ? (step >> 1) : 1;
          if (docSpans[i].yPosition > yOffset)
          {
            i = math.max(i - step, 0);
          }
          else
          {
            i = math.min(i + step, docSpans.length - 1);
          }
        }
      }
    }

    return result;
  }

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

    double offset = 5;
    double endOffset = offset + size.height;

    for (int i = topIndex(offset); i < docSpans.length; i++)
    {
      final container = docSpans[i];
      if (container.yPosition > endOffset)
      {
        break;
      }
      else
      {
        container.span.paint(canvas, size, container.xPosition, container.yPosition - offset);
      }
    }

    /*for (var container in docSpans)
    {
      container.span.paint(canvas, size, container.xPosition, container.yPosition);
    }*/
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate)
  {
    return false;
  }
}