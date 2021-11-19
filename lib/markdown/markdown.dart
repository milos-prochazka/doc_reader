// ignore_for_file: constant_identifier_names

import 'package:doc_reader/objects/applog.dart';
import 'package:tuple/tuple.dart';

/// Deleni textu na radky
final _newLineRegex = RegExp(r'([\r\n])|(\r\n)]', multiLine: true);

/// Detekce nadpisu a odsazeni
final _headRegExp = RegExp(r'\s*((\>\s*)|([\-\+\*]\s+)|(\#{1,6}\s+)|(\d+\.\s)|([A-Za-z]\.\s))', multiLine: false);

/// Trida znaku (italic,bold a dalsi)
final _charClassRegExp = RegExp(r'((\_{1,3})|(\*{1,3}))|(\`{3}(@\w+\s))', multiLine: false);

/// Pojmenovany link
final _namedLinkRegExp = RegExp(r'!?(\[.*\])(\(.+\))', multiLine: false);

/// Url link: http://www.any.org nebo <http://www.any.org>
final _urlRegExp = RegExp(r'\<?[a-zA-Z0-9]{2,32}:\/\/[a-zA-Z0-9@:%\._\\+~#?&\/=\u00A0-\uD7FF\uE000-\uE080]{2,256}\>?',
  multiLine: false);

/// Email link: aaaa@dddd.org nebo <aaaa@dddd.org>
final _emailRegExp = RegExp
(
  r'\<?[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9\u00A0-\uD7FF\uE000-\uE080)]+(?:\.[a-zA-Z0-9-]+)*\>?',
  multiLine: false
);

/// Horizntalni cara --- , === , ___ , ***
final _hrRegExp = RegExp(r'^\s*(([\*]{3,})|([\-]{3,})|([\_]{3,})|([\=]{3,}))\s*$', multiLine: false);

/// Radek s formatem [aaa]: http://wwww.seznam.cz
final _refLinkLinkRegExp = RegExp(r'^\s{0,3}(\[.+\])\:\s+(\S+)$', multiLine: false);

/// Vyhledani escape eskvenci ve vstupnim textu
final _escapeCharRegExp = RegExp(r'\\[\\\`\*\_\{\}\[\]\(\)\#\+\-\.\!\|\s]', multiLine: false);

/// Vyhledani escapovanych znaku
final _escapedCharRegExp = RegExp(r'[\uE000-\uE0FF]', multiLine: false);

/// Escapovane znaky:
/// \ E0C0
/// ` E060
/// * E02A
/// _ E05F
/// { E07B
/// } E07D
/// [ E05B
/// ] E05D
/// ( E028
/// ) E029
/// # E023
/// + E02B
/// - E02D
/// . E02E
/// ! E021
/// | E07C

class Markdown
{
  final paragraphs = <MarkdownParagraph>[];

  writeMarkdownString(String text)
  {
    final lines = MarkdownParagraph.escape(text).split(_newLineRegex);

    for (int i = 0; i < lines.length; i++)
    {
      String line = lines[i];

      appLog_debug('line:"$line"');

      if (_refLinkLinkRegExp.hasMatch(line))
      {
        final match = _refLinkLinkRegExp.firstMatch(line)!;
        if (match.groupCount >= 2)
        {
          final name = MarkdownParagraph.centerSubstring(match.group(1) ?? '', 1, 1);
          final link = (match.group(2) ?? '').trim();
          var brk = 1;
        }
      }
      else if (_hrRegExp.hasMatch(line))
      {
        final ch = line.trim()[0];
        switch (ch)
        {
          case '=':
          case '-':
          if (paragraphs.isNotEmpty && paragraphs.last.words.isNotEmpty)
          {
            paragraphs.last.headClass = ch == '=' ? 'h1' : 'h2';
          }
          else
          {
            paragraphs.add(MarkdownParagraph(text: '', headClass: ''.padLeft(3, ch)));
          }
          break;

          default:
          paragraphs.add(MarkdownParagraph(text: '', headClass: ''.padLeft(3, ch)));
          break;
        }
      }
      else
      {
        var pStart = '';
        var hClass = '';

        int headEnd = 0;
        Match? head;
        do
        {
          head = _headRegExp.matchAsPrefix(line, headEnd);

          if (head != null && head.start == headEnd)
          {
            final t = head.input.substring(head.start, head.end).trim();

            if (t.startsWith('#'))
            {
              hClass = 'h${t.length}';
              pStart = line.substring(0, headEnd);
              headEnd = head.end;
              head = null;
            }
            else
            {
              headEnd = head.end;
            }
          }
          else
          {
            pStart = line.substring(0, headEnd);
          }
        }
        while (head != null);

        line = line.substring(headEnd);
        appLog_debug('[$pStart] [$hClass] "$line"');

        paragraphs.add(MarkdownParagraph(text: line, lineDecoration: pStart, headClass: hClass));
      }
    }

    _doProcess();
  }

