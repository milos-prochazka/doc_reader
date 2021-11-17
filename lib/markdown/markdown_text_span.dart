import 'package:doc_reader/doc_span/color_text.dart';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/objects/applog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'markdown.dart';
import 'dart:math' as math;

final _defaultConfig =
{
  // ••●○■ □▪▫◌○●◦ꓸ
  "bullets": ["        ●  ", "        □  ", "        ■  ", "        ●  ", "        □  ", "        ■  "],
  "textStyles":
  {
    "":
    {
      "fontSize": 20,
      "fontStyle": "normal", // normal, bold, bold_italic
    },
    "h1":
    {
      "fontSize": 45,
      "fontStyle": "italic", // normal, bold, bold_italic
      "color": "Blue"
    },
    "h2":
    {
      "fontSize": 40,
      "fontStyle": "bold_italic", // normal, bold, bold_italic
      "color": "Dark Green"
    },
    "h3":
    {
      "fontSize": 35,
      "fontStyle": "bold", // normal, bold, bold_italic
    },
    "h4":
    {
      "fontSize": 30,
      "fontStyle": "normal", // normal, bold, bold_italic
    },
    "h5":
    {
      "fontSize": 28,
      "fontStyle": "normal", // normal, bold, bold_italic
    },
    "h6":
    {
      "fontSize": 25,
      "fontStyle": "bold", // normal, bold, bold_italic
      "color": "#345"
    },
  }
};

class MarkdownTextConfig
{
  dynamic config = _defaultConfig;
  _MarkdownTextConfigState _state = _MarkdownTextConfigState();
  Key? _layoutKey;

  static final _emptyCfg = <String, dynamic>{};

  T get<T>(List<dynamic> path, {dynamic config, dynamic defValue, bool lastInArray = true})
  {
    try
    {
      var cfg = config ?? this.config;

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

      if (cfg is T)
      {
        return cfg;
      }
      else if (T == double)
      {
        return cfg.toDouble() as T;
      }
      else if (T == String)
      {
        return cfg.toString() as T;
      }
      else
      {
        return defValue as T;
      }
    }
    catch ($)
    {
      return defValue as T;
    }
  }

  static final _fontStyleFromStringMap = <String, FontStyle>
  {
    'normal': FontStyle.normal,
    'bold': FontStyle.normal,
    'italic': FontStyle.italic,
    'bold_italic': FontStyle.italic,
  };

  static FontStyle _fontStyleFromString(String text)
  {
    return _fontStyleFromStringMap[text.toLowerCase()] ?? FontStyle.normal;
  }

  static final _fontWeightFromStringMap = <String, FontWeight>
  {
    'normal': FontWeight.normal,
    'bold': FontWeight.bold,
    'italic': FontWeight.normal,
    'bold_italic': FontWeight.bold,
  };

  static FontWeight _fontWeightFromString(String text)
  {
    return _fontWeightFromStringMap[text.toLowerCase()] ?? FontWeight.normal;
  }

  _WordStyle getTextStyle(MarkdownParagraph para, MarkdownWord word, {bool bullet = false})
  {
    final fullStyle = para.headClass + word.style;
    _WordStyle result;

    if (_state.textStyles.containsKey(fullStyle))
    {
      result = _state.textStyles[fullStyle]!;
    }
    else
    {
      var cfg = get<Map<String, dynamic>>(['textStyles', para.headClass], defValue: _emptyCfg);

      final styleInfo = _WordStyleInfo();

      styleInfo.fontSize = get<double>(['fontSize'], defValue: 20.0, config: cfg);

      final styleStr = get<String>(['fontStyle'], defValue: 'normal', config: cfg);
      styleInfo.fontStyle = _fontStyleFromString(styleStr);
      styleInfo.fontWeight = _fontWeightFromString(styleStr);

      final colorStr = get<String?>(['color'], config: cfg);
      styleInfo.color = colorFormText(colorStr ?? 'Black');
      var yOffset = 0.0;

      if (bullet)
      {
        //yOffset = fontSize * 0.5;
        styleInfo.fontSize *= 0.3333;
        yOffset = -styleInfo.fontSize * 0.3333;
      }

      switch (word.style)
      {
        case '_':
        case '*':
        styleInfo.fontStyle = FontStyle.italic;
        break;

        case '__':
        case '**':
        styleInfo.fontWeight = FontWeight.bold;
        break;

        case '___':
        case '***':
        styleInfo.fontStyle = FontStyle.italic;
        styleInfo.fontWeight = FontWeight.bold;
        break;
      }

      result = _WordStyle
      (
        TextStyle
        (
          color: styleInfo.color,
          fontStyle: styleInfo.fontStyle,
          fontWeight: styleInfo.fontWeight,
          fontSize: styleInfo.fontSize,
          fontFamily: "Agency Fb"
        ),
        yOffset,
      );
    }

    return result;
  }

