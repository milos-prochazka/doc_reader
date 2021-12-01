import 'dart:ui';
import 'package:flutter/material.dart';

abstract class IDocumentSpan 
{
  double height(PaintParameters params);
  double width(PaintParameters params);
  void paint(PaintParameters parameters, double xOffset, double yOffset);
  void calcSize(PaintParameters parameters);
}

class DocumentSpanContainer 
{
  IDocumentSpan span;
  double yPosition = 0.0;
  double xPosition = 0.0;

  DocumentSpanContainer(this.span);
}

class PaintParameters 
{
  final Canvas canvas;
  late Size size;
  late Rect rect;
  late Key key;

  PaintParameters(this.canvas, this.size) 
  {
    rect = Rect.fromLTWH(0, 0, size.width, size.height);
    key = UniqueKey();
  }

  PaintParameters.copyFrom(this.canvas, PaintParameters source) 
  {
    size = source.size;
    rect = source.rect;
    key = source.key;
  }

  void newKey() 
  {
    key = UniqueKey();
  }
}