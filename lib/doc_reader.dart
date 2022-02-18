//#set-tab 2
// ignore_for_file: unused_import

import 'dart:async';
import 'package:doc_reader/objects/speech.dart';

import 'doc_span/doc_span_interface.dart';
import 'doc_span/document_word.dart';
import 'doc_span/paint_parameters.dart';
import 'document.dart';
import 'property_binder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'objects/applog.dart';
import 'dart:math' as math;

class DocReader extends StatefulWidget
{
  final String documentProperty;
  DocReader({Key? key, required this.documentProperty}) : super(key: key ?? GlobalKey(debugLabel: 'DocReader'));

  @override
  State<DocReader> createState() => _DocReaderState();
}

class _DocReaderState extends State<DocReader> with SingleTickerProviderStateMixin
{
  bool isDisposed = false;
  Document? document;
  int cnt = 0;
  double devicePixelRatio = 2.0;
  double textScale = 1.0;
  Size screenSize = const Size(512, 512);

  double animationTimestamp = 0.0;
  double animationSpeed = 1.0;
  double animationValue = 0.0;
  double animationDirection = 0;
  double bottomLineCorrect = 0.0;
  double touchDownCorrect = 0.0;

  int figner = -1;

  _DocReaderState();

  int get topSpanIndex => math.min(document?.position.floor() ?? 0, (document?.docSpans.length ?? 0) - 1);

  double get topSpanOffset
  {
    double result = 0.0;

    if (document?.docSpans.isNotEmpty != null && document?.paintParameters != null)
    {
      final document = this.document!;
      final params = document.paintParameters!;
      final docSpans = document.docSpans;

      result = -(document.position - document.position.floorToDouble()) * docSpans[topSpanIndex].span.height(params);
    }

    return result;
  }

  @override
  Widget build(BuildContext context)
  {
    final media = MediaQuery.of(context);
    devicePixelRatio = media.devicePixelRatio;
    screenSize = media.size;
    textScale = media.textScaleFactor;

    final document = Document.of(context);
    this.document = document;

    document.onTap = onTap;
    document.onTouchMove = onTouchMove;
    document.onTouchUpDown = onTouchUpDown;
    document.onRepaint = onRepaint;
    document.speech.speechEvent = speechEvent;

    final painter = DocumentPainter(document, this);

    final result = CustomPaint
    (
      painter: painter,
      child: Container(),
    );

    return result;
  }

  @override
  void initState()
  {
    super.initState();
    /*WidgetsBinding.instance?.addPostFrameCallback((_)
        {
          print("WidgetsBinding");
        });

        SchedulerBinding.instance?.addPostFrameCallback((_)
        {
          print("SchedulerBinding");
        });*/
  }

  @override
  void dispose()
  {
    isDisposed = true;
    super.dispose();
    document?.onTap = null;
    document?.speech.speechEvent = null;
    /*document?.onTouchMove = null;
        document?.onTouchUpDown = null;
        document?.onRepaint = null;*/
  }

  /*void _calcLayout(BuildContext context)
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
    }*/

  double animationTime()
  {
    double nowTime = DateTime.now().millisecondsSinceEpoch.toDouble();

    if (animationTimestamp == 0)
    {
      animationTimestamp = nowTime;
      return 0;
    }
    else
    {
      final result = math.max(nowTime - animationTimestamp, 0.0);
      animationTimestamp = nowTime;
      return result;
    }
  }

  bool pageAnimateStep()
  {
    bool result = false;

    if (document != null)
    {
      final document = this.document!;
      bool needRefresh = animationDirection != 0.0;
      final time = animationTime();
      var step = time * animationSpeed;

      if (animationValue > 0)
      {
        result = true;
        if (step > animationValue)
        {
          step = animationValue;
          animationValue = 0.0;
        }
        else
        {
          animationValue -= step;
        }
      }

      if (result && step > 1e-3)
      {
        final move = step * animationDirection;
        document.markPosition -= move;
        result = document.movePosition(move);
      }

      if (!result)
      {
        if (animationDirection < 0)
        {
          final spanIndex = document.position.truncate();
          if (spanIndex < document.docSpans.length)
          {
            final move = document.docSpans[spanIndex].span.correctYPosition(-topSpanOffset, false);
            document.movePosition(move);
          }
        }
        animationDirection = 0;
        document.markPosition = double.infinity;
      }

      if (needRefresh)
      {
        setState(() {});
      }
    }

    return result;
  }

