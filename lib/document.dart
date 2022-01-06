import 'objects/utils.dart';
import 'package:flutter/widgets.dart';
import 'doc_span/doc_span_interface.dart';
import 'doc_span/paint_parameters.dart';

class Document
{
  /// Konfigurace pouzita pro zobrazeni dokumentu
  dynamic config;

  /// Aktualni pozice v dokumentu
  double position = 0.0;

  /// Aktualni velikost Widgetu ktery zobrazuje dokument
  Size actualWidgetSize = Size.infinite;

  /// Aktualni parametry vykreslovani Widgetu
  PaintParameters? paintParameters;

  /// Handler kliknuti
  OnTapHandler? onTap;

  /// Handler posunu prstu po widgetu dokumentu
  OnTouchMoveHandler? onTouchMove;

  /// Handler polozeni a uvoleni prstu na widggetu
  OnTouchUpDownHandler? onTouchUpDown;

  /// Handler prekresleni
  OnRepaintHandler? onRepaint;

  /// Handler otevreni souboru
  OnOpenHandler? onOpenFile;

  /// Konfigurace otevreni douboru
  dynamic onOpenFileConfig;

  /// Jednotlive casti (spany) dokumentu
  final docSpans = <DocumentSpanContainer>[];

  /// Relativni pozice vertikalni znacky v dokumentu
  double markPosition = double.nan;

  /// Relativni vyska vertikalni znacky v dokumentu
  double markSize = 0.0;

  /// Doba zmeny stranky (v sekundach)
  double pageAnimation = 0.3;

  /// Prvni zobrazeny span (index)
  int topSpanIndex = 0;

  /// Posledni zobrazeny span (index)
  int bottomSpanIndex = 0;

  /*PaintParameters getPaintParameters(Canvas canvas, Size size)
  {
    if (paintParameters?.size != size)
    {
      paintParameters = PaintParameters(canvas, size);
    }

    return paintParameters!;
  }*/

  /// Cesta k obrazkum
  String imagePath = '';

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
        final fpos = position.frac();

        if (relativeMove < 0)
        {
          if (-relativeMove > fpos)
          {
            if (position <= 0)
            {
              changePosition = false;
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
              changePosition = false;
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

  repaint()
  {
    paintParameters?.newKey();
    onRepaint?.call();
  }

  Future openFile(String name) async
  {
    final success = await onOpenFile?.call(name, this, onOpenFileConfig) ?? false;

    if (success)
    {
      repaint();
    }
  }
}

typedef OnTapHandler = Function(double relativeX, double relativeY);
typedef OnTouchUpDownHandler = Function(bool down, double widgetX, double widgetY, double velocityX, double velocityY);
typedef OnTouchMoveHandler = Function(double deltaX, double deltaY);
typedef OnRepaintHandler = Function();
typedef OnOpenHandler = Future<bool> Function(String name, Document document, dynamic config);