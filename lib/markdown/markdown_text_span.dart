// ignore_for_file: constant_identifier_names, unnecessary_this

import 'dart:ui' as ui;

import 'package:doc_reader/doc_span/color_text.dart';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/objects/applog.dart';
import 'package:doc_reader/objects/picture_cache.dart';
import 'package:doc_reader/objects/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../document.dart';
import 'markdown.dart';
import 'dart:math' as math;

/// Jeden odstavec markdown
class MarkdownTextSpan implements IDocumentSpan 
{
  Key? _layoutKey;
  final MarkdownParagraph paragraph;
  final MarkdownTextConfig config;
  final _spans = <_Span>[];
  double _width = 0;
  double _height = 0;
  final Document document;
  _Blockquotes? _blockquotes;

  MarkdownTextSpan(this.paragraph, this.config, this.document);

  static List<MarkdownTextSpan> create(Markdown markdown, MarkdownTextConfig config, Document document) 
  {
    final result = <MarkdownTextSpan>[];

    for (final para in markdown.paragraphs) 
    {
      result.add(MarkdownTextSpan(para, config, document));
    }

    return result;
  }

  void _updateText(PaintParameters parameters) 
  {
    final line = _Line();

    _spans.clear();
    _height = 0;
    _width = 0;

    var paraStyle = config.getTextStyle(paragraph);

    double left = paraStyle.leftMargin;
    double right = parameters.size.width - paraStyle.rightMargin;
    if ((right - left) < 0.6 * parameters.size.width) 
    {
      left = 0.2 * parameters.size.width;
      right = 0.8 * parameters.size.width;
    }

    double y = 0;

    if (_Hr.hrStyle(paragraph.headClass)) 
    {
      final hr = _Hr(paragraph.headClass, right).calcMetrics(parameters);
      y = hr.height;
      _height = y;
      _spans.add(hr);
    }

    // Odsazeni a decorace zleva
    if (paragraph.words.isNotEmpty && (paragraph.decorations?.isNotEmpty ?? false)) 
    {
      final dec = paragraph.decorations!.last;
      bool bullet = false;
      String text;

      switch (dec.decoration) 
      {
        case 'a':
        text = '   ${numberToCharacters(dec.count, 'abcdefghijklmnopqrstuvwxyz')}. ';
        break;

        case 'A':
        text = '   ${numberToCharacters(dec.count, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')}. ';
        break;

        case '1':
        text = '   ${dec.count + 1}. ';
        break;

        case '>':
        text = '>';
        break;

        default:
        bullet = true;
        text = config.get(["bullets", dec.level], defValue: '  -');
        break;
      }

      if (text == '>') 
      {
        _blockquotes ??= _Blockquotes(config, dec.level + 1);
        left += _blockquotes?.intent ?? 0;
      } 
      else 
      {
        final style = config.getTextStyle(paragraph, word: paragraph.words[0], bullet: bullet);
        final span = _Text(text, style.textStyle, false).calcMetrics(parameters);
        span.yOffset = style.yOffseet;
        span.xOffset = dec.level * config._bulletIntent(parameters, paragraph, paragraph.words[0]);

        _spans.add(span);
        line.add(span);
        left = span.width + span.xOffset;
      }
    }

    // Vytvoreni seznamu spanu k zalomeni ----------------------------------------------------------------------------
    final prepSpans = <_Span>{};
    final leftSpans = <_Span>{};
    final rightSpans = <_Span>{};

    for (final word in paragraph.words) 
    {
      //const style = TextStyle(color: Color.fromARGB(255, 0, 0, 160), fontSize: 20.0, fontFamily: "Times New Roman", fontWeight: FontWeight.bold);
      final style = config.getTextStyle(paragraph, word: word);
      _Span span;

      switch (word.type) 
      {
        case MarkdownWord_Type.image:
        span = _Image(word.attribs, document, style.textStyle, word.stickToNext).calcMetrics(parameters);
        break;

        default:
        span = _Text(word.text, style.textStyle, word.stickToNext).calcMetrics(parameters);
        break;
      }

      span.lineBreak = word.lineBreak;

      switch (span.align) 
      {
        case _Span.ALIGN_LEFT:
        leftSpans.add(span);
        break;

        case _Span.ALIGN_RIGHT:
        rightSpans.add(span);
        break;

        default:
        prepSpans.add(span);
        break;
      }
    }

    // Zalomeni textu -----------------------------------------------------------------------------------------------
    double rightHeight = 0;
    double sizeWidth = right;

    for (final span in rightSpans) 
    {
      span.xOffset = right - span.width;
      sizeWidth = math.min(span.xOffset, sizeWidth);
      span.yOffset = rightHeight;
      rightHeight = math.max(rightHeight, span.yOffset + span.height);
      _spans.add(span);
    }

    double leftLeft = left;
    double leftHeight = 0;
    for (final span in leftSpans) 
    {
      span.xOffset = left;
      leftLeft = math.max(leftLeft, left + span.width);
      span.yOffset = leftHeight;
      leftHeight += span.height;
      _spans.add(span);
    }

    double x = leftLeft;

    // inline spany
    for (final span in prepSpans) 
    {
      final spanWidth = span.width;
      final lineWidth = y > rightHeight ? right : sizeWidth;
      var wordSpace = span.wordSpace;

      if ((x + spanWidth) > lineWidth || span.lineBreak) 
      {
        y = line.calcPosition(this, parameters);
        x = y > leftHeight ? left : leftLeft;
      }

      span.xOffset = x;
      span.yOffset = y;
      _spans.add(span);
      line.add(span);
      x += spanWidth + wordSpace;
    }

    line.calcPosition(this, parameters);
    _width = parameters.size.width;
    _height = math.max(leftHeight, math.max(_height, rightHeight));

    if (paragraph.lastInClass) 
    {
      _height += 10;
    }
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

    _blockquotes?.paint(params.canvas, yOffset, _height);

    for (var word in _spans) 
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