  void _checkKey(PaintParameters params)
  {
    if (_layoutKey != params.key)
    {
      _layoutKey = params.key;
      _state = _MarkdownTextConfigState();
    }
  }

  double _bulletIntent(MarkdownParagraph para, MarkdownWord word)
  {
    if (_state.bulletIntent == null)
    {
      final style =
      getTextStyle(para, word, bullet: true); //TextStyle(color: Color.fromARGB(255, 0, 0, 160), fontSize: 10.0);
      final bullet = _Text(get(["bullets", 0], defValue: '  -'), style.textStyle).calcMetrics();
      _state.bulletIntent = bullet.width;
    }

    return _state.bulletIntent!;
  }
}

class _WordStyleInfo
{
  double fontSize = 20.0;
  FontStyle? fontStyle;
  FontWeight? fontWeight;
  Color color = Colors.black;
  double yOffset = 0.0;
}

class _WordStyle
{
  TextStyle textStyle;
  double yOffseet;

  _WordStyle(this.textStyle, this.yOffseet);
}

class _MarkdownTextConfigState
{
  double? bulletIntent;
  final textStyles = <String, _WordStyle>{};
}

class MarkdownTextSpan implements IDocumentSpan
{
  Key? _layoutKey;
  final MarkdownParagraph paragraph;
  final MarkdownTextConfig config;
  final _word = <_Word>[];
  double _width = 0;
  double _height = 0;

  MarkdownTextSpan(this.paragraph, this.config);

  static List<MarkdownTextSpan> create(Markdown markdown, MarkdownTextConfig config)
  {
    final result = <MarkdownTextSpan>[];

    for (final para in markdown.paragraphs)
    {
      result.add(MarkdownTextSpan(para, config));
    }

    return result;
  }

  void _updateText(PaintParameters parameters)
  {
    final line = _Line();

    _word.clear();
    _height = 0;
    _width = 0;

    double left = 0;
    double y = 0;

    if (_Hr.hrStyle(paragraph.headClass))
    {
      final hr = _Hr(paragraph.headClass, parameters.size.width).calcMetrics();
      y = hr.height;
      _height = y;
      _word.add(hr);
    }

    if (paragraph.words.isNotEmpty && (paragraph.decorations?.isNotEmpty ?? false))
    {
      final style = config.getTextStyle(paragraph, paragraph.words[0], bullet: true);
      final level = paragraph.decorations!.last.level;
      final word = _Text(config.get(["bullets", level], defValue: '  -'), style.textStyle).calcMetrics();
      word.yOffset = style.yOffseet;
      word.xOffset = level * config._bulletIntent(paragraph, paragraph.words[0]);

      _word.add(word);
      line.add(word);
      left = word.width + word.xOffset;
    }

    double x = left;

    for (final word in paragraph.words)
    {
      //const style = TextStyle(color: Color.fromARGB(255, 0, 0, 160), fontSize: 20.0, fontFamily: "Times New Roman", fontWeight: FontWeight.bold);
      final style = config.getTextStyle(paragraph, word);
      final wrd = _Text(word.text, style.textStyle).calcMetrics();

      var pWidth = wrd.width + wrd.wordSpacing;

      if ((x + pWidth) > parameters.size.width || word.lineBreak)
      {
        x = left;
        y = line.calcPosition(this, parameters);
      }

      wrd.xOffset = x;
      wrd.yOffset = y;
      _word.add(wrd);
      line.add(wrd);
      x += pWidth;
    }

    line.calcPosition(this, parameters);
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
    _updateSize(params);
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

    for (var word in _word)
    {
      //word.painter.layout();
      //word.painter.paint(params.canvas, Offset(word.xOffset + xOffset, word.yOffset + yOffset));
      word.paint(params, xOffset, yOffset);
    }
  }

