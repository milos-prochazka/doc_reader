// ignore_for_file: constant_identifier_names

import 'markdown.dart';

class LinkPattern with AllMatches implements Pattern
{
  static const GR_EXCLAMATION = 1;
  static const GR_ALT = 2;
  static const GR_URL_PART = 3;
  static const GR_URL = 4;
  static const GR_TITLE = 5;
  static const GR_VOICE = 6;
  static const GR_WIDTH = 7;
  static const GR_HEIGHT = 8;
  static const GR_ALIGN = 9;
  static const GR_CLASS = 10;
  static const GR_LINK = 11;

  /// Vyraz  typu `[text](link.lnk)` nebo `![text](link.lnk)`
  static const TYPE_LINK = 0;

  /// Vyraz typu `[![text](image.lnk)](url.lnk)`
  static const TYPE_LINKED_IMAGE = 1;

  /// Vyraz typu `[text]: link.lnk` nebo `![text]: link.lnk`
  static const TYPE_LINK_REFERENCE = 2;

  /// Nepouziva se
  static const TYPE_LINKED_IMAGE_REFERENCE = 3;

  /// Vyraz link nebo image
  /// [text](link.lnk)    gr1=  gr2=text  gr3=link.lnk
  /// ![text](link.lnk)   gr1=! gr2=text  gr3=link.lnk
  //static final _linkOrImageRegExp = RegExp(r'(\!)?\[([^\s\[\]]*)\]\(([^\)\(]+)\)', multiLine: false);
  static final _linkOrImageRegExp = RegExp(r'(\!)?\[([^\[\]]*)\]\((([^\)\(]+)|([^\)]*)\))\)', multiLine: false);

  /// Definice link nebo image
  /// [text]: link.lnk    gr1=  gr2=text  gr3=link.lnk
  /// ![text]: link.lnk   gr1=! gr2=text  gr3=link.lnk
  //static final _defineLinkOrImageRegExp = RegExp(r'^\s{0,3}(\!)?\[([^\s\[\]]*)\]\:\s+([^\)\(]+)', multiLine: false);
  static final _defineLinkOrImageRegExp = RegExp(r'^\s{0,3}(\!)?\[([^\[\]]*)\]\:\s+(.+)', multiLine: false);

  /// Vyraz linked nebo image
  /// [![text](image.lnk)](url.lnk)    gr1=[!  gr2=text  gr3=link.lnk gr4=url.lnk
  /// ![text](link.lnk)   gr1=! gr2=text  gr3=link.lnk
  static final _linkedImageRegExp = RegExp(r'(\[\!)\[([^\s\[\]]*)\]\(([^\)\(]+)\)\]\(([^\)\(]+)\)', multiLine: false);

  /// Vyraz dekodovani URL
  static final _urlRegExp = RegExp(r'''\s*([^\s\'\"]+)\s*''', multiLine: false);

  /// Dekodovani retezce:  text = gr2 ?? gr5   ,  delimiter = gr3 ?? gr6 , test ok => gr3==" gr6='
  //static final _stringRegExp = RegExp(r'''(\"([^\s\"]*)(.))\s*|(\'([^\s\']*)(.))\s*''',multiLine: false);

  /// Dekodovani parametru obrazku
  /// 10emx20em left .myclass   => gr1=10 gr3=em gr4=20 gr6=em gr7=left gr8=.myclass
  static final _imageParamsRegExp =
  RegExp(r'\s*(\-?\d+(\.\d+)?)?\s*([\w\%]*)\s*x\s*(\-?\d+(\.\d+)?)?\s*([\w*\%]*)\s*([\.\w]*)\s*([\.\w]*)?');
  final int type;

  LinkPattern(this.type);