const _defaultConfig = 
{
  // ••●○■ □▪▫◌○●◦ꓸ
  "bullets": ["        ●  ", "        □  ", "        ■  ", "        ●  ", "        □  ", "        ■  "],
  "blockquotes": 
  {
    "color": "silver",
    "width": 5,
    "paddingLeft": 5,
    "paddingRight": 5,
  },
  "textStyles": 
  {
    "": 
    {
      "fontSize": 20,
      "fontStyle": "normal", // normal, bold, bold_italic
    },
    "indent": 
    {
      "marginLeft": 80,
      "marginRight": 80,
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

  _WordStyle getTextStyle(MarkdownParagraph para, {MarkdownWord? word, bool bullet = false}) 
  {
    final fullStyle = para.headClass + (word?.style ?? '');
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

      styleInfo.leftMargin = get<double>(['marginLeft'], defValue: 0.0, config: cfg);
      styleInfo.rightMargin = get<double>(['marginRight'], defValue: 0.0, config: cfg);

      if (bullet) 
      {
        //yOffset = fontSize * 0.5;
        styleInfo.fontSize *= 0.3333;
        yOffset = -styleInfo.fontSize * 0.3333;
      }

      switch (word?.style) 
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
          //fontFamily: styleInfo.fontFamily,
        ),
        yOffset,
        styleInfo
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

  double _bulletIntent(PaintParameters parameters, MarkdownParagraph para, MarkdownWord word) 
  {
    if (_state.bulletIntent == null) 
    {
      final style = getTextStyle(para,
        word: word, bullet: true); //TextStyle(color: Color.fromARGB(255, 0, 0, 160), fontSize: 10.0);
      final bullet = _Text(get(["bullets", 0], defValue: '  -'), style.textStyle, false).calcMetrics(parameters);
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
  double leftMargin = 0.0;
  double rightMargin = 0.0;
}

class _WordStyle 
{
  TextStyle textStyle;
  double yOffseet;
  double leftMargin;
  double rightMargin;

  _WordStyle(this.textStyle, this.yOffseet, _WordStyleInfo wsInfo)
  : leftMargin = wsInfo.leftMargin,
  rightMargin = wsInfo.rightMargin;
}

class _MarkdownTextConfigState 
{
  double? bulletIntent;
  final textStyles = <String, _WordStyle>{};
}

class _Span 
{
  static const ALIGN_INLINE = 0;
  static const ALIGN_LEFT = 1;
  static const ALIGN_RIGHT = 2;

  double yOffset = 0;
  double xOffset = 0;
  double baseLine = 0;
  double wordSpace = 0;
  double left = 0;
  double height = 0;
  double width = 0;
  bool lineBreak = false;
  int align = _Span.ALIGN_INLINE;

  bool get textBaseLine => false;

  _Span calcMetrics(PaintParameters parameters) 
  {
    return this;
  }

  void paint(PaintParameters params, double xoffset, double yoffset) {}
}

class _Text extends _Span 
{
  TextPainter? _painter;
  final String text;
  final TextStyle style;
  final bool stickToText;

  _Text(this.text, this.style, this.stickToText);

  @override
  bool get textBaseLine => true;

  @override
  _Span calcMetrics(PaintParameters parameters) 
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
        wordSpace = stickToText ? 0 : (style.wordSpacing ?? p.height / 3);

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

class _Hr extends _Span 
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

    left = 4;
  }

  @override
  _Hr calcMetrics(PaintParameters parameters) 
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

class _Image extends _Span 
{
  final Map<String, Object?> attribs;
  final TextStyle style;
  final bool stickToNext;
  ui.Image? image;
  DrawableRoot? drawableRoot;
  int count = 0;
  double imgWidth = double.nan;
  double imgOffset = double.nan;
  double lineOffset = 0;

  Document? document;

  _Image(this.attribs, this.document, this.style, this.stickToNext);

  double get _fontSize => style.fontSize ?? 20;

  @override
  bool get textBaseLine => baseLine > 0;

  String get imgSource => attribs['image'] as String;

  double? _decodeSize(double? value, String? unit, double screenSize) 
  {
    double? result;

    if (value != null) 
    {
      result = value;
      switch (unit) 
      {
        case 'em':
        result *= _fontSize;
        break;
        case '%':
        result *= 0.01 * screenSize;
      }
    }

    return result;
  }

  _setSize(PaintParameters params, PictureCacheInfo info) 
  {
    double width = info.width;
    double height = info.height;
    double aspectRatio = width / height;

    double? reqWidth = _decodeSize(attribs['width'] as double?, attribs['widthUnit'] as String?, params.size.width);
    double? reqHeight = _decodeSize(attribs['height'] as double?, attribs['heightUnit'] as String?, params.size.width);

    if (reqWidth != null) 
    {
      width = reqWidth;
      if (reqHeight == null) 
      {
        height = width / aspectRatio;
      }
    }

    if (reqHeight != null) 
    {
      height = reqHeight;
      if (reqWidth == null) 
      {
        width = height * aspectRatio;
      }
    }

    aspectRatio = width / height;

    if (params.size.height < height) 
    {
      height = params.size.height;
      width = height * aspectRatio;
    }

    if (params.size.width < width) 
    {
      width = params.size.width;
      height = width / aspectRatio;
    }

    final attr = attribs['align'];
    switch (attr) 
    {
      case 'tight-line':
      {
        count = (params.size.width + width) ~/ width;
        imgWidth = params.size.width / count;
        height = imgWidth / aspectRatio;
        imgOffset = imgWidth;
        width = params.size.width;
      }
      break;

      case 'tight-center-line':
      {
        imgWidth = width;
        imgOffset = width;
        count = (params.size.width) ~/ width;
        width = params.size.width;
        lineOffset = 0.5 * (width - count * imgWidth);
      }
      break;

      case 'line':
      case 'center-line':
      {
        count = params.size.width ~/ width;
        imgWidth = width;
        width = params.size.width;

        if (attr == 'center-line') 
        {
          imgOffset = width / count;
          lineOffset = 0.5 * (imgOffset - imgWidth);
        } 
        else 
        {
          imgOffset = width / count;
          imgOffset += (count > 1) ? (imgOffset - imgWidth) / (count - 1) : 0.5 * ((imgOffset - imgWidth));
        }
      }
      break;

      case 'fill-line':
      {
        count = params.size.width ~/ width;
        imgWidth = params.size.width / count;
        imgOffset = imgWidth;
        if (reqHeight == null) 
        {
          height = imgWidth / aspectRatio;
        }
        width = params.size.width;
      }

      break;

      case 'center':
      count = 1;
      lineOffset = 0.5 * (params.size.width - width);
      imgWidth = width;
      width = params.size.width;
      break;

      case 'left':
      align = _Span.ALIGN_LEFT;
      break;

      case 'right':
      align = _Span.ALIGN_RIGHT;
      break;
    }

    this.wordSpace = this.stickToNext ? 0 : _fontSize / 3;
    this.width = width;
    this.height = height;
    this.baseLine = height;
  }

  bool _loadLock = false;
  _load(PaintParameters params) async 
  {
    print("_load()");

    if (!_loadLock) 
    {
      try 
      {
        _loadLock = true;
        final cache = PictureCache();
        var info = cache.getOrCreateInfo(imgSource);
        var repaint = true; //!info.hasPicture;

        //if (repaint)
        {
          info = await PictureCache().imageAsync(imgSource);
        }

        if (info.hasInfo) 
        {
          _setSize(params, info);
          if (info.hasImage) 
          {
            image = info.image;
          } 
          else if (info.hasDrawable) 
          {
            drawableRoot = info.drawableRoot;
          } 
          else 
          {
            repaint = false;
          }

          if (repaint) 
          {
            document?.repaint();
          }
        }
      } 
      catch (ex, stackTrace) 
      {
        appLogEx(ex, stackTrace: stackTrace);
      } 
      finally 
      {
        _loadLock = false;
      }
    }
  }

  @override
  _Image calcMetrics(PaintParameters parameters) 
  {
    final info = PictureCache().getOrCreateInfo(imgSource);
    if (info.hasInfo) 
    {
      _setSize(parameters, info);
      image = info.image;
      drawableRoot = info.drawableRoot;
    } 
    else 
    {
      _load(parameters);
    }
    return this;
  }

  _paintDrawable(Canvas canvas, double left, double top, double width, double height) 
  {
    try 
    {
      canvas.save();

      canvas.translate(left, top);
      canvas.scale(width / drawableRoot!.viewport.viewBox.width, height / drawableRoot!.viewport.viewBox.height);
      drawableRoot!.draw(canvas, Rect.zero);
    } 
    finally 
    {
      canvas.restore();
    }
  }

  @override
  void paint(PaintParameters params, double xoffset, double yoffset) 
  {
    try 
    {
      if (image != null) 
      {
        final paint = Paint()
        ..filterQuality = ui.FilterQuality.high
        ..isAntiAlias = true;

        final imageRect = Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble());

        if (count > 0) 
        {
          var x = xoffset + lineOffset;
          for (int i = 0; i < count; i++) 
          {
            params.canvas
            .drawImageRect(image!, imageRect, Rect.fromLTWH(x, yoffset + yOffset, imgWidth, height), paint);
            x += imgOffset;
          }
        } 
        else 
        {
          params.canvas.drawImageRect
          (
            image!, imageRect, Rect.fromLTWH(xoffset + xOffset, yoffset + yOffset, width, height), paint
          );
        }
      } 
      else if (drawableRoot != null) 
      {
        if (count > 0) 
        {
          var x = xoffset + lineOffset;
          for (int i = 0; i < count; i++) 
          {
            _paintDrawable(params.canvas, x, yoffset + yOffset, imgWidth, height);
            x += imgOffset;
          }
        } 
        else 
        {
          _paintDrawable(params.canvas, xoffset + xOffset, yoffset + yOffset, width, height);
        }
      } 
      else 
      {
        _load(params);
      }
    } 
    catch (ex, stackTrace) 
    {
      appLogEx(ex, stackTrace: stackTrace);
    }
  }
}

class _Line 
{
  final _words = <_Span>[];

  void add(_Span word) => _words.add(word);

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
        if (word.textBaseLine) 
        {
          asc = math.max(asc, word.baseLine);
          desc = math.max(desc, word.height - word.baseLine);
        }
      }

      final double height = asc + desc;

      for (var word in _words) 
      {
        if (word.textBaseLine) 
        {
          word.yOffset += asc - word.baseLine;
        }
      }

      span._height += height;

      _words.clear();
    }

    return span._height;
  }
}

class _Blockquotes 
{
  late Paint _paint;
  late double _left, _right, _width;
  final int _count;

  _Blockquotes(MarkdownTextConfig config, this._count) 
  {
    _paint = Paint()..color = colorFormText(config.get(['blockquotes', 'color'], defValue: 'silver'));
    _left = config.get(['blockquotes', 'paddingLeft'], defValue: 5.0);
    _right = config.get(['blockquotes', 'paddingRight'], defValue: 5.0);
    _width = config.get(['blockquotes', 'width'], defValue: 5.0);
  }

  double get intent 
  {
    return _count * (_left + _width) + _right;
  }

  void paint(Canvas canvas, double yoffset, double height) 
  {
    double x = 0.0;

    for (int i = 0; i < _count; i++) 
    {
      canvas.drawRect(Rect.fromLTWH(x + _left, yoffset, _width, height), _paint!);
      x += _left + _width;
    }
  }
}