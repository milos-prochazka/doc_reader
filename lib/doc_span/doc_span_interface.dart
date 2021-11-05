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
  final Size size;
  final Canvas canvas;
  final Key key = UniqueKey();

  PaintParameters(this.canvas, this.size);
}