  @override
  double width(PaintParameters params)
  {
    calcSize(params);
    return _width;
  }
}

class _Word
{
  double yOffset = 0;
  double xOffset = 0;
  double baseLine = 0;
  double wordSpacing = 0;
  double left = 0;
  double height = 0;
  double width = 0;

  _Word calcMetrics()
  {
    return this;
  }

  void paint(PaintParameters params, double xoffset, double yoffset) {}
}

class _Text extends _Word
{
  TextPainter? _painter;
  late String text;
  late TextStyle style;

  _Text(this.text, this.style);

  @override
  _Word calcMetrics()
  {
    // ignore: unused_local_variable
    final p = painter;
    return this;
  }

  TextPainter get painter
  {
    if (_painter != null)
    {
      return _painter!;
    }
    else
    {
      final p = TextPainter
      (
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      );

      p.layout(minWidth: 0.0, maxWidth: 10000.0);
      _painter = p;

      final ml = p.computeLineMetrics();

      if (ml.isNotEmpty)
      {
        final metrics = ml.first;
        wordSpacing = style.wordSpacing ?? p.height / 3;

        baseLine = metrics.ascent;
        height = metrics.height;
        width = p.size.width; // Mereni s mezerami
        //width = metrics.width; // Mereni bez mezer
        left = metrics.left;
      }

      return p;
    }
  }

  @override
  void paint(PaintParameters params, double xoffset, double yoffset)
  {
    final textPainter = painter;

    final offset = Offset(xOffset + xoffset, yOffset + yoffset);
    final rect = Rect.fromLTWH(offset.dx, offset.dy, width, height);

    if (rect.overlaps(params.rect))
    {
      textPainter.paint(params.canvas, offset);
    }
  }
}

class _Hr extends _Word
{
  String style;

  static bool hrStyle(String style)
  {
    switch (style)
    {
      case '===':
      case '***':
      case '___':
      case '---':
      return true;

      default:
      return false;
    }
  }

  _Hr(this.style, double width)
  {
    this.width = width;

    switch (style)
    {
      case '===':
      height = 8;
      break;

      case '***':
      height = 16;
      break;

      case '___':
      case '----':
      height = 4;
      break;
    }

    this.left = 4;
  }

  @override
  _Hr calcMetrics()
  {
    return this;
  }

  @override
  void paint(PaintParameters params, double xoffset, double yoffset)
  {
    final paint = Paint()
    ..color = Colors.grey
    ..strokeWidth = height * 0.5;

    double y = yoffset + height * 0.5;

    params.canvas.drawLine(Offset(xoffset + left, y), Offset(xoffset + width - 2 * left, y), paint);
  }
}

class _Line
{
  final _words = <_Word>[];

  void add(_Word word) => _words.add(word);

  double calcPosition(MarkdownTextSpan span, PaintParameters parameters)
  {
    if (_words.isNotEmpty)
    {
      //double y = 0;
      double asc = 0;
      double desc = 0;

      for (var word in _words)
      {
        //y = math.max(y,word.yOffset);
        asc = math.max(asc, word.baseLine);
        desc = math.max(desc, word.height - word.baseLine);
      }

      final double height = asc + desc;

      for (var word in _words)
      {
        word.yOffset += asc - word.baseLine;
      }

      span._height += height;

      _words.clear();
    }

    return span._height;
  }
}