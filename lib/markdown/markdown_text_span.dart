import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'markdown.dart';
import 'dart:math' as math;

final _defaultConfig =
{
  "bullets": ["  ● ", "  ○ ", "  ■ ", "  ● ", "  ○ ", "  ■ "]
};

class MarkdownTextConfig
{
  dynamic config = _defaultConfig;
  _MarkdownTextConfigState _state = _MarkdownTextConfigState();
  Key? _layoutKey;

  T get<T>(List<dynamic> path, {dynamic defValue, bool lastInArray = true})
  {
    try
    {
      var cfg = config;

      for (var item in path)
      {
        if (item is num)
        {
          if (cfg is List)
          {
            final index = item.toInt();
            final count = cfg.length;

            if (index >= count)
            {
              if (!lastInArray)
              {
                return defValue as T;
              }
              else
              {
                cfg = cfg[count - 1];
              }
            }
            else
            {
              cfg = cfg[index];
            }
          }
          else
          {
            return defValue as T;
          }
        }
        else if (item is String)
        {
          if (cfg is Map)
          {
            // ignore: unnecessary_cast
            final key = item as String;

            if (cfg.containsKey(key))
            {
              cfg = cfg[key];
            }
            else
            {
              return defValue as T;
            }
          }
          else
          {
            return defValue as T;
          }
        }
      }

      return cfg as T;
    }
    catch ($)
    {
      return defValue as T;
    }
  }

  void _checkKey(PaintParameters params)
  {
    if (_layoutKey != params.key)
    {
      _layoutKey = params.key;
      _state = _MarkdownTextConfigState();
    }
  }

  double bulletIntent(PaintParameters params)
  {
    _checkKey(params);

    if (_state.bulletIntent == null)
    {
      final bullText = get(["bullets", 0], defValue: '  -');
      final bullPaint = TextPainter
      (
        text: TextSpan(text: bullText, style: const TextStyle(color: Color.fromARGB(255, 0, 0, 160), fontSize: 20.0)),
        textDirection: TextDirection.ltr
      );

      bullPaint.layout();
      _state.bulletIntent = bullPaint.size.width;
    }

    return _state.bulletIntent!;
  }
}

class _MarkdownTextConfigState
{
  double? bulletIntent;
}

class MarkdownTextSpan implements IDocumentSpan
{
  Key? _layoutKey;
  final MarkdownParagraph paragraph;
  final MarkdownTextConfig config;
  final _spans = <_Span>[];
  double _width = 0;
  double _height = 0;

  static List<MarkdownTextSpan> create(Markdown markdown, MarkdownTextConfig config)
  {
    final result = <MarkdownTextSpan>[];

    for (final para in markdown.paragraphs)
    {
      result.add(MarkdownTextSpan(para, config));
    }

    return result;
  }

  MarkdownTextSpan(this.paragraph, this.config);

  void _updateText(PaintParameters parameters)
  {
    _spans.clear();

    double left = 0;

    if (paragraph.decorations?.isNotEmpty ?? false)
    {
      var painter = TextPainter
      (
        text: TextSpan
        (
          text: config.get(["bullets", 0], defValue: '  -'),
          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 160), fontSize: 10.0)
        ),
        textDirection: TextDirection.ltr
      );
      painter.layout();
      _spans.add(_Span(painter, 0, 5));
      left = painter.size.width;
    }

    double x = left;
    double y = 0;
    double h = 0;

    for (final word in paragraph.words)
    {
      var painter = TextPainter
      (
        text: TextSpan
        (
          text: word.text + ' ', style: const TextStyle(color: Color.fromARGB(255, 0, 0, 160), fontSize: 20.0)
        ),
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