  animatePage(double direction, [double? speed])
  {
    final document = this.document!;
    animationValue = document.actualWidgetSize.height - document.markPosition.abs();
    if (direction > 0)
    {
      if (-touchDownCorrect + 8 < document.actualWidgetSize.height)
      {
        animationValue += touchDownCorrect;
      }
    }

    if (speed != null)
    {
      animationSpeed = math.max(1e-3 * speed, 0.1);
    }
    else
    {
      animationSpeed = 1e-3 * animationValue / document.pageAnimation;
    }

    animationDirection = direction;
    animationTimestamp = 0.0;
    pageAnimateStep();
  }

  toNextPage()
  {
    if (animationDirection == 0 && document != null)
    {
      touchDownCorrect = bottomLineCorrect;
      animatePage(1.0);
    }
  }

  toPrevPage()
  {
    if (animationDirection == 0 && document != null)
    {
      touchDownCorrect = bottomLineCorrect;
      animatePage(-1.0);
    }
  }

  void onTap(double relativeX, double relativeY)
  {
//#verbose
    appLog_verbose('onTap: relativeX=${relativeX.toStringAsFixed(4)} relativeY=${relativeY.toStringAsFixed(4)}');
//#end VERBOSE line:253

    if (relativeY >= 0.75)
    {
      toNextPage();
    }
    else if (relativeY <= 0.25)
    {
      toPrevPage();
    }
    else
    {
      // TODO test
      //Future.microtask(() async => await document!.speech.speak('Start předčítání textu.'));

      //document?.onShowMenu?.call(document!);
      document?.mode = DocumentShowMode.menu;

      ///

      /*if (document?.ttsPlay ?? true)
      {
        document?.ttsStop();
      }
      else
      {
        document?.ttsStart();
      }*/
    }
  }

  void onTouchMove(double deltaX, double deltaY)
  {
    if (document?.movePosition(-deltaY) ?? false)
    {
      setState
      (
        ()
        {
//#verbose
          appLog_verbose('onTouchMove: deltaX=$deltaX deltaY=$deltaY');
//#end VERBOSE line:293
          if (document?.markPosition.isFinite ?? false)
          {
            document?.markPosition += deltaY;
          }
        }
      );
    }
  }

  void onTouchUpDown(bool down, double widgetX, double widgetY, double velocityX, double velocityY)
  {
    setState
    (
      ()
      {
        if (down)
        {
          touchDownCorrect = bottomLineCorrect;
          if (document != null)
          {
            final document = this.document!;
            document.markPosition = 0;
            document.markSize = document.actualWidgetSize.height;
          }
        }
        else
        {
          if (animationDirection == 0.0)
          {
            if (velocityY.abs() > 50.0)
            {
              animatePage(-velocityY.sign, velocityY.abs());
            }
            else
            {
              document?.markPosition = double.infinity;
            }
          }
        }
      }
    );
  }

  bool onRepaint_run = false;
  void onRepaint()
  {
    if (!onRepaint_run)
    {
      onRepaint_run = true;

      try
      {
        Future.microtask
        (
          () async
          {
            try
            {
              await Future.delayed(const Duration(milliseconds: 20));
              if (!isDisposed)
              {
                setState(() {});
              }
            }
            catch (ex, stackTrace)
            {
              appLogEx(ex, stackTrace: stackTrace);
            }
            finally
            {
              onRepaint_run = false;
            }
          }
        );
      }
      catch (ex, stackTrace)
      {
        appLogEx(ex, stackTrace: stackTrace);
      }
    }
  }

  speechEvent(SpeechState oldState, SpeechState newState, String word, int start, int end)
  {
    switch (newState)
    {
      case SpeechState.stopped:
      print('TTS STOP *****************************************');

      document?.playNextSentence();
      figner = -1;
      setState(() {});
      break;

      case SpeechState.playing:
      if (document != null)
      {
        final document = this.document!;
        final position = document.ttsWordPosition[start];
        if (position != null && word.isNotEmpty)
        {
          figner = position;
          print('Word position: $position *****************************************');
          setState(() {});
        }
        else
        {
          print('Word err pos: $start ');
        }
      }
      break;
    }
  }
}

class DocumentPainter extends CustomPainter
{
  final Document document;
  final _DocReaderState state;

  DocumentPainter(this.document, this.state);

