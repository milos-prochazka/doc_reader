// ignore_for_file: constant_identifier_names

import 'dart:ui' as ui;

import '../doc_span/color_text.dart';
import '../doc_span/doc_span_interface.dart';
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

final _defaultConfig =
{
  // ••●○■ □▪▫◌○●◦ꓸ
  'bullets': ['        ●  ', '        □  ', '        ■  ', '        ●  ', '        □  ', '        ■  '],
  'blockquotes':
  {
    'color': 'silver',
    'width': 5,
    'paddingLeft': 5,
    'paddingRight': 5,
  },
  'classes':
  {
    'p':
    {
      'fontSize': 60,
      'fontStyle': 'normal', // normal, bold, bold_italic
    },
    'qaqa': {'color': 'cyan', 'borderColor': 'blue'},
    'indent':
    {
      'marginLeft': 40,
      'marginRight': 40,
      'borderPadding': 10,
      'borderColor': '#fedd',
      'borderRadius': 20,
      'fontSize': 20,
      'fontStyle': 'normal', // normal, bold, bold_italic
    },
    'h1':
    {
      'fontSize': 45,
      'fontStyle': 'italic', // normal, bold, bold_italic
      'color': 'Blue'
    },
    'h2':
    {
      'fontSize': 40,
      'fontStyle': 'bold_italic', // normal, bold, bold_italic
      'color': 'Dark Green'
    },
    'h3':
    {
      'fontSize': 35,
      'fontStyle': 'bold', // normal, bold, bold_italic
    },
    'h4':
    {
      'fontSize': 30,
      'fontStyle': 'normal', // normal, bold, bold_italic
    },
    'h5':
    {
      'fontSize': 28,
      'fontStyle': 'normal', // normal, bold, bold_italic
    },
    'h6':
    {
      'fontSize': 25,
      'fontStyle': 'bold', // normal, bold, bold_italic
      'color': '#345'
    },
  }
};

class MarkdownTextConfig
{
  dynamic config = clone(_defaultConfig);
  final _MarkdownTextConfigState _state = clone(_MarkdownTextConfigState());
  //Key? _layoutKey;

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

  bool _setInfoByStyle(_WordStyleInfo styleInfo, String className)
  {
    bool result = false;
    final cfg = get<Map<String, dynamic>?>(['classes', className]);

    if (cfg != null)
    {
      final fontSize = get<double>(['fontSize'], defValue: -1.0, config: cfg);
      if (fontSize > 0)
      {
        styleInfo.fontSize = fontSize;
        styleInfo.bulletIntent = 3 * fontSize;
      }

      styleInfo.styleStr = get<String>(['fontStyle'], defValue: styleInfo.styleStr, config: cfg);
      styleInfo.fontStyle = _fontStyleFromString(styleInfo.styleStr);
      styleInfo.fontWeight = _fontWeightFromString(styleInfo.styleStr);

      final colorStr = get<String?>(['color'], defValue: textFromColor(styleInfo.color), config: cfg);
      styleInfo.color = colorFormText(colorStr ?? 'Black');

      styleInfo.leftMargin = get<double>(['marginLeft'], defValue: styleInfo.leftMargin, config: cfg);
      styleInfo.rightMargin = get<double>(['marginRight'], defValue: styleInfo.rightMargin, config: cfg);
      styleInfo.borderPadding = get<double>(['borderPadding'], defValue: styleInfo.borderPadding, config: cfg);
      styleInfo.borderColor = colorFormText
      (
        get<String?>(['borderColor'], defValue: textFromColor(styleInfo.borderColor), config: cfg) ?? 'Silver'
      );
      styleInfo.borderRadius = get<double>(['borderRadius'], defValue: styleInfo.borderRadius, config: cfg);

      const alignCases =
      {
        'default': WordStyle.ALIGN_DEFAULT,
        'left': WordStyle.ALIGN_LEFT,
        'right': WordStyle.ALIGN_RIGHT,
        'center': WordStyle.ALIGN_CENTER,
        'justify': WordStyle.ALIGN_JUSTIFY
      };
      final alignStr = get<String?>(['align'], config: cfg);
      if (alignStr != null)
      {
        styleInfo.align = alignCases[alignStr] ?? styleInfo.align;
      }

      result = true;
    }

    return result;
  }

