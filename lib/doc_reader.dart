import 'dart:ui';
import 'package:flutter/material.dart';

class DocReader extends StatefulWidget
{
  @override
  State<DocReader> createState() => _DocReaderState();
}

class _DocReaderState extends State<DocReader>
{
  @override
  Widget build(BuildContext context)
  {
    return CustomPaint
    (
      painter: ShapePainter(),
      child: Container(),
    );
  }
}

class ShapePainter extends CustomPainter
{
  @override
  void paint(Canvas canvas, Size size)
  {
    var paint = Paint()
    ..color = Colors.teal
    ..strokeWidth = 5
    ..strokeCap = StrokeCap.round;

    Offset startingPoint = Offset(0, size.height / 2);
    Offset endingPoint = Offset(size.width, size.height / 2);

    canvas.drawLine(startingPoint, endingPoint, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate)
  {
    return false;
  }
}