  void _doProcess()
  {
    // Slouceni odstavcu
    for (int i = 1; i < paragraphs.length;)
    {
      final para = paragraphs[i];
      final prevPara = paragraphs[i - 1];

      if
      (
        para.lineDecoration.isEmpty &&
        para.headClass.isEmpty &&
        para.words.isNotEmpty &&
        prevPara.words.isNotEmpty &&
        prevPara.headClass.isEmpty
      )
      {
        prevPara.copyWords(para);
        paragraphs.removeAt(i);
      }
      else
      {
        i++;
      }
    }

    // Vypusteni prazdnych odstavcu
    for (int i = 0; i < paragraphs.length;)
    {
      final para = paragraphs[i];

      if (para.lineDecoration.isEmpty && para.words.isEmpty && para.headClass.isEmpty)
      {
        paragraphs.removeAt(i);
      }
      else
      {
        para.decorations = MarkdownDecoration.textToList(para.lineDecoration);
        i++;
      }
    }

    MarkdownDecoration.modify(paragraphs);
  }

  @override
  String toString()
  {
    final builder = StringBuffer('Markdown: ${paragraphs.length} paragraphs\r\n');

    for (int i = 0; i < paragraphs.length; i++)
    {
      final para = paragraphs[i].toString();
      builder.write('[$i] $para');
    }
    return builder.toString();
  }
}

class MarkdownParagraph
{
  String lineDecoration;
  List<MarkdownDecoration>? decorations;
  String headClass;
  final words = <MarkdownWord>[];

  MarkdownParagraph({required String text, this.lineDecoration = '', this.headClass = ''})
  {
    writeText(text);
  }

  static String escape(String text)
  {
    if (!_escapeCharRegExp.hasMatch(text))
    {
      return text;
    }
    else
    {
      var index = 0;
      final builder = StringBuffer();

      final matches = _escapeCharRegExp.allMatches(text);

      for (final match in matches)
      {
        if (match.start > index)
        {
          builder.write(text.substring(index, match.start));
        }

        builder.writeCharCode(0xE000 + text.codeUnitAt(match.start + 1));
        index = match.end;
      }

      if (text.length > index)
      {
        builder.write(text.substring(index));
      }

      return builder.toString();
    }
  }

  static String unescape(String text)
  {
    if (!_escapedCharRegExp.hasMatch(text))
    {
      return text;
    }
    else
    {
      var index = 0;
      final builder = StringBuffer();

      final matches = _escapedCharRegExp.allMatches(text);

      for (final match in matches)
      {
        if (match.start > index)
        {
          builder.write(text.substring(index, match.start));
        }

        builder.writeCharCode(text.codeUnitAt(match.start) & 0x00FF);
        index = match.end;
      }

      if (text.length > index)
      {
        builder.write(text.substring(index));
      }

      return builder.toString();
    }
  }

  @override
  String toString()
  {
    final builder = StringBuffer("Paragraph: start='$lineDecoration' headClass='$headClass'\r\n");

    if (decorations != null && decorations!.isNotEmpty)
    {
      builder.write('Decorations:\r\n');
      for (final dec in decorations!)
      {
        builder.write('${dec.toString()}\r\n');
      }
      if (words.isNotEmpty)
      {
        builder.write('Words:\r\n');
      }
    }

    for (int i = 0; i < words.length; i++)
    {
      final word = words[i].toString();
      builder.write('  $i: $word\r\n');
    }
    return builder.toString();
  }

