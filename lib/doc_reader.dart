import 'dart:ui';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/document.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:flutter/material.dart';

class DocReader extends StatefulWidget
{
  final String documentProperty;
  DocReader({Key? key, required this.documentProperty}) : super(key: key ?? GlobalKey(debugLabel: 'DocReader'));

  @override
  State<DocReader> createState() => _DocReaderState();
}

class _DocReaderState extends State<DocReader>
{
  _DocReaderState();

  @override
  Widget build(BuildContext context)
  {
    _calcLayout(context);

    return CustomPaint
    (
      painter: ShapePainter(document(context)),
      child: Container(),
    );
  }

  Document document(BuildContext context) =>
  PropertyBinder.of(context).getOrCreateProperty<Document>(widget.documentProperty, (binder) => Document());

  void _calcLayout(BuildContext context)
  {
    final param = CalcSizeParameters(context);

    double y = 0;

    var doc = document(context);
    for (var container in doc.docSpans)
    {
      container.yPosition = y;
      container.span.calcSize(param);
      y += container.span.height;
    }
  }
}

class ShapePainter extends CustomPainter
{
  final Document document;

  ShapePainter(this.document);

  @override
  void paint(Canvas canvas, Size size)
  {
    document.position += 0.2;
    final docSpans = document.docSpans;

    int spanIndex = document.position.floor();
    double offset = -(document.position - document.position.floorToDouble()) * docSpans[spanIndex].span.height;

    for (; spanIndex < docSpans.length && offset < size.height; spanIndex++)
    {
      final container = docSpans[spanIndex];
      container.span.paint(canvas, size, container.xPosition, offset);
      offset += container.span.height;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate)
  {
    return false;
  }
}