  WordStyle getTextStyle(MarkdownParagraph para, {MarkdownWord? word, bool bullet = false})
  {
    final linkStyle = word?.type == MarkdownWord_Type.link;
    final fullStyle = para.fullClassName(word, bullet, linkStyle);
    WordStyle? result = _state.textStyles[fullStyle];

    if (result == null)
    {
      final styleInfo = _WordStyleInfo();
      var wordStyle = false;

      if (!_setInfoByStyle(styleInfo, fullStyle))
      {
        if (!_setInfoByStyle(styleInfo, para.fullClassName(null, bullet)))
        {
          _setInfoByStyle(styleInfo, para.masterClass);
          _setInfoByStyle(styleInfo, para.subClass);
        }
        if (word != null)
        {
          if (_setInfoByStyle(styleInfo, word.style))
          {
            wordStyle = true;
          }
        }
      }
      else
      {
        wordStyle = true;
      }

      if (!wordStyle)
      {
        switch (word?.style.length)
        {
          case 1:
            styleInfo.fontStyle = FontStyle.italic;
            break;

          case 2:
            styleInfo.fontWeight = FontWeight.bold;
            break;

          case 3:
            styleInfo.fontStyle = FontStyle.italic;
            styleInfo.fontWeight = FontWeight.bold;
            break;
        }
      }

      if (bullet)
      {
        //yOffset = fontSize * 0.5;
        styleInfo.fontSize *= 0.3333;
        styleInfo.yOffset = -styleInfo.fontSize * 0.3333;
      }
      else
      {
        switch (word?.script ?? MarkdownScript.normal)
        {
          case MarkdownScript.subscript:
          case MarkdownScript.superscript:
            styleInfo.fontSize *= 0.58;
            break;

          default:
            break;
        }

        switch (word?.decoration)
        {
          case MarkdownDecoration.striketrough:
            styleInfo.textDecoration = TextDecoration.lineThrough;
            break;

          case MarkdownDecoration.underline:
            styleInfo.textDecoration = TextDecoration.underline;
            break;

          default:
            break;
        }

        if (linkStyle)
        {
          styleInfo.textDecoration = TextDecoration.underline;
        }
      }

      result = WordStyle(styleInfo);

      _state.textStyles[fullStyle] = result;
    }

    return result;
  }

  /*void _checkKey(PaintParameters params)
  {
    if (_layoutKey != params.key)
    {
      _layoutKey = params.key;
      _state = _MarkdownTextConfigState();
    }
  }*/

}

class _WordStyleInfo
{
  double fontSize = 20.0;
  String styleStr = 'normal';
  FontStyle? fontStyle;
  FontWeight? fontWeight;
  ui.TextDecoration? textDecoration;
  Color color = Colors.black;
  double yOffset = 0.0;
  double leftMargin = 0.0;
  double rightMargin = 0.0;
  double borderPadding = 0.0;
  Color borderColor = Colors.grey;
  double borderRadius = 0.0;
  int align = WordStyle.ALIGN_DEFAULT;
  double bulletIntent = 60.0;
}

class WordStyle
{
  static const ALIGN_DEFAULT = 0;
  static const ALIGN_LEFT = 1;
  static const ALIGN_RIGHT = 2;
  static const ALIGN_CENTER = 3;
  static const ALIGN_JUSTIFY = 4;

  TextStyle textStyle;
  double yOffseet;
  double leftMargin;
  double rightMargin;
  double borderPadding;
  Color borderColor;
  double borderRadius;
  int align;
  double bulletIntent;

  WordStyle(_WordStyleInfo wsInfo)
  : leftMargin = wsInfo.leftMargin,
  rightMargin = wsInfo.rightMargin,
  borderColor = wsInfo.borderColor,
  borderPadding = wsInfo.borderPadding,
  borderRadius = wsInfo.borderRadius,
  yOffseet = wsInfo.yOffset,
  align = wsInfo.align,
  bulletIntent = wsInfo.bulletIntent,
  textStyle = TextStyle
  (
    color: wsInfo.color,
    fontStyle: wsInfo.fontStyle,
    fontWeight: wsInfo.fontWeight,
    fontSize: wsInfo.fontSize,
    decoration: wsInfo.textDecoration
    //fontFamily: wsInfo.fontFamily,
  );
}

class _MarkdownTextConfigState
{
  double? bulletIntent;
  final textStyles = <String, WordStyle>{};
}