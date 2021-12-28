//#set-tab 2
// ignore_for_file: unused_import

import 'dart:ui';
import 'dart:async';
import 'doc_span/doc_span_interface.dart';
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
  Timer? timer;
  double animateStep = 0.0;
  int animateCount = 0;

  double animationTimestamp = 0.0;
  double animationSpeed = 1.0;
  double animationValue = 0.0;
  double animationDirection = 1;


  _DocReaderState();

  int get topSpanIndex => math.min(document?.position.floor() ?? 0, (document?.docSpans.length ?? 0) - 1);

  double get TopSpanOffset
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

    final document =
    PropertyBinder.of(context).getOrCreateProperty<Document>(widget.documentProperty, (binder) => Document());
    this.document = document;

    document.onTap = onTap;
    document.onTouchMove = onTouchMove;
    document.onTouchUpDown = onTouchUpDown;
    document.onRepaint = onRepaint;

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
    double nowTime = new DateTime.now().millisecondsSinceEpoch.toDouble();

    if (animationTimestamp == 0 )
    {
        animationTimestamp = nowTime;
        return 0;
    }
    else
    {
        final result =  math.max(nowTime - animationTimestamp,0.0);
        animationTimestamp = nowTime;
        return result;
    }
  }

  bool pageAnimateStep()
  {
    bool result = false;
    bool needRefresh = animationDirection != 0.0;
    final time = animationTime();
    var step = time * animationSpeed;


    if (animationValue > 0)
    {
        result = true;
        if (step>animationValue)
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
      result = document?.movePosition(step*animationDirection) ?? false;
    }

    if (!result)
    {
      document?.alignPosition(animateStep < 0);
      animationDirection = 0;
    }

    if (needRefresh)
    {
      setState(() {});
    }
    
    return result;
  }

  // TODO zrusit
  animatePage(int fps, Document document)
  {
    final document = this.document!;
    final fps = document.animateFPS.toInt();

    timer = Timer.periodic
    (
      Duration(microseconds: 1000000 ~/ fps), (timer)
      {
        setState
        (
          ()
          {
            final move = document.movePosition(animateStep);
            if (!move || --animateCount <= 0)
            {
              document.alignPosition(animateStep < 0);
              timer.cancel();
              this.timer = null;
              document.markPosition = double.infinity;
            }
            else
            {
              document.markPosition -= animateStep;
            }
          }
        );
      }
    );
  }

  toNextPage()
  {
    if (animationDirection == 0 && document != null)
    {
      /*final document = this.document;
      final fps = document!.animateFPS.toInt();
      animateCount = (document.animateFPS * document.pageAnimation).toInt();
      animateStep = 1 / animateCount * document.actualWidgetSize.height;

      animatePage(fps, document);*/
      animationValue = document!.actualWidgetSize.height;
      animationSpeed = 1.0;
      animationDirection = 1.0;
      animationTimestamp = 0.0;
      pageAnimateStep();
    }
  }

  toPrevPage()
  {
    if (animationDirection == 0 && document != null)
    {
      /*final document = this.document;
      final fps = document!.animateFPS.toInt();
      animateCount = (document.animateFPS * document.pageAnimation).toInt();
      animateStep = -1 / animateCount * document.actualWidgetSize.height;

      animatePage(fps, document);*/
      animationValue = document!.actualWidgetSize.height;
      animationSpeed = 1.0;
      animationDirection = -1.0;
      animationTimestamp = 0.0;
      pageAnimateStep();
    }
  }

  void onTap(double relativeX, double relativeY)
  {
    appLog('onTap: relativeX=${relativeX.toStringAsFixed(4)} relativeY=${relativeY.toStringAsFixed(4)}');

    if (relativeY >= 0.75)
    {
      toNextPage();
    }
    else if (relativeY <= 0.25)
    {
      toPrevPage();
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
          appLog('onTouchMove: deltaX=$deltaX deltaY=$deltaY');
          if (document?.markPosition.isFinite ?? false)
          {
            document?.markPosition += deltaY;
          }
        }
      );
    }
  }

  void onTouchUpDown(bool down, double widgetX, double widgetY)
  {
    setState
    (
      ()
      {
        if (down)
        {
          document?.markPosition = 0;
          document?.markSize = screenSize.height;
        }
        else
        {
          if (timer == null)
          {
            document?.markPosition = double.infinity;
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
}

/*class DocReaderPainter extends StatefulWidget
{
    final String documentProperty;
    DocReaderPainter({Key? key, required this.documentProperty}) : super(key: key ?? GlobalKey(debugLabel: 'DocReader'));

  @override
  State<DocReaderPainter> createState() => _DocReaderPainterState();
}

class _DocReaderPainterState extends State<DocReaderPainter> {
  @override
  Widget build(BuildContext context)
  {
        final document =
        PropertyBinder.of(context).getOrCreateProperty<Document>(widget.documentProperty, (binder) => Document());

       final painter = DocumentPainter(document);

        final result =   CustomPaint
        (
            painter: painter,
            child: Container(),
        );

        return result;
   }
}*/

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

      // TODO predelat ziskavani PaintParameters do document
      if (document.paintParameters == null || document.actualWidgetSize != size)
      {
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
        double offset = state.TopSpanOffset;
        //-(document.position - document.position.floorToDouble()) * docSpans[spanIndex].span.height(params);

        for (; spanIndex < docSpans.length && offset < size.height; spanIndex++)
        {
          final container = docSpans[spanIndex];
          container.span.paint(params, container.xPosition, offset);
          offset += container.span.height(params);
        }

        if (document.markPosition.isFinite)
        {
          final markPaint = Paint()..color = const Color.fromARGB(100, 128, 138, 160);
          canvas.drawRect(Rect.fromLTWH(0, document.markPosition, size.width, document.markSize), markPaint);
          appLog('MarkSize=${document.markSize}');
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