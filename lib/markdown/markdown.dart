import 'package:doc_reader/objects/applog.dart';

final newLineRegex = RegExp(r'[\r\n(\r\n)]', multiLine: true);
final headRegExp = RegExp(r'^\s*#{1,6}', multiLine: false);
final listRegExp = RegExp(r'^\s*[\-\+\*]\s', multiLine: false);

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
    }
  }
}

class MarkdownParagraph
{
  String paragraphClass;
  final words = <MarkdownWord>[];

  MarkdownParagraph({required String text, this.paragraphClass = ''}) {}

  void writeText(String text) {}
}

class MarkdownWord
{
  MarkdownWordStyle style = MarkdownWordStyle.normal;
  bool stickToNext = false;
  String text = '';
}

enum MarkdownWordStyle { normal, italic, bold, italicBold }

// -----------------------------------------------