  @override
  void paint(Canvas canvas, Size size)
  {
    try
    {
      if (state.animationDirection != 0.0)
      {
        Future.microtask(() => state.pageAnimateStep());
      }

      if (document.paintParameters == null || document.actualWidgetSize != size)
      {
        document.resetPaintState();
        document.actualWidgetSize = size;
        document.paintParameters =
        PaintParameters(canvas, size, state.devicePixelRatio, state.textScale, state.screenSize);
      }
      else
      {
        document.paintParameters = PaintParameters.copyFrom(canvas, document.paintParameters!);
      }

      final params = document.paintParameters!;

      final docSpans = document.docSpans;

      int spanIndex = state.topSpanIndex; //math.min(document.position.floor(), docSpans.length - 1);
      if (spanIndex >= 0)
      {
        double offset = state.topSpanOffset;
        double bottomTop = offset;
        double ttsBottom = double.infinity;
        double ttsTop = double.infinity;

        document.topSpanIndex = spanIndex;
        int bottomIndex = spanIndex;

        for (; spanIndex < docSpans.length && offset < size.height; spanIndex++)
        {
          bottomIndex = spanIndex;
          final container = docSpans[spanIndex];

          // Zobrazeni prehravani tts
          if (document.ttsPlay)
          {
            final markPaint = Paint()
            ..color = const Color.fromARGB(100, 128, 138, 160)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

            if (spanIndex == document.ttsSpanIndex)
            {
              // Zobrayeni vety - jako zvyrazenne radky
              /*if (document.ttsPlaySpanLines.isNotEmpty)
              {
                ttsTop = document.ttsPlaySpanLines.first.top + offset;
                ttsBottom = document.ttsPlaySpanLines.last.bottom + offset;
                for (var line in document.ttsPlaySpanLines)
                {
                  canvas.drawRect(line.translate(0, offset), markPaint);
                }
              }*/

              // Zobrazeni vety - jako zvyraznena slova
              /*for (var i in document.ttsWordPosition.values)
              {
                final info = document.ttsPlaySpanWords[i];
                final rect = info.rect.translate(0, offset);

                print('word:${info.text} ${rect.left},${rect.top},${rect.width},${rect.height}');
                canvas.drawRect(Rect.fromLTWH(rect.left, rect.bottom - 10, rect.width, 10), markPaint);
              }*/

              // Zobrazeni ukazatele na slovo
              if (state.figner >= 0 && state.figner < document.ttsPlaySpanWords.length)
              {
                // Ukazatel na slovo
                final info = document.ttsPlaySpanWords[state.figner];
                final rect = info.rect.translate(0, offset);
                if (ttsTop.isInfinite)
                {
                  ttsTop = rect.top;
                  ttsBottom = rect.bottom + 32;
                }

                canvas.drawRect(Rect.fromLTWH(rect.left, rect.bottom - 10, rect.width, 10), markPaint);
              }
            }
          }

          // Vykresleni spanu
          bottomTop = offset;
          container.span.paint(params, container.xPosition, offset);
          offset += container.span.height(params);
        }

        document.bottomSpanIndex = bottomIndex;

        if (bottomIndex < docSpans.length)
        {
          // Korekce pro prechod na dalsi stranku
          state.bottomLineCorrect = docSpans[bottomIndex].span.correctYPosition(size.height - bottomTop, true);
        }

        if (!document.ttsPlay && document.markPosition.isFinite)
        {
          // Zobrazeni oznaceni presouvane stranky
          final markPaint = Paint()..color = const Color.fromARGB(100, 128, 138, 160);
          canvas.drawRect(Rect.fromLTWH(0, document.markPosition, size.width, document.markSize), markPaint);
        }

        if (document.ttsPlay && state.animationDirection == 0.0)
        {
          // Posun zobrazeni pri prehravani TTS

          if (ttsTop.isFinite && ttsTop < 0)
          {
            state.bottomLineCorrect = 0;
            document.markPosition = size.height + ttsTop;
            Future.microtask(() => state.toPrevPage());
          }
          else if (ttsBottom.isFinite && ttsBottom > size.height)
          {
            if (ttsTop > 1)
            {
              state.bottomLineCorrect = math.max(ttsBottom - 2 * size.height, -0.25 * size.height);
              document.markPosition = 0;
              Future.microtask(() => state.toNextPage());
            }
          }
          else if (document.ttsPlaySpanIndex < state.topSpanIndex)
          {
            document.position = document.ttsPlaySpanIndex.toDouble();
            state.onRepaint();
          }
          else if (bottomIndex < docSpans.length)
          {
            if (bottomIndex < document.ttsPlaySpanIndex)
            {
              document.markPosition = 0;
              Future.microtask(() => state.toNextPage());
            }
          }
        }
      }
    }
    catch (ex, stackTrace)
    {
      appLogEx(ex, stackTrace: stackTrace);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate)
  {
    return true;
  }
}