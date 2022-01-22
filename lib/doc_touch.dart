import 'doc_reader.dart';
import 'document.dart';
import 'property_binder.dart';
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
      document.onTouchUpDown?.call(true, downPoint.dx, downPoint.dy, 0, 0);
    }
  }

  void _up(Offset upPoint, Velocity velocity)
  {
    _downPoint = Offset.infinite;

    if (isDown)
    {
      isDown = false;
      document.onTouchUpDown
      ?.call(false, upPoint.dx, upPoint.dy, velocity.pixelsPerSecond.dx, velocity.pixelsPerSecond.dy);
    }
  }

  void onPanDown(DragDownDetails details)
  {
//#verbose
//##    appLog_verbose
//##    (
//##      'onPanDown:'
//##      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
//##      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)}'
//##    );
//#end VERBOSE line:63

    _down(details.localPosition);
  }

  void onPanStart(DragStartDetails details)
  {
//#verbose
//##    appLog_verbose
//##    (
//##      'onPanStart:'
//##      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
//##      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)} '
//##      'kind=${details.kind ?? 'no kind'} timestamp=${details.sourceTimeStamp}'
//##    );
//#end VERBOSE line:77
    _down(details.localPosition);
  }

  void onPanUpdate(DragUpdateDetails details)
  {
//#verbose
//##    appLog_verbose
//##    (
//##      'onPanUpdate:'
//##      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
//##      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)} '
//##      'dx=${details.delta.dx.toStringAsFixed(1)} dy=${details.delta.dy.toStringAsFixed(1)} '
//##      'time=${details.sourceTimeStamp}'
//##    );
//#end VERBOSE line:91

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
//#verbose
//##    appLog_verbose('onPanEnd: '
//##      'velocity=${details.velocity} primaryVelocity=${details.primaryVelocity}');
//#end VERBOSE line:116
    _up(Offset.infinite, details.velocity);
  }

  void _doTap(double relativeX, double relativeY)
  {
//#verbose
//##    appLog_verbose('doTap: relativeX=${relativeX.toStringAsFixed(4)} relativeY=${relativeY.toStringAsFixed(4)}');
//#end VERBOSE line:125
    document.onTap?.call(relativeX, relativeY);
  }

  void onTap()
  {
//#verbose
//##    appLog_verbose('onTap:');
//#end VERBOSE line:133
    if (_downPoint.isFinite && document.actualWidgetSize.isFinite)
    {
      _doTap(_downPoint.dx / document.actualWidgetSize.width, _downPoint.dy / document.actualWidgetSize.height);
    }
    _up(_downPoint, Velocity.zero);
  }

  void onTapDown(TapDownDetails details)
  {
//#verbose
//##    appLog_verbose
//##    (
//##      'onTapDown:'
//##      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
//##      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)}'
//##    );
//#end VERBOSE line:145

    _down(details.localPosition);
  }

  void onPanCancel()
  {
    //appLog('onPanCancel:');
    //_up(_downPoint);
  }

  void onTapUp(TapUpDetails details)
  {
//#verbose
//##    appLog_verbose
//##    (
//##      'onTapUp:'
//##      'lx=${details.localPosition.dx.toStringAsFixed(1)} ly=${details.localPosition.dy.toStringAsFixed(1)} '
//##      'gx=${details.globalPosition.dx.toStringAsFixed(1)} gy=${details.globalPosition.dy.toStringAsFixed(1)} '
//##      'kind=${details.kind} '
//##    );
//#end VERBOSE line:165

    if (_downPoint.isFinite && document.actualWidgetSize.isFinite)
    {
      _doTap(_downPoint.dx / document.actualWidgetSize.width, _downPoint.dy / document.actualWidgetSize.height);
    }

    _up(details.localPosition, Velocity.zero);
  }
}