  @override
  Match? matchAsPrefix(String string, [int start = 0])
  {
    final RegExp pattern;

    switch (type)
    {
      case TYPE_LINKED_IMAGE:
      pattern = _linkedImageRegExp;
      break;

      case TYPE_LINK_REFERENCE:
      pattern = _defineLinkOrImageRegExp;
      break;

      case TYPE_LINKED_IMAGE_REFERENCE:
      //break; -- neimplementovano

      case TYPE_LINK:
      default:
      pattern = _linkOrImageRegExp;
      break;
    }

    final pMatch = pattern.firstMatch(string.substring(start)); // pattern.matchAsPrefix(string,start) nefunguje ?
    if (pMatch != null)
    {
      // Vyraz nalezen
      final result = PatternMatch(12, string, this, pMatch.start + start, pMatch.end + start)
      .._groups[0] = pMatch[0]
      .._groups[GR_EXCLAMATION] = pMatch[1]
      .._groups[GR_ALT] = pMatch[2]
      .._groups[GR_URL_PART] = pMatch[3];

      final urlStr = pMatch[3]!.trim();

      final uMatch = _urlRegExp.firstMatch(urlStr);
      if (uMatch?.start == 0)
      {
        // Url objektu nalzeeno
        result._groups[GR_URL] = uMatch![1];

        var index = uMatch.end;

        var iBracket = urlStr.indexOf('(', index);
        if (iBracket >= 0)
        {
          index = iBracket + 1;
        }

        // Vyhledani rezecu (popis a zvukovy popis)
        final sMatch = StringPattern().allMatches(urlStr, index).toList(growable: false);

        for (var c = 0; c < 2; c++)
        {
          if (c < sMatch.length)
          {
            result._groups[GR_TITLE + c] = sMatch[c][1];
            index = sMatch[c].end;
          }
        }

        final iMatch = _imageParamsRegExp.matchAsPrefix(urlStr, index);
        if (iMatch != null)
        {
          // Nalezena definice parametru obrazku
          if (iMatch[1] != null)
          {
            result._groups[GR_WIDTH] = iMatch[1]! + (iMatch[3] ?? '');
          }
          if (iMatch[4] != null)
          {
            result._groups[GR_HEIGHT] = iMatch[4]! + (iMatch[6] ?? '');
          }

          for (final m in <String?>[iMatch[7], iMatch[8]])
          {
            // trida a zarovnani
            if (m != null && m.isNotEmpty)
            {
              if (m.startsWith('.'))
              {
                result._groups[GR_CLASS] = m.substring(1);
              }
              else
              {
                result._groups[GR_ALIGN] = m;
              }
            }
          }
        }

        result._groups[GR_LINK] = (pMatch.groupCount >= 4) ? pMatch[4] : uMatch[1];

        for (int i = 0; i < result._groups.length; i++)
        {
          final t = result._groups[i];
          if (t != null)
          {
            result._groups[i] = MarkdownParagraph.unescape(t);
          }
        }

        return result;
      }
    }

    return null;
  }
}

extension SafeString on String
{
  int safeCodeUnitAt(int index, [int defValue = -1])
  {
    return (index >= 0 && index < length) ? codeUnitAt(index) : 0;
  }
}

class StringPattern with AllMatches implements Pattern
{
  static final StringPattern _instance = StringPattern._();

  StringPattern._();

  factory StringPattern()
  {
    return _instance;
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0])
  {
    while (start < string.length && ' \t\v\u00a0'.contains(string[start]))
    {
      start++;
    }

    var ch = string.safeCodeUnitAt(start);
    if (ch == /*$'*/(0x27) || ch == /*$"*/(0x22))
    {
      var index = start + 1;

      while (index < string.length && string.codeUnitAt(index) != ch)
      {
        index++;
      }

      if (index < string.length)
      {
        return PatternMatch(2, string, this, start, index + 1)
        .._groups[0] = string.substring(start, index + 1)
        .._groups[1] = string.substring(start + 1, index);
      }
    }

    return null;
  }
}

abstract class AllMatches
{
  Iterable<Match> allMatches(String string, [int start = 0])
  {
    final result = <Match>[];

    Match? match;

    while ((match = matchAsPrefix(string, start)) != null)
    {
      result.add(match!);
      start = match.end;
    }

    return result;
  }

  Match? firstMatch(String input) => matchAsPrefix(input);

  Match? matchAsPrefix(String string, [int start = 0]);
  /*{
    throw UnimplementedError();
  }*/
}

class PatternMatch implements Match
{
  final List<String?> _groups;
  final Pattern _pattern;
  final String _input;
  final int _start;
  final int _end;

  PatternMatch(int groupCount, this._input, this._pattern, this._start, this._end)
  : _groups = List<String?>.filled(groupCount, null, growable: false);

  @override
  String? operator [](int group) => _groups[group];

  @override
  int get end => _end;

  @override
  String? group(int group) => _groups[group];

  @override
  int get groupCount => _groups.length;

  @override
  List<String?> groups(List<int> groupIndices) => _groups;

  @override
  String get input => _input;

  @override
  Pattern get pattern => _pattern;

  @override
  int get start => _start;
}