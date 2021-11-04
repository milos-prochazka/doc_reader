import 'dart:ui';
import 'package:flutter/material.dart';

abstract class IDocumentSpan
{
  double get height;
  double get width;
  void paint(Canvas canvas, Size size, double xOffset, double yOffset);
  void calcSize(CalcSizeParameters parameters);
}

class DocumentSpanContainer
{
  IDocumentSpan span;
  double yPosition = 0.0;
  double xPosition = 0.0;

  DocumentSpanContainer(this.span);
}

class CalcSizeParameters
{
  late BuildContext context;
  late MediaQueryData media;

  CalcSizeParameters(this.context)
  {
    media = MediaQuery.of(context);
  }
}