  MarkdownWord makeWord(String text, List<String> styleStack,
    {MarkdownWord_Type type = MarkdownWord_Type.word, bool stickToNext = false, String? link, String? image})
  {
    final result = MarkdownWord()
    ..type = type
    ..text = MarkdownParagraph.unescape(text)
    ..style = styleStack.isEmpty ? '' : styleStack.last
    ..stickToNext = stickToNext;

    if (link != null)
    {
      result.link = MarkdownParagraph.unescape(link);
    }

    if (image != null)
    {
      result.image = MarkdownParagraph.unescape(image);
    }

    return result;
  }

  void writeWord(StringBuffer wordBuffer, List<String> styleStack, bool stickToNext)
  {
    if (wordBuffer.isNotEmpty)
    {
      words.add
      (
        MarkdownWord()
        ..text = MarkdownParagraph.unescape(wordBuffer.toString())
        ..style = styleStack.isEmpty ? '' : styleStack.last
        ..stickToNext = stickToNext
      );
      wordBuffer.clear();
    }
  }

  static String centerSubstring(String text, int prefix, int postfix)
  {
    if ((prefix + postfix) >= text.length)
    {
      return '';
    }
    else
    {
      return text.substring(prefix, text.length - postfix);
    }
  }

  writeText(String text)
  {
    const MATCH_NONE = 0;
    const NAMED_LINK = 1;
    const EMAIL_LINK = 2;
    const URL_LINK = 3;

    final wordBuffer = StringBuffer();
    final styleStack = <String>[];
    int readIndex = 0;
    final List<Match?> lineMatches = List.filled(text.length, null);
    final List<int> lineMatchType = List.filled(text.length, MATCH_NONE);

    for
    (
      final matchInfo in
      [
        Tuple2(NAMED_LINK, _namedLinkRegExp),
        Tuple2(EMAIL_LINK, _emailRegExp),
        Tuple2(URL_LINK, _urlRegExp),
      ]
    )
    {
      final matches = matchInfo.item2.allMatches(text);
      for (final match in matches)
      {
        lineMatches[match.start] = match;
        lineMatchType[match.start] = matchInfo.item1;
      }
    }

    do
    {
      final ch = charAT(text, readIndex);
      final type = readIndex < text.length ? lineMatchType[readIndex] : MATCH_NONE;

      try
      {
        switch (type)
        {
          case NAMED_LINK:
          {
            final match = lineMatches[readIndex]!;
            if (match.groupCount >= 2)
            {
              final desc = centerSubstring(match.group(1) ?? '', 1, 1);
              final link = centerSubstring(match.group(2) ?? '', 1, 1);
              final word = (ch == '!')
              ? makeWord(desc, styleStack, type: MarkdownWord_Type.image, image: link)
              : makeWord(desc, styleStack, type: MarkdownWord_Type.link, link: link);
              words.add(word);
            }
          }
          break;

          default: // MATCH_NONE
          {
            switch (ch)
            {
              case '': // konec textu
              break;

              case ' ': // mezera
              writeWord(wordBuffer, styleStack, false);
              readIndex++;
              break;

              case '!': // Obrazek (mozna)
              readIndex++;
              if (charAT(text, readIndex) == '[')
              {
                var match = _namedLinkRegExp.matchAsPrefix(text, readIndex);

                if (match != null && match.start == readIndex)
                {
                  writeWord(wordBuffer, styleStack, false);
                  wordBuffer.write(text.substring(readIndex - 1, match.end));
                  writeWord(wordBuffer, styleStack, false);
                  readIndex = match.end;
                }
              }
              else
              {
                wordBuffer.write(ch);
              }
              break;

              default: // Jiny znak
              {
                final match = _charClassRegExp.matchAsPrefix(text, readIndex);

                if (match != null && match.start == readIndex)
                {
                  // styl
                  readIndex += match.end - match.start;
                  final mValue = matchVal(match);

                  if (styleStack.isNotEmpty && compareClass(styleStack.last, mValue))
                  {
                    // konec stylu
                    final ch = charAT(text, readIndex);
                    writeWord(wordBuffer, styleStack, ch != ' ' && ch != '');
                    styleStack.removeLast();
                  }
                  else
                  {
                    // zacatek stylu
                    styleStack.add(matchVal(match));
                  }
                }
                else
                {
                  readIndex++;
                  wordBuffer.write(ch);
                }
              }
              break;
            }
          }
          break;
        }

        if (type != MATCH_NONE)
        {
          readIndex = lineMatches[readIndex]?.end ?? readIndex + 1;
        }
      }
      catch (e)
      {
        appLogEx(e);
      }
    }
    while (readIndex < text.length);

    writeWord(wordBuffer, styleStack, false); // Posledni slovo
  }

