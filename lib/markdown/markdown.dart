import 'package:doc_reader/objects/applog.dart';

final newLineRegex = RegExp(r'[\r\n(\r\n)]', multiLine: true);
final headRegExp = RegExp(r'^\s*#{1,6}', multiLine: false);
final listRegExp = RegExp(r'^\s*[\-\+\*]\s', multiLine: false);
final charClass = RegExp(r'((\_{1,3})|(\*{1,3}))|(\`{3}(@\w+\s))', multiLine: false);

class Markdown
{
  final paragraphs = <MarkdownParagraph>[];

  writeMarkdownString(String text)
  {
    final lines = text.split(newLineRegex);

    for (int i = 0; i < lines.length; i++)
    {
      String line = lines[i];
      var head = headRegExp.firstMatch(line);

      appLog_debug('line:"$line"');
      var pClass = '';

      if (head != null)
      {
        pClass = 'h${(head.end - head.start).toString()}';
        line = line.substring(head.end);
        appLog_debug('head:$pClass "$line"');
      }
      var list = listRegExp.firstMatch(line);
      if (list != null)
      {
        pClass = 'li#{list.end}';
        line = line.substring(list.end);
        appLog_debug("list:$pClass '$line'");
      }

      paragraphs.add(MarkdownParagraph(text: line));
    }
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
  String paragraphClass;
  final words = <MarkdownWord>[];

  MarkdownParagraph({required String text, this.paragraphClass = ''})
  {
    writeText(text);
  }

  @override
  String toString()
  {
    final builder = StringBuffer('Paragraph: ${paragraphClass}\r\n');
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

        case '\\': // escape
          wordBuffer.write(charAT(text, readIndex + 1));
          readIndex += 2;
          break;

        default: // Jiny znak
          final match = charClass.matchAsPrefix(text, readIndex);

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
}

class MarkdownWord
{
  String style = '';
  bool stickToNext = false;
  String text = '';

  @override
  String toString()
  {
    final s = stickToNext ? '+' : ' ';
    return '[$style]$s "$text"';
  }
}

// -----------------------------------------------