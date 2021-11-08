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
      print('line:"$line"');
      if (head != null)
      {
        print('head:${head.end - head.start}');
      }
      var list = listRegExp.firstMatch(line);
      if (list != null)
      {
        print("list:${list.end}");
      }
    }
  }
}

class MarkdownParagraph
{
  String paragraphClass = '';
}

class MarkdownWord
{
  MarkdownWordStyle style = MarkdownWordStyle.normal;
}

enum MarkdownWordStyle { normal, italic, bold, italicBold }