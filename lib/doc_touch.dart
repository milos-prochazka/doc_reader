import 'dart:developer';

import 'package:doc_reader/doc_reader.dart';
import 'package:doc_reader/document.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:flutter/material.dart';

import 'objects/applog.dart';

class DocTouch
{
  DocReader docReader;
  late Document document;
  Offset _downPoint = Offset.infinite;
  bool isDown = false;

  DocTouch._internal(BuildContext context, this.docReader, String documentProperty)
  {
    document = PropertyBinder.of(context).getProperty<Document?>(documentProperty, null)!;
  }

  static Widget build({required BuildContext context, Key? key, required String documentProperty})
  {
    final touch = DocTouch._internal(context, DocReader(documentProperty: documentProperty), documentProperty);

    return GestureDetector
    (
      key: key,
      child: touch.docReader,
      onTap: touch.onTap,
      onTapDown: touch.onTapDown,
      onTapUp: touch.onTapUp,
      onPanDown: touch.onPanDown,
      onPanStart: touch.onPanStart,
      onPanUpdate: touch.onPanUpdate,
      onPanEnd: touch.onPanEnd,
      onPanCancel: touch.onPanCancel,
    );
  }

  void _down(Offset downPoint)
  {
    if (!isDown)
    {
      _downPoint = downPoint;
      isDown = true;
      document.onTouchUpDown?.call(true, downPoint.dx, downPoint.dy);
    }
  }

  void _up(Offset upPoint)
  {
    _downPoint = Offset.infinite;

    if (isDown)
    {
      isDown = false;
      document.onTouchUpDown?.call(true, upPoint.dx, upPoint.dy);
    }
  }

  void onPanDown(DragDownDetails details)
  {
    appLog_debug
    (
      'onPanDown:'
      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)}'
    );

    _down(details.localPosition);
  }

  void onPanStart(DragStartDetails details)
  {
    appLog_debug
    (
      'onPanStart:'
      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)} '
      'kind=${details.kind ?? 'no kind'} timestamp=${details.sourceTimeStamp}'
    );
    _down(details.localPosition);
  }

  void onPanUpdate(DragUpdateDetails details)
  {
    appLog_debug
    (
      'onPanUpdate:'
      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)} '
      'dx=${details.delta.dx.toStringAsFixed(1)} dy=${details.delta.dy.toStringAsFixed(1)} '
      'time=${details.sourceTimeStamp}'
    );

    if (_downPoint.isFinite)
    {
      document.onTouchMove?.call(details.localPosition.dx - _downPoint.dx, details.localPosition.dy - _downPoint.dy);
      _downPoint = Offset.infinite;
    }
    else
    {
      _down(details.localPosition);
      document.onTouchMove?.call(details.delta.dx, details.delta.dy);
    }
  }

  void onPanEnd(DragEndDetails details)
  {
    appLog_debug('onPanEnd: '
      'velocity=${details.velocity} primaryVelocity=${details.primaryVelocity}');
    _up(Offset.infinite);
  }

  void _doTap(double relativeX, double relativeY)
  {
    appLog_debug('doTap: relativeX=${relativeX.toStringAsFixed(4)} relativeY=${relativeY.toStringAsFixed(4)}');
    document.onTap?.call(relativeX, relativeY);
  }

  void onTap()
  {
    appLog_debug('onTap:');

    if (_downPoint.isFinite && document.actualWidgetSize.isFinite)
    {
      _doTap(_downPoint.dx / document.actualWidgetSize.width, _downPoint.dy / document.actualWidgetSize.height);
    }
    _up(_downPoint);
  }

  void onTapDown(TapDownDetails details)
  {
    appLog_debug
    (
      'onTapDown:'
      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)}'
    );

    _down(details.localPosition);
  }

  void onPanCancel()
  {
    appLog('onPanCancel:');
    _up(_downPoint);
  }

  void onTapUp(TapUpDetails details)
  {
    appLog_debug
    (
      'onTapUp:'
      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)} '
      'kind=${details.kind}'
    );

    if (_downPoint.isFinite && document.actualWidgetSize.isFinite)
    {
      _doTap(_downPoint.dx / document.actualWidgetSize.width, _downPoint.dy / document.actualWidgetSize.height);
    }

    _up(details.localPosition);
  }
}