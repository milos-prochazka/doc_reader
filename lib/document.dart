import 'package:doc_reader/property_binder.dart';

import 'doc_span/document_word.dart';
import 'objects/applog.dart';
import 'objects/speech.dart';
import 'objects/utils.dart';
import 'package:flutter/widgets.dart';
import 'doc_span/doc_span_interface.dart';
import 'doc_span/paint_parameters.dart';
import 'dart:math' as math;

class Document
{
  /// Property pouzivane pri bindovani dokumentu
  static const documentProperty = 'document';

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

  /// Handler zpracovani udalosti "nahran novy soubor"
  OnReloadHandler? onReload;

  /// Handler prekresleni
  OnRepaintHandler? onRepaint;

  /// Handler otevreni souboru
  OnOpenHandler? onOpenFile;

  /// Handler zobrazeni menu
  OnShowMenu? onShowMenu;

  /// Konfigurace otevreni douboru
  dynamic onOpenFileConfig;

  /// Jednotlive casti (spany) dokumentu
  final docSpans = <DocumentSpanContainer>[];

  /// Obsah dokumentu
  DocumentContent? documentContent;

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

  /// Index spanu ktery je prehravan
  int ttsPlaySpanIndex = -1;

  /// Slova spanu ktery se prehrava
  var ttsPlaySpanWords = <DocumentWordInfo>[];

  /// Indexy slov v prehravanem vete => konverze pocatku slova ve vete na index slova ve spanu
  final ttsWordPosition = <int, int>{};

  /// Radky prehravaneho stavu
  var ttsPlaySpanLines = <Rect>[];

  /// Flag - probiha prehravani TTS
  var _ttsPlay = false;
  bool get ttsPlay => _ttsPlay;

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
        if (spanIndex >= 0 && spanIndex < docSpans.length)
        {
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
    }

    return changePosition;
  }

  repaint()
  {
    paintParameters?.newKey();
    onRepaint?.call();
  }

  reload()
  {
    paintParameters?.newKey();
    onReload?.call(this);
    repaint();
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

  //
  List<Rect> _makeLines(List<DocumentWordInfo> words)
  {
    final result = <Rect>[];
    double top = double.infinity;
    double left = double.infinity;
    double right = double.infinity;
    double bottom = double.infinity;

    for (var word in words)
    {
      final nextLine = bottom.isFinite && word.rect.top + 1 >= bottom;
      if (nextLine)
      {
        result.add(Rect.fromLTRB(left, top, right, bottom));
        top = double.infinity;
        left = double.infinity;
        right = double.infinity;
        bottom = double.infinity;
      }

      left = (left.isInfinite || left > word.rect.left) ? word.rect.left : left;
      right = (right.isInfinite || right < word.rect.right) ? word.rect.right : right;
      top = (top.isInfinite || top > word.rect.top) ? word.rect.top : top;
      bottom = (bottom.isInfinite || bottom < word.rect.bottom) ? word.rect.bottom : bottom;

      if (word == words.last)
      {
        if (top.isFinite)
        {
          result.add(Rect.fromLTRB(left, top, right, bottom));
        }
      }
    }

    return result;
  }

  DocumentSentence getTtsSentence([bool gotoNext = true])
  {
    final result = DocumentSentence();

    ttsWordPosition.clear();

    /// test - skok na zacatek
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

    ttsPlaySpanIndex = ttsSpanIndex;
    ttsPlaySpanWords = words;

    final builder = StringBuffer();
    var wordIndex = ttsSpanWordIndex;
    final selectedWords = <DocumentWordInfo>[];

    for (; wordIndex < words.length; wordIndex++)
    {
      final word = words[wordIndex];
      final txt = word.text ?? '';

      selectedWords.add(word);

      if (txt.isNotEmpty)
      {
        if (builder.isNotEmpty)
        {
          builder.write(' ');
        }

        ttsWordPosition[builder.length] = wordIndex;
        builder.write(txt);
      }

      if (builder.length > 300)
      {
        break;
      }

      if (builder.length > 150 && (txt.contains(',') || txt.contains(';')))
      {
        break;
      }

      if (word.isPause)
      {
        result.pause = word.pause.toDouble();
        break;
      }

      if (word.isTssEnd)
      {
        break;
      }
    }

    if (gotoNext)
    {
      ttsSpanWordIndex = wordIndex + 1;
    }

    ttsPlaySpanLines = _makeLines(selectedWords);

    result.text = builder.toString();

    print('TTS:${result.text}');

    return result;
  }

  int _speechPause = 0;

  Future<bool> _playPause() async
  {
    bool result = false;

    if (_speechPause > 0)
    {
      print('- wait ------------------------');
      await Future.delayed(Duration(milliseconds: _speechPause));
      _speechPause = 0;
      print('>>>>>>>>>>>>>>>>>>>>>');
      result = true;
    }

    return result;
  }

  playNextSentence()
  {
    if (_ttsPlay)
    {
      Future.microtask
      (
        () async
        {
          DocumentSentence text;
          bool repeat = true;

          await _playPause();

          do
          {
            text = getTtsSentence();
            _speechPause = math.min(text.pause, 5000).toInt();

            if (text.text.isNotEmpty)
            {
              await speech.speak(text.text);
              repeat = false;
            }
            else
            {
              await _playPause();
            }
          }
          while (repeat && _ttsPlay);
        }
      );
    }
  }

  ttsStart()
  {
    if (!_ttsPlay)
    {
      _ttsPlay = true;
      try
      {
        playNextSentence();
      }
      catch (ex, stackTrace)
      {
        appLogEx(ex, stackTrace: stackTrace);
      }
    }
  }

  ttsStop()
  {
    if (_ttsPlay)
    {
      _ttsPlay = false;
      ttsSpanIndex = ttsPlaySpanIndex;
      ttsSpanWordIndex = 0;
      Future.microtask
      (
        () async
        {
          try
          {
            await speech.stop();
          }
          catch (ex, stackTrace)
          {
            appLogEx(ex, stackTrace: stackTrace);
          }
        }
      );
    }
  }

  resetPaintState()
  {
    ttsWordPosition.clear();
    ttsPlaySpanLines.clear();
    ttsPlaySpanWords.clear();
  }

  static doOn(BuildContext context, DoOnDocument caller) => caller(context, of(context));

  static Document of(BuildContext context) =>
  PropertyBinder.of(context).getOrCreateProperty<Document>(documentProperty, (binder) => Document());
}

class DocumentSentence
{
  String text = '';
  double pause = 0;
}

class DocumentContent
{
  var lines = <DocumentContentLine>[];
  String caption = '';

  bool get isEmpty => lines.isEmpty && caption.isEmpty;
}

class DocumentContentLine
{
  int level;
  String text;
  bool title;

  DocumentContentLine(this.text, this.level, this.title);
}

abstract class IDocumentContentSource
{
  DocumentContent getContent();
}

typedef OnTapHandler = Function(double relativeX, double relativeY);
typedef OnTouchUpDownHandler = Function(bool down, double widgetX, double widgetY, double velocityX, double velocityY);
typedef OnTouchMoveHandler = Function(double deltaX, double deltaY);
typedef OnRepaintHandler = Function();
typedef OnReloadHandler = Function(Document document);
typedef OnOpenHandler = Future<bool> Function(String name, Document document, dynamic config);
typedef OnShowMenu = Function(Document document);
typedef DoOnDocument(BuildContext context, Document document);