  static String matchVal(Match? match)
  {
    return match?.input.substring(match.start, match.end) ?? '';
  }

  static bool compareClass(String push, String pop)
  {
    return (push == pop) || (pop == '```' && push.startsWith('```@'));
  }

  static String charAT(String text, int index)
  {
    return (index < 0 || index >= text.length) ? '' : text[index];
  }

  void copyWords(MarkdownParagraph src)
  {
    words.add
    (
      MarkdownWord()
      ..lineBreak = true
      ..text = '\r'
    );

    for (var word in src.words)
    {
      words.add(word);
    }
  }
}

class MarkdownDecoration
{
  String decoration = '';
  int level = 0;
  int column = 0;
  int count = 0;

  @override
  String toString()
  {
    return '$decoration level=$level column=$column count=$count';
  }

  MarkdownDecoration(String decor, this.column)
  {
    int ch = decor.codeUnitAt(column);
    if ((ch >= /*$A*/(0x41) && ch <= /*$Z*/(0x5A)) || (ch >= /*$a*/(0x61) && ch <= /*$z*/(0x7A)))
    {
      decor = 'a';
    }
    else if (ch >= /*$0*/(0x30) && ch <= /*$9*/(0x39))
    {
      decor = '1';
    }
    else if (ch == /*$-*/(0x2D) || ch == /*$**/(0x2A) || ch == /*$+*/(0x2B))
    {
      decor = '-';
    }
    else
    {
      decor = decor.substring(column, column + 1);
    }

    decoration = decor;
  }

  static bool compareModify(List<MarkdownDecoration>? current, List<MarkdownDecoration>? prev)
  {
    if (current == null || prev == null)
    {
      return true;
    }
    else
    {
      for (int i = 0; i < prev.length; i++)
      {
        if (i >= current.length)
        {
          return false;
        }
        else
        {
          final c = current[i];
          final p = prev[i];

          if (c.decoration != p.decoration)
          {
            return true;
          }
          else
          {
            if (c.decoration != '>')
            {
              if ((c.column - p.column).abs() < 2)
              {
                c.column = p.column;
                c.level = p.level;
                c.count = p.count + 1;
              }
              else if (c.column > p.column)
              {
                c.level = p.level + 1;
                return true;
              }
              else
              {
                return false;
              }
            }
          }
        }
      }
    }

    return true;
  }

  static void modify(List<MarkdownParagraph> para)
  {
    for (int index = 1; index < para.length; index++)
    {
      final cur = para[index];

      var prev = index - 1;
      while (prev >= 0 && !compareModify(cur.decorations, para[prev].decorations))
      {
        prev--;
      }
    }
  }

  static List<MarkdownDecoration> textToList(String text)
  {
    final result = <MarkdownDecoration>[];

    for (int i = 0; i < text.length;)
    {
      if (text.codeUnitAt(i) != /*$ */(0x20))
      {
        result.add(MarkdownDecoration(text, i));
        while (i < text.length && text.codeUnitAt(i) != /*$ */(0x20))
        {
          i++;
        }
      }
      else
      {
        i++;
      }
    }

    return result;
  }
}

class MarkdownWord
{
  MarkdownWord_Type type = MarkdownWord_Type.word;
  String style = '';
  bool stickToNext = false;
  String text = '';
  bool lineBreak = false;
  String link = '';
  String image = '';

  String get params => image;
  set params(String value) => image = value;

  @override
  String toString()
  {
    final s = stickToNext ? '+' : ' ';
    final t = lineBreak ? '<break>' : text;
    return '[$style]$s "$t"';
  }
}

enum MarkdownWord_Type { word, link, image, link_image, reference_definition }

// -----------------------------------------------