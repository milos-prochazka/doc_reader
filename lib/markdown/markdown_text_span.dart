// ignore_for_file: constant_identifier_names, unnecessary_this

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import '../objects/json_utils.dart';

import '../doc_span/document_word.dart';

import '../doc_span/paint_parameters.dart';

import '../doc_span/color_text.dart';
import '../doc_span/doc_span_interface.dart';
import 'markdown_text_config.dart';
import 'value_unit.dart';
import '../objects/applog.dart';
import '../objects/picture_cache.dart';
import '../objects/text_load_provider.dart';
import '../objects/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../document.dart';
import 'markdown.dart';
import 'package:path/path.dart' as path;
import 'dart:math' as math;

final _decimalNumberRegEx = RegExp(r'(\-?\d+(\.\d+)?)', multiLine: false);

/// Jeden odstavec markdown
class MarkdownTextSpan implements IDocumentSpan
{
  Key? _layoutKey;
  final MarkdownParagraph paragraph;
  final MarkdownTextConfig config;
  final _spans = <_Span>[];
  double _width = 0;
  double _height = 0;
  final _linePositions = <double>[];
  final Document document;
  _Blockquotes? _blockquotes;

  MarkdownTextSpan(this.paragraph, this.config, this.document);

  int get id => paragraph.id;

  static List<MarkdownTextSpan> create(Markdown markdown, MarkdownTextConfig config, Document document)
  {
    final result = <MarkdownTextSpan>[];

    if (markdown.classes.isNotEmpty)
    {
      final classes = config.get<Map<String, dynamic>?>(['classes']);

      if (classes != null)
      {
        for (var markdownClass in markdown.classes.entries)
        {
          var cls = classes[markdownClass.key];
          if (cls != null)
          {
            for (final item in markdownClass.value.entries)
            {
              cls[item.key] = clone(item.value);
            }
          }
          else
          {
            cls = clone(markdownClass.value);
            classes[markdownClass.key] = cls;
          }
        }
      }
    }

    document.documentContent = markdown.getContent();

    for (final para in markdown.paragraphs)
    {
      result.add(MarkdownTextSpan(para, config, document));
    }

    return result;
  }

  void _updateText(PaintParameters parameters)
  {
    _spans.clear();
    _height = 0;
    _width = 0;
    _linePositions.clear();

    appLog_debug('_updateText:\n$paragraph\n');

    final paraStyle = config.getTextStyle(paragraph);
    final line = _Line(paraStyle);

    double left = paraStyle.leftMargin;
    double right = parameters.size.width - paraStyle.rightMargin;
    if ((right - left) < 0.6 * parameters.size.width)
    {
      left = 0.2 * parameters.size.width;
      right = 0.8 * parameters.size.width;
    }

    final borderPadding = paraStyle.borderPadding;
    final borderLeft = left;
    final borderRight = right;

    if (borderPadding > 0)
    {
      left += borderPadding;
      right -= borderPadding;
    }

    double y = paragraph.firstInClass ? math.max(borderPadding, paraStyle.spaceBefore) : 0;

    if (_Hr.hrStyle(paragraph.masterClass))
    {
      final hr = _Hr(paragraph.masterClass, right).calcMetrics(parameters);
      y += hr.height;
      _spans.add(hr);
    }

    _height = y;

    // Odsazeni a decorace zleva
    if (paragraph.isNotEmpty && paragraph.listIndent != null)
    {
      final dec = paragraph.listIndent!;
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

        default:
        bullet = true;
        text = config.get(['bullets', dec.level], defValue: '  -');
        break;
      }

      if (paragraph.blockquoteLevel > 0)
      {
        _blockquotes ??= _Blockquotes(config, paragraph.blockquoteLevel);
        left += _blockquotes?.intent ?? 0;
      }

      final style = config.getTextStyle(paragraph, word: paragraph[0], bullet: bullet);
      final span = _Text(text, null, style.textStyle, false).calcMetrics(parameters);
      span.yOffset = style.yOffseet;
      span.xOffset = left + dec.level * paraStyle.bulletIntent;

      _spans.add(span);
      line.add(span);
      left = span.width + span.xOffset;
    }

    // Vytvoreni seznamu spanu k zalomeni ----------------------------------------------------------------------------
    final prepSpans = <_Span>{};
    final leftSpans = <_Span>{};
    final rightSpans = <_Span>{};

