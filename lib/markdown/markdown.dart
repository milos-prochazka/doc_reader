final newLineRegex = RegExp(r'[\r\n(\r\n)]', multiLine: true);

class Markdown
{
  final paragraphs = <MarkdownParagraph>[];

  writeMarkdownString(String text)
  {
    final lines = text.split(newLineRegex);

    for (int i = 0; i < lines.length; i++)
    {
      String line = lines[i];
      while ((i + 1) < lines.length)
      {
        final nextLine = lines[i + 1];
        final nextLineTrim = nextLine.trim();
        if (nextLineTrim.isNotEmpty)
        {
          line += ' \n' + nextLine;
          i++;
        }
        else
        {
          break;
        }
      }

      print(line);
    }
  }
}

class MarkdownParagraph
{
  String paraClass = '';
}

class MarkdownWord
{
  MarkdownWordStyle style = MarkdownWordStyle.normal;
}

enum MarkdownWordStyle { normal, italic, bold, italicBold }