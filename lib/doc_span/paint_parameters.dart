import 'dart:ui';
import 'package:flutter/material.dart';

class PaintParameters
{
  final Canvas canvas;
  final Size size;
  final Rect rect;
  final double devicePixelRatio;
  final double textScale;
  final Size screenSize;
  late Key key;

  PaintParameters(this.canvas, this.size, this.devicePixelRatio, this.textScale, this.screenSize)
  : rect = Rect.fromLTWH(0, 0, size.width, size.height),
  key = UniqueKey();

  PaintParameters.copyFrom(this.canvas, PaintParameters source)
  : size = source.size,
  rect = source.rect,
  key = source.key,
  devicePixelRatio = source.devicePixelRatio,
  textScale = source.textScale,
  screenSize = source.screenSize;

  void newKey()
  {
    key = UniqueKey();
  }
}