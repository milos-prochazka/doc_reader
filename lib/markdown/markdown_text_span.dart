import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'markdown.dart';
import 'dart:math' as math;

class MarkdownTextSpan implements IDocumentSpan
{
  Key? _layoutKey;
  final _words = <MarkdownWord>[];
  final _spans = <_Span>[];
  double _width = 0;
  double _height = 0;

  static List<MarkdownTextSpan> create(Markdown markdown)
  {
    final result = <MarkdownTextSpan>[];

    for (final para in markdown.paragraphs)
    {
      result.add(MarkdownTextSpan(para));
    }

    return result;
  }

  MarkdownTextSpan(MarkdownParagraph para)
  {
    for (final word in para.words)
    {
      _words.add(word);
    }
  }

  void _updateText(PaintParameters parameters)
  {
    _spans.clear();

    double height = 0;
    double left = 0;
    double x = left;
    double y = 0;
    double h = 0;

    for (final word in _words)
    {
      var painter = TextPainter
      (
        text: TextSpan(text: word.text + ' ', style: const TextStyle(color: Colors.blue, fontSize: 20.0)),
        textDirection: TextDirection.ltr
      );

      painter.layout();

      var pWidth = painter.size.width;
      var pHeight = painter.size.height;

      if ((x + pWidth) > parameters.size.width || word.lineBreak)
      {
        x = left;
        y += h;
        h = 0;
      }
      h = math.max(pHeight, h);

      _spans.add(_Span(painter, x, y));
      x += pWidth;
    }

    _height = y + h;
    _width = parameters.size.width;
  }

  @override
  void calcSize(PaintParameters parameters)
  {
    _layoutKey = parameters.key;
    _updateText(parameters);
  }

  @override
  double height(PaintParameters params)
  {
    calcSize(params);
    return _height;
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

    for (var word in _spans)
    {
      //word.painter.layout();
      word.painter.paint(params.canvas, Offset(word.xOffset + xOffset, word.yOffset + yOffset));
    }
  }

  @override
  double width(PaintParameters params)
  {
    calcSize(params);
    return _width;
  }
}

class _Span
{
  TextPainter painter;
  double xOffset;
  double yOffset;

  _Span(this.painter, [this.xOffset = 0, this.yOffset = 0]);
}