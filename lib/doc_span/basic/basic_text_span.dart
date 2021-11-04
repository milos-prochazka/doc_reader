import 'dart:ui';
import 'dart:math' as math;
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class BasicTextSpan implements IDocumentSpan
{
  double _height = 0.0;
  double _width = 0.0;

  String _text = '';
  List<_Word> _words = <_Word>[];

  String get text => _text;
  set text(String value)
  {
    _text = value;
    _updateText();
  }

  BasicTextSpan(this._text)
  {
    _updateText();
  }

  void _updateText()
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
        _words.add(_Word(painter));
      }
    }
  }

  Paint _createPaint()
  {
    return Paint();
  }

  @override
  void calcSize(CalcSizeParameters parameters)
  {
    _height = parameters.media.size.height;
    _width = parameters.media.size.width;

    double x = 0;
    double y = 0;
    double h = 0;

    for (var word in _words)
    {
      word.painter.layout();
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

  @override
  double get height => _height;

  @override
  void paint(Canvas canvas, Size size, double xOffset, double yOffset)
  {
    for (var word in _words)
    {
      word.painter.layout();
      word.painter.paint(canvas, Offset(word.xOffset + xOffset, word.yOffset + yOffset));
    }
  }

  @override
  double get width => _width;
}

class _Word
{
  TextPainter painter;
  double xOffset = 0;
  double yOffset = 0;

  _Word(this.painter);
}