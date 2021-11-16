import 'package:doc_reader/objects/applog.dart';

final _newLineRegex = RegExp(r'([\r\n])|(\r\n)]', multiLine: true);
final _headRegExp = RegExp(r'\s*((\>\s*)|([\-\+\*]\s+)|(\#{1,6}\s+)|(\d+\.\s)|([A-Za-z]\.\s))', multiLine: false);
final _charClassRegExp = RegExp(r'((\_{1,3})|(\*{1,3}))|(\`{3}(@\w+\s))', multiLine: false);
final _namedLinkRegExp = RegExp(r'\[.*\]\(.+\)', multiLine: false);
final _urlRegExp =
RegExp(r'\<?[a-zA-Z0-9]{2,32}:\/\/[a-zA-Z0-9@:%\._\\+~#?&\/=\u00A0-\uD7FF]{2,256}\>?', multiLine: false);
final _emailRegExp =
RegExp(r'\<?[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9\u00A0-\uD7FF)]+(?:\.[a-zA-Z0-9-]+)*\>?', multiLine: false);
final _hrRegExp = RegExp(r'\^\s*(([\*]{3,})|([\-]{3,})|([\_]{3,})|([\=]{3,}))\s*$', multiLine: false);
final _refLinkLinkRegExp = RegExp(r'^\s{0,3}\[.+\]\s+\S+$', multiLine: false);

class Markdown
{
  final paragraphs = <MarkdownParagraph>[];

  writeMarkdownString(String text)
  {
    final lines = text.split(_newLineRegex);

    for (int i = 0; i < lines.length; i++)
    {
      String line = lines[i];

      appLog_debug('line:"$line"');
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

      if (para.lineDecoration.isEmpty && para.words.isEmpty)
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

  void writeWord(StringBuffer wordBuffer, List<String> styleStack, bool stickToNext)
  {
    if (wordBuffer.isNotEmpty)
    {
      words.add
      (
        MarkdownWord()
        ..text = wordBuffer.toString()
        ..style = styleStack.isEmpty ? '' : styleStack.last
        ..stickToNext = stickToNext
      );
      wordBuffer.clear();
    }
  }

  void writeText(String text)
  {
    final wordBuffer = StringBuffer();
    final styleStack = <String>[];
    int readIndex = 0;

    do
    {
      final ch = charAT(text, readIndex);

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

        case '\\': // escape
        wordBuffer.write(charAT(text, readIndex + 1));
        readIndex += 2;
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
            wordBuffer.write(ch);
            readIndex++;
          }
        }
        break;
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
  String style = '';
  bool stickToNext = false;
  String text = '';
  bool lineBreak = false;

  @override
  String toString()
  {
    final s = stickToNext ? '+' : ' ';
    final t = lineBreak ? '<break>' : text;
    return '[$style]$s "$t"';
  }
}

// -----------------------------------------------