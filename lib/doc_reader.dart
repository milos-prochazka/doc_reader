//#set-tab 4
import 'dart:ui';
import 'dart:async';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/document.dart';
import 'package:doc_reader/property_binder.dart';
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
    Document? document;
    Timer? _timer;
    int cnt = 0;
    double devicePixelRatio = 2.0;
    double textScale = 1.0;
    Size screenSize = const Size(512, 512);

    _DocReaderState();

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

    void onTap(double relativeX, double relativeY)
    {
        if (relativeY >= 0.75)
        {
            appLog();
            //_timer?.cancel();
            _timer = Timer.periodic
            (
                const Duration(microseconds: 1000000 ~/ 60), (timer)
                {
                    setState
                    (
                        ()
                        {
                            document?.position += 1;
                        }
                    );
                }
            );
        }

        setState
        (
            ()
            {
                appLog('onTap: relativeX=${relativeX.toStringAsFixed(4)} relativeY=${relativeY.toStringAsFixed(4)}');
            }
        );
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
        if (down)
        {
            setState
            (
                ()
                {
                    document?.markPosition = widgetY;
                    document?.markSize = 100;
                }
            );
        }
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
                            print("onRepiant() -------------------------------------------------------------");
                            await Future.delayed(const Duration(milliseconds: 20));
                            setState(() {});
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

            int spanIndex = math.min(document.position.floor(), docSpans.length - 1);
            if (spanIndex >= 0)
            {
                double offset =
                -(document.position - document.position.floorToDouble()) * docSpans[spanIndex].span.height(params);

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