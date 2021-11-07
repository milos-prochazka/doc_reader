import 'package:flutter/widgets.dart';
import 'dart:math' as math;
import 'doc_span/doc_span_interface.dart';

class Document
{
  /// Aktualni pozice v dokumentu
  double position = 1.0;

  /// Aktualni velikost Widgetu ktery zobrazuje dokument
  Size actualWidgetSize = Size.infinite;

  /// Aktualni parametry vykreslovani Widgetu
  PaintParameters? paintParameters;

  /// Handler kliknuti
  OnTapHandler? onTap;

  /// Handler posunu prstu po widgetu dokumentu
  OnTouchMoveHandler? onTouchMove;

  /// Handler polozeni a uvoleni prstu na widggetu
  OnTouchUpDown? onTouchUpDown;

  /// Jednotlive casti (spany) dokumentu
  final docSpans = <DocumentSpanContainer>[];

  /// Relativni pozice vertikalni znacky v dokumentu
  double markPosition = double.nan;

  /// Relativni vyska vertikalni znacky v dokumentu
  double markSize = 0.0;

  PaintParameters getPaintParameters(Canvas canvas, Size size)
  {
    if (paintParameters?.size != size)
    {
      paintParameters = PaintParameters(canvas, size);
    }

    return paintParameters!;
  }

  double frac(double x)
  {
    return x - x.floorToDouble();
  }

  bool movePosition(double absoluteMove)
  {
    bool changePosition = false;

    if (paintParameters != null)
    {
      while (absoluteMove.abs() > 1e-6)
      {
        changePosition = true;
        final spanIndex = position.floor();
        final height = docSpans[spanIndex].span.height(paintParameters!);
        final relativeMove = absoluteMove / height;
        final fpos = frac(position);

        if (relativeMove < 0)
        {
          if (-relativeMove > fpos)
          {
            if (position <= 0)
            {
              break;
            }
            else
            {
              if (fpos > 1e-6)
              {
                absoluteMove += fpos * height;
                position = position.floorToDouble();
              }
              else
              {
                if (position <= 1.0)
                {
                  position = 0;
                  absoluteMove = 0;
                }
                else
                {
                  position -= 1.0;
                  absoluteMove += docSpans[position.floor()].span.height(paintParameters!);
                }
              }
            }
          }
          else
          {
            position += relativeMove;
            absoluteMove = 0.0;
          }
        }
        else
        {
          if ((fpos + relativeMove) >= 1.0)
          {
            if ((position + 1.99) >= docSpans.length)
            {
              break;
            }
            else
            {
              absoluteMove -= (1.0 - fpos) * height;
              position = position.floorToDouble() + 1.0;
            }
          }
          else
          {
            position += relativeMove;
            absoluteMove = 0.0;
          }
        }
      }
    }

    return changePosition;
  }
}

typedef OnTapHandler = Function(double relativeX, double relativeY);
typedef OnTouchUpDown = Function(bool down, double widgetX, double widgetY);
typedef OnTouchMoveHandler = Function(double deltaX, double deltaY);