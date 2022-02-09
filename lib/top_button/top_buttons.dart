import 'package:flutter/material.dart';
import 'dart:math' as Math;

typedef TopButtonBuilder = Widget Function(BuildContext context, TopButtonItem item);

class TopButtons extends StatefulWidget
{
  final List<TopButtonItem> buttons;
  final TopButtonsControl control = TopButtonsControl();
  final Color foregroundColor;
  final Color backgroundColor;
  TopButtonEvent? event;

  TopButtons(this.buttons,
    {Key? key, this.foregroundColor = Colors.white, this.backgroundColor = Colors.black, this.event})
  : super(key: key)
  {
    for (var item in buttons)
    {
      item.foregroundColor = foregroundColor;
      item.backgroundColor = backgroundColor;
      item.event = event;
    }
  }

  @override
  State<TopButtons> createState() => _TopButtonsState();
}

class TopButtonsControl
{
  _TopButtonsState? state;

  TopButtonsControl()
  {
    var brk = 1;
  }

  set visible(bool value)
  {
    if (state != null)
    {
      var state = this.state!;
      if (state._visible != value)
      {
        state._visible = value;
        if (value)
        {
          state.menuAnimation.forward();
        }
        else
        {
          state.menuAnimation.reverse();
        }
      }
    }
  }

  bool get visible => state?._visible ?? false;
}

class _TopButtonsState extends State<TopButtons> with SingleTickerProviderStateMixin
{
  bool _visible = false;
  late AnimationController menuAnimation;
  _TopButtonsMeasure? measure;
  final itemsInfo = <TopButtonItem>[];

  _TopButtonsState();

  @override
  Widget build(BuildContext context)
  {
    final childList = <Widget>[];
    itemsInfo.clear();

    for (var item in widget.buttons)
    {
      var newWidget = item.builder(context, item);
      itemsInfo.add(item);
      childList.add(newWidget);
    }

    return OrientationBuilder
    (
      builder: (context, orientation)
      {
        measure = null;
        menuAnimation.reset();
        _visible = false;

        return Flow
        (
          delegate: _FlowDelegate(menuAnimation: menuAnimation, state: this),
          children: childList,
        );
      }
    );
  }

  @override
  void initState()
  {
    super.initState();
    widget.control.state = this;
    menuAnimation = AnimationController
    (
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }
}

class TopButtonItem
{
  String? id;
  TopButtonBuilder builder;
  late double relativewidth;
  TopButtonType type;
  double viewLeft = 0;
  double viewTop = 0;
  double viewWidth = 0;
  double viewHeight = 0;
  double hideLeft = 0;
  double hideTop = 0;
  double hideWidth = 0;
  double hideHeight = 0;
  Color foregroundColor = Colors.black;
  Color backgroundColor = Colors.white;
  TopButtonEvent? event;

  TopButtonItem({this.id, required this.type, required this.builder, double? relativeWidth, this.event})
  {
    // ignore: unnecessary_this
    this.relativewidth = relativeWidth ?? 1;
  }
}

enum TopButtonType { top, bottom, left, right, center }

class _FlowDelegate extends FlowDelegate
{
  final Animation<double> menuAnimation;
  final _TopButtonsState state;

  _FlowDelegate({required this.menuAnimation, required this.state}) : super(repaint: menuAnimation);

  @override
  bool shouldRepaint(_FlowDelegate oldDelegate)
  {
    return menuAnimation != oldDelegate.menuAnimation;
  }

  _TopButtonsMeasure calcMeasure(FlowPaintingContext context)
  {
    var result = _TopButtonsMeasure();

    final topList = <TopButtonItem>[];
    final bottomList = <TopButtonItem>[];
    final width = context.size.width;
    final height = context.size.height;
    final landscape = width > height;

    result.landscape = landscape;

    // ---------------------------------------------------------
    for (var item in state.widget.buttons)
    {
      switch (item.type)
      {
        case TopButtonType.top:
        topList.add(item);
        break;

        case TopButtonType.bottom:
        bottomList.add(item);
        break;

        default:
        break;
      }
    }

    // Top buttony ---------------------------------------------
    double sumWidth = topList.fold(0.0, (a, b) => a + b.relativewidth);

    if (result.landscape)
    {
      result.topButtonWidth = width / sumWidth;
      result.topLineHeight = result.topButtonWidth / 2;
    }
    else
    {
      result.topButtonWidth = Math.min(width / sumWidth, height / 5);
      result.topLineHeight = result.topButtonWidth;
    }

    double left = 0;
    for (var item in topList)
    {
      item.viewLeft = left;
      item.viewTop = 0;
      item.viewWidth = result.topButtonWidth * item.relativewidth;
      item.viewHeight = result.topLineHeight;
      left += item.viewWidth;
    }

    // Bottom buttony ----------------------------------------------
    sumWidth = bottomList.fold(0.0, (a, b) => a + b.relativewidth);

    if (result.landscape)
    {
      result.bottomButtonWidth = width / sumWidth;
      result.bottomLineHeight = result.bottomButtonWidth / 2;
    }
    else
    {
      result.bottomButtonWidth = Math.min(width / sumWidth, height / 5);
      result.bottomLineHeight = result.bottomButtonWidth;
    }

    left = 0;
    for (var item in bottomList)
    {
      item.viewLeft = left;
      item.viewWidth = result.bottomButtonWidth * item.relativewidth;
      item.viewHeight = result.bottomLineHeight;
      item.hideTop = height;
      item.viewTop = height - item.viewHeight;
      left += item.viewWidth;
    }

    state.measure = result;

    return result;
  }

  static double translate(double relative, double min, double max)
  {
    return min + relative * (max - min);
  }

  @override
  void paintChildren(FlowPaintingContext context)
  {
    double dx = menuAnimation.value;
    final measure = state.measure ?? calcMeasure(context);

    for (int i = 0; i < context.childCount; ++i)
    {
      var info = state.itemsInfo[i];

      //print("paintChildren $dx ${context.size.height}");
      var s = context.getChildSize(i)!;
      var w = context.size;

      var matrix = Matrix4.diagonal3Values(info.viewWidth / s.width * dx, info.viewHeight / s.height * dx, 1);
      matrix.setTranslationRaw(info.viewLeft * dx, translate(dx, info.hideTop, info.viewTop), 0);
      //matrix.translate(-s.width * 0.5, -s.height * 0.5, 0.0);
      //matrix.rotateZ(0.1);
      //matrix.translate(s.width * 0.5, s.height * 0.5, 0.0);
      //matrix.translate(10.0,1.0,0.0);

      //matrix.translate(10,10.0,0.0);
      context.paintChild
      (
        i,
        transform: matrix,
      );
    }
  }
}

class _TopButtonsMeasure
{
  bool landscape = false;
  double topLineHeight = 100;
  double topButtonWidth = 100;
  double bottomLineHeight = 100;
  double bottomButtonWidth = 100;
}

/// Typ prikazu top button
enum TopButtonCmdType { click }

/// Parametry prikazu Top button
class TopButtonCmd
{
  TopButtonCmdType cmdType = TopButtonCmdType.click;
  String id = '?';
}

/// Udalost TopButton
typedef TopButtonEvent = void Function(TopButtonCmd cmd);