    for (final word in paragraph.words)
    {
      //const style = TextStyle(color: Color.fromARGB(255, 0, 0, 160), fontSize: 20.0, fontFamily: 'Times New Roman', fontWeight: FontWeight.bold);
      final style = config.getTextStyle(paragraph, word: word);
      _Span? span;

      switch (word.type)
      {
        case MarkdownWord_Type.image:
        span = _Image(config, word.attribs, document, style.textStyle, word.stickToNext, left, right)
        .calcMetrics(parameters);
        break;

        case MarkdownWord_Type.word:
        case MarkdownWord_Type.link:
        span = _Text(word.text, word.ttsPhonetic, style.textStyle, word.stickToNext).calcMetrics(parameters)
        ..ttsBehavior = word.ttsBehavior;
        break;

        case MarkdownWord_Type.speech_only:
        case MarkdownWord_Type.speech_pause:
        span = _SpeechOnly(word.text, style.textStyle, word.stickToNext)..ttsBehavior = word.ttsBehavior;
        break;
      }

      if (span != null)
      {
        span.lineBreak = word.lineBreak;
        span.script = word.script;
        span.ttsBehavior = word.ttsBehavior;
        _spans.add(span);

        if (span.visible)
        {
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
      }
    }

    // Zalomeni textu -----------------------------------------------------------------------------------------------
    double rightHeight = y;
    double sizeWidth = right;

    for (final span in rightSpans)
    {
      span.xOffset = right - span.width;
      sizeWidth = math.min(span.xOffset, sizeWidth);
      span.yOffset = rightHeight;
      rightHeight = math.max(rightHeight, span.yOffset + span.height);
    }

    double leftLeft = left;
    double leftHeight = y;

    for (final span in leftSpans)
    {
      span.xOffset = left;
      leftLeft = math.max(leftLeft, left + span.width);
      span.yOffset = leftHeight;
      leftHeight += span.height;
    }

    double x = leftLeft;
    double lineLeft = x;
    double lineWidth = sizeWidth;

    // inline spany
    for (final span in prepSpans)
    {
      final spanWidth = span.width;
      lineWidth = y > rightHeight ? right : sizeWidth;
      var wordSpace = span.wordSpace;

      if (span.lineBreak)
      {
        // Novy radek
        if (line._words.isEmpty)
        {
          _height += span.height;
          y = _height;
        }
        else
        {
          y = line.calcPosition(this, parameters, lineLeft, lineWidth, false);
        }

        x = y > leftHeight ? left : leftLeft;
        lineLeft = x;
      }
      else
      {
        // Normalni text
        if ((x + spanWidth) > lineWidth)
        {
          y = line.calcPosition(this, parameters, lineLeft, lineWidth, false);
          x = y > leftHeight ? left : leftLeft;
          lineLeft = x;
        }

        span.xOffset = x;
        span.yOffset = y;
        line.add(span);
        x += spanWidth + wordSpace;
      }
    }

    line.calcPosition(this, parameters, lineLeft, lineWidth, true);
    _width = parameters.size.width;

    _height = math.max(leftHeight, math.max(_height, rightHeight));

    if (paraStyle.paragraphUnderline > 0)
    {
      final hr = _Hr.fromHeight(paraStyle.paragraphUnderline, lineWidth);
      hr.xOffset = leftLeft;
      hr.yOffset = _height;
      _height += hr.height;
      this._spans.add(hr);
    }

    if (borderPadding > 0.0)
    {
      var topRadius = 0.0, bottomRadius = 0.0;

      if (paragraph.lastInClass)
      {
        _height += borderPadding;
        bottomRadius = paraStyle.borderRadius;
      }
      if (paragraph.firstInClass)
      {
        topRadius = paraStyle.borderRadius;
      }
      final tr = ui.Radius.circular(topRadius);
      final br = ui.Radius.circular(bottomRadius);

      _height = _height.ceilToDouble();
      final rect = ui.RRect.fromLTRBAndCorners(borderLeft, 0, borderRight, _height,
        topLeft: tr, topRight: tr, bottomLeft: br, bottomRight: br);
      final box = _Box(paraStyle.borderColor, rect);
      _spans.insert(0, box);
    }

    if (paragraph.lastInClass)
    {
      _height += math.max(paraStyle.spaceAfter, borderPadding);
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
      if (word.visible)
      {
        word.paint(params, xOffset, yOffset);
      }
    }
  }

