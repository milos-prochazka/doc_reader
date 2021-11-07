//#set-tab 4
import 'dart:ui';
import 'dart:async';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/document.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:flutter/material.dart';

import 'doc_span/objects/applog.dart';

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

    _DocReaderState();

    @override
    Widget build(BuildContext context)
    {
        //_calcLayout(context);
        final document =
        PropertyBinder.of(context).getOrCreateProperty<Document>(widget.documentProperty, (binder) => Document());
        this.document = document;

        document.onTap = onTap;
        document.onTouchMove = onTouchMove;
        document.onTouchUpDown = onTouchUpDown;

        final painter = DocumentPainter(document);

        return CustomPaint
        (
            painter: painter,
            child: Container(),
        );
    }

    @override
    void dispose()
    {
        super.dispose();
        document?.onTap = null;
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
}

class DocumentPainter extends CustomPainter
{
    final Document document;

    DocumentPainter(this.document);

    @override
    void paint(Canvas canvas, Size size)
    {
        final params = PaintParameters(canvas, size);
        document.paintParameters = params;

        if (document.actualWidgetSize != size)
        {
            document.actualWidgetSize = size;
        }

        final docSpans = document.docSpans;

        int spanIndex = document.position.floor();
        double offset = -(document.position - document.position.floorToDouble()) * docSpans[spanIndex].span.height(params);

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

    @override
    bool shouldRepaint(CustomPainter oldDelegate)
    {
        return true;
    }
}