import 'doc_span/document_word.dart';
import 'objects/speech.dart';
import 'objects/utils.dart';
import 'package:flutter/widgets.dart';
import 'doc_span/doc_span_interface.dart';
import 'doc_span/paint_parameters.dart';
import 'dart:math' as math;

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

  /// Index spanu ktery je cten
  int ttsSpanIndex = 0;

  /// Index slova prvniho slova ktere bude preteno
  int ttsSpanWordIndex = 0;

  /// Engine pro cteni textu
  final speech = Speech();

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

  List<DocumentWordInfo> getWordsInfo(int startIndex, int endIndex,
    [bool setOffset = false, double xOffset = 0.0, double yOffset = 0.0])
  {
    final result = <DocumentWordInfo>[];

    if (paintParameters != null)
    {
      final parameters = paintParameters!;

      startIndex = math.max(startIndex, 0);
      endIndex = math.min(endIndex, docSpans.length - 1);

      for (int i = startIndex; i <= endIndex; i++)
      {
        final span = docSpans[i].span;
        if (setOffset)
        {
          int sIndex = result.length;
          span.getSpanWords(result, parameters, i, true);
          while (sIndex < result.length)
          {
            result[sIndex++].translate(xOffset, yOffset);
          }
          yOffset += span.height(parameters);
        }
        else
        {
          span.getSpanWords(result, parameters, i, true);
        }
      }
    }

    return result;
  }

  String getTtsSentence([bool gotoNext = true])
  {
    /// test
    if (ttsSpanIndex >= docSpans.length)
    {
      ttsSpanWordIndex = 0;
      ttsSpanIndex = 0;
    }

    ///
    var words = getWordsInfo(ttsSpanIndex, ttsSpanIndex);
    if (ttsSpanWordIndex >= words.length)
    {
      ttsSpanIndex++;
      ttsSpanWordIndex = 0;
      words = getWordsInfo(ttsSpanIndex, ttsSpanIndex);
    }

    /*var j = ttsSpanWordIndex;
        var k = ttsSpanWordIndex;
        // ignore: empty_statements, curly_braces_in_flow_control_structures
        //for (; j > 0 && !words[j - 1].isTssEnd; j--);
        // ignore: empty_statements, curly_braces_in_flow_control_structures
        for (; k < words.length && !words[k].isTssEnd; k++);


        final builder = StringBuffer();
        for (var l = j; l <= k; l++)
        {
          builder.write(words[l].text);
          builder.write(' ');
        }

        if (gotoNext)
        {
            ttsSpanWordIndex = k+1;
        }*/

    final builder = StringBuffer();
    var i = ttsSpanWordIndex;
    for (; i < words.length; i++)
    {
      final txt = words[i].text ?? '';
      builder.write(txt);
      if (builder.length > 300) break;
      if (builder.length > 150 && (txt.contains(',') || txt.contains(';'))) break;
      if (words[i].isTssEnd)
      {
        break;
      }
      else
      {
        builder.write(' ');
      }
    }

    if (gotoNext)
    {
      ttsSpanWordIndex = i + 1;
    }
    var result = builder.toString();
    print('TTS:$result');

    return result;
  }
}

typedef OnTapHandler = Function(double relativeX, double relativeY);
typedef OnTouchUpDownHandler = Function(bool down, double widgetX, double widgetY, double velocityX, double velocityY);
typedef OnTouchMoveHandler = Function(double deltaX, double deltaY);
typedef OnRepaintHandler = Function();
typedef OnOpenHandler = Future<bool> Function(String name, Document document, dynamic config);