  @override
  double width(PaintParameters params)
  {
    calcSize(params);
    return _width;
  }

  @override
  double correctYPosition(double yPosition, bool alignTop)
  {
    int i = 0;
    int max = _linePositions.length - 1;

    while ((i < max) && ((_linePositions[i + 1] + 1e-3) < yPosition))
    {
      i++;
    }

    if (i < _linePositions.length)
    {
      if (alignTop)
      {
        return _linePositions[i] - yPosition;
      }
      else
      {
        if ((_linePositions[i] + 1e-3) > yPosition)
        {
          return 0.0;
        }
        else
        {
          final h = ((i + 1) < _linePositions.length) ? _linePositions[i + 1] : _height;
          return h - yPosition;
        }
      }
    }
    else
    {
      return 0.0;
    }
  }

  static Future<bool> fileOpen(String name, Document document, config) async
  {
    bool result = false;

    document.imagePath = path.dirname(name);

    final text = await Markdown.loadText(name, config as TextLoadProvider);
    final markdown = Markdown();
    markdown.writeMarkdownString(text);

    final textConfig = document.config as MarkdownTextConfig;
    print('#############################\r\n${markdown.toString()}\r\n#####################');

    // TODO Test smazat
//#if 1
    final json = markdown.toJson(true);
    final s = jsonEncode(json);
    //final directory = await getApplicationDocumentsDirectory();
    final File file = File('my_file.json');
    final p = file.absolute;
    await file.writeAsString(s);

    final bfile = File('my_file.cbj');
    final b = DBJ.encode(json);
    await bfile.writeAsBytes(b);

    final File file1 = File('my_file1.json');
    final js1 = jsonEncode(DBJ.decode(b));
    await file1.writeAsString(js1);

    final md1 = Markdown.fromJson(jsonDecode(js1));
    final File file2 = File('my_file2.json');
    final js2 = jsonEncode(md1.toJson(true));
    await file2.writeAsString(js2);
//#end if line:432
    //////////////////////////////////////////

    final ms = MarkdownTextSpan.create(markdown, textConfig, document);

    document.docSpans.clear();
    for (final s in ms)
    {
      document.docSpans.add(DocumentSpanContainer(s));
    }

    document.reload();

    result = true;

    return result;
  }

  @override
  void getSpanWords(List<DocumentWordInfo> words, PaintParameters parameters, int id, bool speech)
  {
    _updateSize(parameters);
    for (final span in this._spans)
    {
      if (span is _Text)
      {
        if (!speech || span.ttsBehavior != DocumentWordInfo.TTS_IGNORE)
        {
          final info = DocumentWordInfo()..id = id;
          info.rect = Rect.fromLTWH(span.xOffset, span.yOffset, span.width, span.height);
          info.ttsBehavior = span.ttsBehavior;
          info.text = speech ? (span.ttsPhonetic ?? span.text) : (span.text);
          print('Speech word ${info.text} ${info.rect.toString()}');
          words.add(info);
        }
      }
    }
  }
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
  MarkdownScript script = MarkdownScript.normal;
  int align = _Span.ALIGN_INLINE;
  int ttsBehavior = DocumentWordInfo.TTS_SPEECH;

  bool get textBaseLine => false;

  bool get visible => true;

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
  String? ttsPhonetic;
  final TextStyle style;
  final bool stickToNext;

  _Text(this.text, this.ttsPhonetic, this.style, this.stickToNext);

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
        wordSpace = stickToNext ? 0 : (style.wordSpacing ?? p.height / 3);

