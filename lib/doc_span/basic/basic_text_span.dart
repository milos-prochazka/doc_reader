import 'dart:ui';
import 'dart:math' as math;
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// ignore_for_file: unnecessary_getters_setters
class BasicTextSpan implements IDocumentSpan
{
  double _height = 0.0;
  double _width = 0.0;

  String _text = '';
  final List<_Word> _words = <_Word>[];
  Key? _layoutKey;

  String get text => _text;
  set text(String value)
  {
    _text = value;
  }

  BasicTextSpan(this._text);

  void _updateText(PaintParameters parameters)
  {
    final wrtList = text.split(' ');
    _words.clear();

    for (var $ in wrtList)
    {
      final word = $.trim();

      if (word.isNotEmpty)
      {
        var painter = TextPainter
        (
          text: TextSpan(text: word + ' ', style: const TextStyle(color: Colors.grey)),
          textDirection: TextDirection.ltr
        );
        painter.layout();
        _words.add(_Word(painter));
      }
    }

    _layoutKey = parameters.key;
  }

  @override
  void calcSize(PaintParameters parameters)
  {
    _height = parameters.size.height;
    _width = parameters.size.width;

    _updateText(parameters);

    double x = 0;
    double y = 0;
    double h = 0;

    for (var word in _words)
    {
      final tWidth = word.painter.size.width;
      final tHeight = word.painter.size.height;

      if ((x + tWidth) <= _width)
      {
        word.xOffset = x;
        word.yOffset = y;
        h = math.max(tHeight, h);
        x += tWidth;
      }
      else
      {
        y += h;
        h = tHeight;
        word.xOffset = 0;
        word.yOffset = y;
        x = tWidth;
      }
    }

    _height = y + h;
  }

  void _updateSize(PaintParameters params)
  {
    if (_layoutKey != params.key)
    {
      calcSize(params);
    }
  }

  @override
  void paint(PaintParameters params, double xOffset, double yOffset)
  {
    _updateSize(params);

    for (var word in _words)
    {
      //word.painter.layout();
      word.painter.paint(params.canvas, Offset(word.xOffset + xOffset, word.yOffset + yOffset));
    }
  }

  @override
  double height(PaintParameters params)
  {
    _updateSize(params);
    return _height;
  }

  @override
  double width(PaintParameters params)
  {
    _updateSize(params);
    return _width;
  }
}

class _Word
{
  TextPainter painter;
  double xOffset = 0;
  double yOffset = 0;

  _Word(this.painter);
}