        baseLine = metrics.ascent;
        height = metrics.height;
        width = p.size.width; // Mereni s mezerami
        //width = metrics.width; // Mereni bez mezer
        left = metrics.left;
      }
      else
      {
        height = style.fontSize ?? 0.0;
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

class _SpeechOnly extends _Text
{
  _SpeechOnly(String text, TextStyle style, bool stickToNext) : super(text, text, style, stickToNext);

  @override
  TextPainter get painter => throw Exception('Unimplemented');

  @override
  bool get visible => false;
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

  _Hr.fromHeight(double height, double width) : this.style = '---'
  {
    this.height = 2 * height;
    this.width = width;
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

    double y = yoffset + this.yOffset + height * 0.25;

    params.canvas.drawLine(Offset(xoffset + left, y), Offset(xoffset + width - 2 * left, y), paint);
  }
}

class _Box extends _Span
{
  Paint boxPaint;
  ui.RRect rect;

  _Box(Color color, this.rect) : boxPaint = Paint()..color = color;

  @override
  _Box calcMetrics(PaintParameters parameters)
  {
    return this;
  }

  @override
  void paint(PaintParameters params, double xoffset, double yoffset)
  {
    params.canvas.drawRRect(rect.shift(Offset(xoffset, yoffset)), boxPaint);
  }
}

class _Image extends _Span
{
  late Map<String, dynamic> attribs;
  final TextStyle style;
  final bool stickToNext;
  final double maxWidth;
  final double paraLeft;
  double imgWidth = double.nan;
  double imgOffset = double.nan;
  double lineOffset = 0;
  double _devicePixelRatio = 2.0;
  ui.Image? _image;
  DrawableRoot? _drawableRoot;
  int count = 0;
  Color? color;
  ColorFilter? colorFilter;

  Document? document;

  _Image(MarkdownTextConfig config, Map<String, String?> attr, this.document, this.style, this.stickToNext,
    this.paraLeft, paraRight)
  : maxWidth = paraRight - paraLeft
  {
    final clsName = attr['class'];

    if (clsName != null)
    {
      this.attribs = clone(attr);
      final clsData = config.get<Map<String, dynamic>?>(['classes', clsName]);

      clsData?.forEach
      (
        (key, value)
        {
          this.attribs[key] = value;
        }
      );
    }
    else
    {
      this.attribs = attr;
    }

    final colorStr = this.attribs['color'];
    if (colorStr != null)
    {
      color = colorFormText(colorStr);
    }

    const stdColorFilter = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
    const alphaFilter = <double>
    [
      0, 0, 0, 0, 0, //
      0, 0, 0, 0, 0, //
      0, 0, 0, 0, 0, //
      0, 0, 0, 1, 0
    ];
    const sepiaFilter = <double>
    [
      //
      0.393, 0.769, 0.189, 0, 0, //
      0.349, 0.686, 0.168, 0, 0, //
      0.272, 0.534, 0.131, 0, 0, //
      0, 0, 0, 1, 0 //
    ];

    double _factor(List<String> params) => (params.length >= 2) ? ((ValueUnit(params[1]).value ?? 100) * 0.01) : 1;

    List<double> interleawe(double factor, List<double> src, List<double> dst)
    {
      if (factor <= 0)
      {
        return src;
      }
      else if (factor >= 1)
      {
        return dst;
      }
      else
      {
        final result = <double>[];
        final count = math.min(src.length, dst.length);

        for (int i = 0; i < count; i++)
        {
          result.add(dst[i] * factor + src[i] * (1 - factor));
        }
        return result;
      }
    }

    final colorFilter = this.attribs['colorfilter'];

    if (colorFilter != null)
    {
      final params = colorFilter.toString().split(' ');

      if (params.isNotEmpty)
      {
        switch (params[0].toLowerCase())
        {
          case 'sepia':
          {
            this.colorFilter = ui.ColorFilter.matrix(interleawe(_factor(params), stdColorFilter, sepiaFilter));
          }
          break;

          case 'alpha':
          {
            final color = this.color ?? Colors.black;
            final filter = <double>[...alphaFilter];

            filter[4] = color.red.toDouble();
            filter[9] = color.green.toDouble();
            filter[14] = color.blue.toDouble();

            this.colorFilter = ui.ColorFilter.matrix(interleawe(_factor(params), stdColorFilter, filter));
          }
          break;

          case 'monochrome':
          {
            final color = this.color ?? Colors.white;
            const cr = 0.2125 * 0.00392157;
            const cg = 0.7154 * 0.00392157;
            const cb = 0.0721 * 0.00392157;

            this.colorFilter = ui.ColorFilter.matrix
            (
              interleawe
              (
                _factor(params), stdColorFilter, <double>
                [
                  // red
                  color.red * cr,
                  color.red * cg,
                  color.red * cb,
                  0,
                  0,
                  // green
                  color.green * cr,
                  color.green * cg,
                  color.green * cb,
                  0,
                  0,
                  // blue
                  color.blue * cr,
                  color.blue * cg,
                  color.blue * cb,
                  0,
                  0,
                  // alpha
                  0,
                  0,
                  0,
                  1,
                  0
                ]
              )
            );
          }
          break;

          default:
          {
            final matches = _decimalNumberRegEx.allMatches(colorFilter).toList();

            if (matches.isNotEmpty)
            {
              final array = <double>[];

              for (int i = 0; i < 20; i++)
              {
                final s = i < matches.length ? matches[i].group(1) ?? '0' : '0';
                array.add(double.tryParse(s) ?? 0);
              }

              this.colorFilter = ui.ColorFilter.matrix(array);
            }
          }
          break;
        }
      }
    }
  }

  double get _fontSize => style.fontSize ?? 20;

  @override
  bool get textBaseLine => baseLine > 0;

  String get imgSource => path.join(document?.imagePath ?? '', attribs['image'] as String);

  /*double? _decodeSize(double? value, String? unit, double screenSize)
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
  }*/

  int get imagePixelWidth => (imgWidth * _devicePixelRatio).round();

  int get imagePixelHeight => (height * _devicePixelRatio).round();

  Future<ui.Image?> _createImage(PictureCacheInfo info) async
  {
    ui.Image? result;

    if (info.hasDrawable)
    {
      _drawableRoot = info.drawableRoot;

      result = await info.makeSizedImage(imagePixelWidth, imagePixelHeight);
    }

    return result;
  }

  ui.Image? _getImage(PictureCacheInfo info) => info.getSizedImage(imagePixelWidth, imagePixelHeight);

  _setSize(PaintParameters params, PictureCacheInfo info)
  {
    print('_setSize()');

    _devicePixelRatio = params.devicePixelRatio;

    double width = info.width;
    double height = info.height;
    double aspectRatio = width / height;

    double? reqWidth = ValueUnit(attribs['width']).toDip(_fontSize, maxWidth);
    // TODO neni u reqHeight spatne maxWidth?
    double? reqHeight = ValueUnit(attribs['height']).toDip(_fontSize, maxWidth);

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

    if (maxWidth < width)
    {
      width = maxWidth;
      height = width / aspectRatio;
    }

    imgWidth = width;

    final attr = attribs['align'];
    switch (attr)
    {
      case 'tight-line':
      {
        count = (maxWidth + width) ~/ width;
        imgWidth = maxWidth / count;
        height = imgWidth / aspectRatio;
        imgOffset = imgWidth;
        width = maxWidth;
      }
      break;

      case 'tight-center-line':
      {
        imgWidth = width;
        imgOffset = width;
        count = (maxWidth) ~/ width;
        width = maxWidth;
        lineOffset = 0.5 * (width - count * imgWidth);
      }
      break;

      case 'line':
      case 'center-line':
      {
        count = maxWidth ~/ width;
        imgWidth = width;
        width = maxWidth;

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
        count = maxWidth ~/ width;
        imgWidth = maxWidth / count;
        imgOffset = imgWidth;
        if (reqHeight == null)
        {
          height = imgWidth / aspectRatio;
        }
        width = maxWidth;
      }
      break;

      case 'center':
      {
        count = 1;
        lineOffset = 0.5 * (maxWidth - width);
        imgWidth = width;
        width = maxWidth;
      }
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
    if (!_loadLock)
    {
      print('_load()');
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
            _image = info.image;
          }
          else if (info.hasDrawable)
          {
            _drawableRoot = info.drawableRoot;

            final img = await _createImage(info);
            if (img != null)
            {
              _image = info.image;
            }
            else
            {
              repaint = false;
            }
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
      _drawableRoot = info.drawableRoot;
      if (_drawableRoot == null)
      {
        _image = info.image;
      }
      else
      {
        _image = _getImage(info);
      }
    }
    else
    {
      _load(parameters);
    }
    return this;
  }

  // ignore: unused_element
  _paintDrawable(Canvas canvas, double left, double top, double width, double height)
  {
    // TODO perspektivne zrusit -> tiskne se pomoci prevodu na image
    try
    {
      canvas.save();

      canvas.translate(left, top);
      canvas.scale(width / _drawableRoot!.viewport.viewBox.width, height / _drawableRoot!.viewport.viewBox.height);
      _drawableRoot!.draw(canvas, Rect.zero);
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
      if (_image != null)
      {
        final paint = Paint()
        ..filterQuality = ui.FilterQuality.high
        ..isAntiAlias = true
        ..colorFilter = colorFilter;

        final imageRect = Rect.fromLTWH(0, 0, _image!.width.toDouble(), _image!.height.toDouble());

        if (count > 0)
        {
          var x = xoffset + paraLeft + lineOffset;
          for (int i = 0; i < count; i++)
          {
            params.canvas
            .drawImageRect(_image!, imageRect, Rect.fromLTWH(x, yoffset + yOffset, imgWidth, height), paint);
            x += imgOffset;
          }
        }
        else
        {
          params.canvas.drawImageRect
          (
            _image!, imageRect, Rect.fromLTWH(xoffset + xOffset, yoffset + yOffset, width, height), paint
          );
        }
      }
      /*else if (_drawableRoot != null)
      { // TODO perspektivne zrusit -> tiskne se pomoci prevodu na image
        if (count > 0)
        {
          var x = xoffset + paraLeft + lineOffset;
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
      }*/
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
  final int align;

  void add(_Span word) => _words.add(word);

  _Line(final WordStyle paraStyle) : align = paraStyle.align;

  double calcPosition(MarkdownTextSpan span, PaintParameters parameters, double left, double right, bool lastLine)
  {
    if (_words.isNotEmpty)
    {
      //double y = 0;
      double asc = 0;
      double desc = 0;
      double linePositon = double.maxFinite;

      for (final word in _words)
      {
        //y = math.max(y,word.yOffset);
        if (word.textBaseLine)
        {
          asc = math.max(asc, word.baseLine);
          desc = math.max(desc, word.height - word.baseLine);
        }

        linePositon = math.min(linePositon, word.yOffset);
      }

      if (linePositon < double.maxFinite)
      {
        span._linePositions.add(linePositon);
      }

      final double height = asc + desc;

      for (var word in _words)
      {
        //print('word:${(word as _Text).text}');
        if (word.textBaseLine)
        {
          switch (word.script)
          {
            //
            case MarkdownScript.superscript:
            // word.yOffset = word.yOffset;
            break;
            //
            case MarkdownScript.subscript:
            word.yOffset += height - word.height;
            break;
            //
            default:
            word.yOffset += asc - word.baseLine;
            break;
          }
        }
      }

      if (_words.isNotEmpty)
      {
        final textRight = _words.last.xOffset + _words.last.width;
        switch (align)
        {
          case WordStyle.ALIGN_RIGHT:
          {
            final offset = right - textRight;
            for (final word in _words)
            {
              word.xOffset += offset;
            }
          }
          break;

          case WordStyle.ALIGN_CENTER:
          {
            final offset = 0.5 * (right - textRight);
            for (final word in _words)
            {
              word.xOffset += offset;
            }
          }
          break;

          case WordStyle.ALIGN_JUSTIFY:
          {
            if (_words.length >= 4 && !lastLine && (textRight - left) > 0.75 * (right - left))
            {
              final step = (right - textRight) / (_words.length - 1);
              var offset = 0.0;
              for (final word in _words)
              {
                word.xOffset += offset;
                offset += step;
              }
            }
          }
          break;
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
  final Paint _paint;
  final double _left, _right, _width;
  final int _count;

  _Blockquotes(MarkdownTextConfig config, this._count)
  : _paint = Paint()..color = colorFormText(config.get(['blockquotes', 'color'], defValue: 'silver')),
  _left = config.get(['blockquotes', 'paddingLeft'], defValue: 5.0),
  _right = config.get(['blockquotes', 'paddingRight'], defValue: 5.0),
  _width = config.get(['blockquotes', 'width'], defValue: 5.0);

  double get intent
  {
    return _count * (_left + _width) + _right;
  }

  void paint(Canvas canvas, double yoffset, double height)
  {
    double x = 0.0;

    for (int i = 0; i < _count; i++)
    {
      canvas.drawRect(Rect.fromLTWH(x + _left, yoffset, _width, height), _paint);
      x += _left + _width;
    }
  }
}