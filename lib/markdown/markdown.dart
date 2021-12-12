// ignore_for_file: constant_identifier_names

import 'package:doc_reader/markdown/patterns.dart';
import 'package:doc_reader/objects/applog.dart';
import 'package:doc_reader/objects/utils.dart';
import 'package:tuple/tuple.dart';

/// Deleni textu na radky
final _newLineRegex = RegExp(r'([\r\n])|(\r\n)]', multiLine: true);

/// Detekce radku ktere se nespojuji s  ( zacatek #, []:, * , - , + , 1. , a., A. , ```, nebo horizontalni cara)
final _noMergeRegExp = RegExp
(
  r'(^\s*#{1,6}\s.*)|(^\[.*\]\:)|(^\s*\>+\s*)|(^\s*[\-\+\*]\s+)|(^\s*\#{1,6}\s+)|(^\s*\d+\.\s)|(^\s*[A-Za-z]\.\s)|(^\s*[\-\=\*\`]{3,}\s*$)',
  multiLine: false
);

/// Detekce potencialnniho potrzeni nadpisu
final _headUnderlineRegExp = RegExp(r'^\s*[\-\=]{3,}\s*', multiLine: false);

/// Detekce nadpisu a odsazeni
final _headRegExp = RegExp(r'\s*((\>+\s*)|([\-\+\*]\s+)|(\#{1,6}\s+)|(\d+\.\s)|([A-Za-z]\.\s))', multiLine: false);

/// Detekce znaku # na konci nadpisu (odstrani se)
final _headEndRegExp = RegExp(r'\s*\#{1,}\s*$', multiLine: false);

/// Detekce znaku # na konci nadpisu s escapovanim (neodstrani se)
final _headEcapeEndRegExp = RegExp(r'\uE023[\uE023#]*\s*$', multiLine: false);

/// Detekce odsazeneho bloku (mezery na zacatku)
final _indentBlockRegExp = RegExp(r'^\s{4,}', multiLine: false);

/// Detekce uvodu/konce bloku ```name => g1=``` g2=name
final _blockRegExp = RegExp(r'^\s*(\`{3,})(\w*)\s*$', multiLine: false);

/// Trida znaku (italic,bold a dalsi)
final _charClassRegExp = RegExp(r'((\_{1,3})|(\*{1,3}))|(\`{3}(@\w+\s))', multiLine: false);

/// Dlouhy link (obsahuje URL)
final _longLinkRegExp = RegExp(r'(\!?)\[([^\]]+)\]\(([^\)]+)\)', multiLine: false);

/// Kratky link [link] , nebo ![_image]
/// ![myImage] g1=! g2=image
final _shortLinkRegExp = RegExp(r'(\!?)\[([^\]]+)\]', multiLine: false);

// TODO UPRAVIT!!!
/// Obrazek se zadanou velikosti
/// img.jpg =1.5%x34em right .mycls gr2 = 1.5 , gr3 = % , gr8 = 34 , gr9 = em , gr14 = right, gr16 = mycls
final _imageSizeRegExp = RegExp
(
  r'\s\=\s*(([\d\.]*)((px)|(em)|(%))?)?\s*[xX]\s*(([\d\.]*)((px)|(em)|(%))?)?(\s*([\.\#]?[\w\-]+))?(\s*([\.\#]?[\w\-]+))?\s*$',
  multiLine: false,
  caseSensitive: false
);

/// Obrazek se zadanou tridou
/// imge.jpg .myclass gr1=myclass
final _imageClassRegExp = RegExp(r'\s+\.(\w+)\s*$', multiLine: false);

/// Special attributes {.class}  {#anchor} {*name=dddd}
final _attributeLikRegExp = RegExp(r'\{([\.\#\*])([^}]+)\}');

/// Url link: http://www.any.org nebo <http://www.any.org>
final _urlRegExp = RegExp(r'\<?([a-zA-Z0-9]{2,32}:\/\/[a-zA-Z0-9@:%\._\\+~#?&\/=\u00A0-\uD7FF\uE000-\uE080]{2,256})\>?',
  multiLine: false);

/// Email link: aaaa@dddd.org nebo <aaaa@dddd.org>
final _emailRegExp = RegExp
(
  r'\<?([a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9\u00A0-\uD7FF\uE000-\uE080)]+(?:\.[a-zA-Z0-9-]+)*)\>?',
  multiLine: false
);

/// Horizontalni cara --- , === , ___ , ***
final _hrRegExp = RegExp(r'^\s*(([\*]{3,})|([\-]{3,})|([\_]{3,})|([\=]{3,}))\s*$', multiLine: false);

/// Reference na link:
///  [aaa]: http://wwww.seznam.cz g2='' g3=aaa g4=http://wwww.seznam.cz
/// Nebo definice tridy:
///  [.myclass]: width=100em height=50em color=#cfa g2=. g3=myclass g4=width=100em height=50em color=#cfa
//final _refLinkLinkRegExp = RegExp(r'^\s{0,3}(\[(\.?)(.+)\])\:\s+(.+)*$', multiLine: false);

// Nova definice
final _refLinkLinkRegExp = LinkPattern(LinkPattern.TYPE_LINK_REFERENCE);

// Pojemnovany atroibitu: width=100em  g1=width g2=100em
//final _namedAttributeRegExp = RegExp(r'(\w+)\=(\S+)', multiLine: false);
final _namedAttributeRegExp = RegExp(r'\s([-_%\w]+)\=', multiLine: false);

/// Vyhledani escape eskvenci ve vstupnim textu
//final _escapeCharRegExp = RegExp(r'\\[\\\`\*\_\{\}\[\]\(\)\#\+\-\.\!\|\:\s]', multiLine: false);
final _escapeCharRegExp = RegExp(r'\\[\x21-0x2f\x3a-\x40\x5b-\x60\x7b-\x7e]', multiLine: false);

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
/// : E03A

class Markdown
{
  // Vsechny odstavce dokumentu
  final paragraphs = <MarkdownParagraph>[];
  // Pojmenovane linky
  final namedLinks = <String, MarkdownWord>{};
  // Tridy
  final classes = <String, Map<String, Object?>>{};
  // Vsechny odstavce odsazene pomoci mezerer
  final _indentParas = <MarkdownParagraph>{};

  writeMarkdownString(String text)
  {
    var blockClass = '';
    final lines = detab(MarkdownParagraph.escape(text), 4).split(_newLineRegex);
    //final lines = textToLines(text);

    for (int i = 0; i < lines.length; i++)
    {
      String line = lines[i].trimRight();

      appLog_debug('line:"$line"');

      Match? match;

      if ((match = _refLinkLinkRegExp.firstMatch(line)) != null)
      {
        // Pojmenovany link nebo definice tridy
        var name = match![LinkPattern.GR_ALT] ?? '';
        final data = (match[LinkPattern.GR_URL_PART] ?? '').trim();
        if (name.startsWith('.'))
        {
          // Trida
          name = name.substring(1);
          final clsData = ' ' + data;
          final attributes = _namedAttributeRegExp.allMatches(clsData).toList();
          final clsAttr = classes[name] ?? <String, Object?>{};

          for (var i = 0; i < attributes.length; i++)
          {
            final attr = attributes[i];
            final end = (i + 1) < attributes.length ? attributes[i + 1].start : clsData.length;
            //print ((attr.group(1)??'<>') + '=' + (attr.group(2)??'<>'));
            final attrName = MarkdownParagraph.unescape(attr.group(1) ?? '');
            final attrValue = MarkdownParagraph.unescape(attr.input.substring(attr.end, end).trim());

            clsAttr[attrName] = attrValue;
          }

          classes[name] = clsAttr;
        }
        else
        {
          // Link
          //paragraphs.add(MarkdownParagraph.referenceLink(name, data));
          namedLinks[name] = MarkdownWord.fromMatch(match);
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
            paragraphs.last.masterClass = ch == '=' ? 'h1' : 'h2';
          }
          else
          {
            paragraphs.add(MarkdownParagraph(text: '', pargraphClass: ''.padLeft(3, ch)));
          }
          break;

          default:
          paragraphs.add(MarkdownParagraph(text: '', pargraphClass: ''.padLeft(3, ch)));
          break;
        }
      }
      else if ((match = _blockRegExp.firstMatch(line)) != null)
      {
        final cls = match?.group(2) ?? '';

        if (cls.isEmpty)
        {
          blockClass = (blockClass.isEmpty) ? 'indent' : '';
        }
        else
        {
          blockClass = cls;
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
              if (!_headEcapeEndRegExp.hasMatch(line))
              {
                line = line.replaceAll(_headEndRegExp, '');
              }
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

        final indent = _indentBlockRegExp.firstMatch(line);
        final indentPara = indent != null && blockClass.isEmpty;
        if (indentPara && pStart.isEmpty)
        {
          hClass = 'indent';
        }
        else if (blockClass.isNotEmpty)
        {
          hClass = blockClass;
        }

        line = line.substring(headEnd);
        appLog_debug('[$pStart] [$hClass] "$line"');

        final newPara = MarkdownParagraph(text: line, lineDecoration: pStart, pargraphClass: hClass);
        if (indentPara)
        {
          _indentParas.add(newPara);
        }
        paragraphs.add(newPara);
      }
    }

    _doProcess();
  }

  String _textLine(List<String> lines, int index)
  {
    return (index >= 0 && index < lines.length) ? lines[index].trimRight() : '';
  }

  List<String> textToLines(String text)
  {
    final lines = detab(MarkdownParagraph.escape(text), 4).split(_newLineRegex);
    final result = <String>[];

    for (var i = 0; i < lines.length; i++)
    {
      final line = _textLine(lines, i);

      if (line.isEmpty)
      {
        result.add(line);
      }
      else if (_noMergeRegExp.hasMatch(line))
      {
        result.add(line);
      }
      else
      {
        var nextLine = _textLine(lines, i + 1);

        if
        (
          nextLine.isEmpty ||
          _noMergeRegExp.hasMatch(nextLine) ||
          _headUnderlineRegExp.hasMatch(_textLine(lines, i + 2))
        )
        {
          result.add(line);
        }
        else
        {
          final builder = StringBuffer(line);
          do
          {
            builder.write('\n');
            builder.write(nextLine);
            i++;
            nextLine = _textLine(lines, i + 1);
          }
          while
          (
            !
            (
              nextLine.isEmpty ||
              _noMergeRegExp.hasMatch(nextLine) ||
              _headUnderlineRegExp.hasMatch(_textLine(lines, i + 2))
            )
          );

          result.add(builder.toString());
        }
      }
    }

    return result;
  }

  /// Zpracovani nacteneho textu
  void _doProcess()
  {
    // Slouceni odstavcu
    _mergeAfterBullet();

    // Slouceni odstavcu odsazenych pomoci mezer
    _mergeIndent();

    // Vypusteni prazdnych odstavcu
    _removeBlankLines();

    // Nalezeni odstavcu tesne za sebou (zobrazene bez mezery)
    _mergeTight();

    // Kompilace odsazeni
    _makeDecorations();

    // Nalezeni odkazu na kratke linky (liny uvnitr dokumentu)
    compileLinks();

    //MarkdownDecoration.create(paragraphs);
  }

  /// Nalezeni odkazu na kratke linky (liny uvnitr dokumentu)
  compileLinks()
  {
    final remove = <MarkdownWord>[];

    for (final para in paragraphs)
    {
      remove.clear();
      for (final word in para.words)
      {
        switch (word.type)
        {
          // Odkaz
          case MarkdownWord_Type.link:
          {
            if (!word.attribs.containsKey('link'))
            {
              final link = namedLinks[word.text]?.attribs['link'];
              if (link != null)
              {
                word.attribs.addAll({'link': link});
              }
              else
              {
                remove.add(word);
              }
            }
          }
          break;

          // Obrazek
          case MarkdownWord_Type.image:
          {
            if (!word.attribs.containsKey('image'))
            {
              final image = namedLinks[word.text];
              if (image != null)
              {
                word.attribs.addAll(image.attribs);
              }
              else
              {
                remove.add(word);
              }
            }
          }
          break;

          default:
          break;
        }
      }

      // Odstraneni linku bez odkazu
      for (final word in remove)
      {
        para.words.remove(word);
      }
    }
  }

  /// Slouceni odstavcu za odsazenim.
  ///
  /// Pripojuje se odstavec :
  /// - na odsazenym odstavcem (zacatek - + * > )
  /// - bez kotev a podtridy
  /// - stejne tridy jako predchozi odstavec
  _mergeAfterBullet()
  {
    const mergeCls = ['p.p', 'p.indent', 'indent.p', "indent.indent"];

    for (int i = 1; i < paragraphs.length;)
    {
      final para = paragraphs[i];
      final prevPara = paragraphs[i - 1];

      if
      (
        !para.isBlankLine &&
        para.lineDecoration.isEmpty &&
        prevPara.lineDecoration.isNotEmpty &&
        para.subclass.isEmpty &&
        para.anchors.isEmpty &&
        mergeCls.contains('${prevPara.masterClass}.${para.masterClass}')
      )
      {
        prevPara.words.add(MarkdownWord.newLine());
        prevPara.copyWords(para);
        paragraphs.removeAt(i);
      }
      else
      {
        i++;
      }
    }
  }

  /// Slouceni odstavcu odsazenych pomoci mezer
  ///
  /// - vytvari bloky z odstavcu odsazenych pomoci mezer (trida indent)
  ///
  _mergeIndent()
  {
    for (int i = 1; i < paragraphs.length; i++)
    {
      final para = paragraphs[i];
      if (_indentParas.contains(para))
      {
        int end = -1;

        for (int j = i + 1; j < paragraphs.length; j++)
        {
          final nextPara = paragraphs[j];
          if (!nextPara.isEmpty)
          {
            if (_indentParas.contains(nextPara))
            {
              end = j;
              break;
            }
          }
        }

        if (end > 0)
        {
          for (int j = i + 1; j < end; j++)
          {
            final nextPara = paragraphs[j];
            nextPara.masterClass = para.masterClass;
            nextPara.words.add(MarkdownWord.newLine());
          }
        }
      }
    }
  }

  static String detab(String text, int tabSize)
  {
    if (!text.contains("\t"))
    {
      return text;
    }
    else
    {
      final builder = StringBuffer();

      for (final ch in text.codeUnits)
      {
        if (ch == /*$\t*/(0x9))
        {
          final l = builder.length;
          var n = tabSize - (l % tabSize);

          while (n > 0)
          {
            builder.writeCharCode(/*$ */(0x20));
            n--;
          }
        }
        else
        {
          builder.writeCharCode(ch);
        }
      }

      return builder.toString();
    }
  }

  // Vypusteni prazdnych odstavcu
  // - Pokud za sebou nasleduje dva a vice prazdnych odstavcu ponecha pouze jeden
  _removeBlankLines()
  {
    for (int i = 1; i < paragraphs.length; i++)
    {
      final para = paragraphs[i];
      final prevPara = paragraphs[i - 1];

      if (prevPara.masterClass == 'p')
      {
        if (prevPara.isEmpty)
        {
          if (para.isBlankLine)
          {
            paragraphs.removeAt(i);
            i--;
          }
          else
          {
            prevPara.words.add(MarkdownWord.newLine());
          }
        }
      }
      else if (prevPara.isEmpty)
      {
        prevPara.words.add(MarkdownWord.newLine());
      }
    }
  }

  // Nalezeni odstavcu tesne za sebou (zobrazene bez mezery)
  // - provede slouceni do bloku pomoci lastInClass a firstInClass
  _mergeTight()
  {
    for (int i = 1; i < paragraphs.length; i++)
    {
      final para = paragraphs[i];
      final prevPara = paragraphs[i - 1];

      if (para.masterClass == prevPara.masterClass && (const ['p', 'indent']).contains(para.masterClass))
      {
        prevPara.lastInClass = false;
        para.firstInClass = false;
      }
    }
  }

  /// Vytvoreni odsazeni
  /// - Vytvori odsazeni (pole decorations)
  /// - Odstrani nadbytecne prazdne radky
  _makeDecorations()
  {
    for (int i = 0; i < paragraphs.length;)
    {
      final para = paragraphs[i];

      // TODO tohle nefunguje para.isBlankLine && para.masterClass.isEmpty je vzdy false
      if (para.lineDecoration.isEmpty && para.isBlankLine && para.masterClass.isEmpty)
      {
        paragraphs.removeAt(i);
      }
      else
      {
        para.decorations = MarkdownDecoration.textToList(para.lineDecoration);
        i++;
      }
    }

    // Spocitani urvni odsazeni a poradi v seznamech ¡¡
    MarkdownDecoration.create(paragraphs);
  }

  @override
  String toString()
  {
    bool insertHr = false;
    final builder = StringBuffer('Markdown: ${paragraphs.length} paragraphs\r\n');

    if (classes.isNotEmpty)
    {
      builder.write('Classes:\r\n');
      insertHr = true;
      for (final cls in classes.entries)
      {
        builder.write('  ${cls.key}:');
        for (final attr in cls.value.entries)
        {
          builder.write(' ${attr.key}:${attr.value}');
        }
        builder.write('\r\n');
      }
    }

    if (namedLinks.isNotEmpty)
    {
      builder.write('Links:\r\n');
      insertHr = true;
      for (final link in namedLinks.entries)
      {
        builder.write("  ${link.key}: '${link.value}'\r\n");
      }
    }

    if (insertHr)
    {
      builder.write('============\r\n');
    }

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
  MarkdownParagraphType type = MarkdownParagraphType.normalParagraph;
  String lineDecoration = '';
  List<MarkdownDecoration>? decorations;
  String masterClass;
  String subclass;
  final anchors = <String>[];
  final words = <MarkdownWord>[];
  final attributes = <String, String>{};
  bool lastInClass = true;
  bool firstInClass = true;

  MarkdownParagraph({required String text, this.lineDecoration = '', pargraphClass = ''})
  : masterClass = pargraphClass.isEmpty ? 'p' : pargraphClass,
  subclass = ''
  {
    writeText(text);
  }

  MarkdownParagraph.referenceLink(String linkName, String linkUrl)
  : type = MarkdownParagraphType.linkReferece,
  masterClass = linkName,
  subclass = linkUrl;

  String get linkName => masterClass;

  String get linkUrl => subclass;

  String fullClassName([MarkdownWord? word, bool bullet = false])
  {
    final cname = subclass.isEmpty ? masterClass : '$masterClass.$subclass';
    final fname = (word?.style.isEmpty ?? true) ? cname : '$cname.${word?.style}';
    return bullet ? '$fname.\ue100' : fname;
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
    final builder = StringBuffer('Paragraph: type=${enum_ToString(type)} ');

    switch (type)
    {
      case MarkdownParagraphType.linkReferece:
      builder.write("name='$linkName' link='$linkUrl'\r\n");
      break;

      default:
      builder.write("start='$lineDecoration' class='$masterClass' '$subclass'\r\n");
      break;
    }
    var label = false;

    if (decorations != null && decorations!.isNotEmpty)
    {
      builder.write('Decorations:');
      for (final dec in decorations!)
      {
        builder.write(' "${dec.toString()}"');
      }

      builder.write('\r\n');
      label = words.isNotEmpty;
    }

    if (anchors.isNotEmpty)
    {
      builder.write('Anchors:');
      for (final dec in anchors)
      {
        builder.write(' ${dec.toString()}');
      }
      builder.write('\r\n');
      label = words.isNotEmpty;
    }

    if (attributes.isNotEmpty)
    {
      builder.write('Attributes:');
      for (final dec in attributes.entries)
      {
        builder.write(' ${dec.key}=${dec.value}');
      }
      builder.write('\r\n');
    }

    if (label)
    {
      builder.write('Words:\r\n');
    }

    for (int i = 0; i < words.length; i++)
    {
      final word = words[i].toString();
      builder.write('  $i: $word\r\n');
    }
    return builder.toString();
  }

  MarkdownWord makeWord(String text, List<String> styleStack,
    {MarkdownWord_Type type = MarkdownWord_Type.word, bool stickToNext = false, Map<String, String?>? attr})
  {
    final result = MarkdownWord()
    ..type = type
    ..text = MarkdownParagraph.unescape(text)
    ..style = styleStack.isEmpty ? '' : styleStack.last
    ..stickToNext = stickToNext;

    if (attr != null)
    {
      result.attribs.addAll(attr);
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

  /*static String centerSubstring(String text, int prefix, int postfix)
  {
    if ((prefix + postfix) >= text.length)
    {
      return '';
    }
    else
    {
      return text.substring(prefix, text.length - postfix);
    }
  }*/

  writeText(String text)
  {
    const MATCH_NONE = 0;
    const LONG_LINK = 1;
    const SHORT_LINK = 2;
    const EMAIL_LINK = 3;
    const URL_LINK = 4;
    const ATTRIBUTE = 5;

    final wordBuffer = StringBuffer();
    final styleStack = <String>[];
    int readIndex = 0;
    final List<Match?> lineMatches = List.filled(text.length, null);
    final List<int> lineMatchType = List.filled(text.length, MATCH_NONE);

    for
    (
      final matchInfo in
      [
        Tuple2(SHORT_LINK, _shortLinkRegExp),
        Tuple2(EMAIL_LINK, _emailRegExp),
        Tuple2(URL_LINK, _urlRegExp),
        Tuple2(LONG_LINK, _longLinkRegExp),
        Tuple2(ATTRIBUTE, _attributeLikRegExp),
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
        if (type != MATCH_NONE)
        {
          writeWord(wordBuffer, styleStack, true);
        }

        switch (type)
        {
          case LONG_LINK:
          {
            final match = lineMatches[readIndex]!;
            if (match.groupCount >= 3)
            {
              final type = match.group(1) ?? '';
              final desc = match.group(2) ?? '';
              final link = match.group(3) ?? '';
              MarkdownWord? word;

              if (type == '!')
              {
                word = makeWord(desc, styleStack, type: MarkdownWord_Type.image, attr: _imageAttributes(link));
              }
              else
              {
                word = makeWord(desc, styleStack, type: MarkdownWord_Type.link, attr: {'link': link});
              }

              word.stickToNext = charAT(text, match.end) != ' ';
              words.add(word);
            }
          }
          break;

          case SHORT_LINK:
          {
            final match = lineMatches[readIndex]!;
            MarkdownWord? word;

            if (match.groupCount >= 2)
            {
              final type = match.group(1) ?? '';
              final name = match.group(2) ?? '!';
              if (type == '!')
              {
                word = makeWord(name, styleStack, type: MarkdownWord_Type.image);
              }
              else
              {
                word = makeWord(name, styleStack, type: MarkdownWord_Type.link);
              }

              word.stickToNext = charAT(text, match.end) != ' ';
              words.add(word);
            }
          }
          break;

          case ATTRIBUTE:
          {
            final match = lineMatches[readIndex]!;
            if (match.groupCount >= 2)
            {
              final type = match.group(1) ?? '';
              final text = match.group(2) ?? '';
              switch (type)
              {
                case '.':
                subclass = text;
                break;

                case '#':
                anchors.add(text);
                break;

                case '*':
                if (text.contains('='))
                {
                  final kvi = text.indexOf('=');
                  attributes[text.substring(0, kvi).trim()] = text.substring(kvi + 1).trim();
                }
                else
                {
                  final t = text.trim();
                  attributes[t] = t;
                }
              }
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

              case '\n': // Novy radek
              writeWord(wordBuffer, styleStack, false);
              words.add(MarkdownWord.newLine());
              readIndex++;
              break;

              case '!': // Obrazek (mozna)
              readIndex++;
              if (charAT(text, readIndex) == '[')
              {
                var match = _longLinkRegExp.matchAsPrefix(text, readIndex);

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
                    writeWord(wordBuffer, styleStack, true);
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
      catch (ex, stackTrace)
      {
        appLogEx(ex, stackTrace: stackTrace);
      }
    }
    while (readIndex < text.length);

    writeWord(wordBuffer, styleStack, false); // Posledni slovo
  }

  static Map<String, String?> _imageAttributes(String imageUri)
  {
    // TODO Upravit _imageSizeRegExp
    var info = _imageSizeRegExp.firstMatch(imageUri);

    if (info != null)
    {
      final w = info.group(2) ?? '';
      final wu = info.group(3) ?? '';
      final h = info.group(8) ?? '';
      final hu = info.group(9) ?? '';
      String? al;
      String? cl;

      for (final p in [info.group(14), info.group(16)])
      {
        if (p != null)
        {
          if (p.startsWith('.'))
          {
            cl = p.substring(1);
          }
          else
          {
            al = p;
          }
        }
      }

      return <String, String?>
      {
        'image': imageUri.substring(0, info.start).trim(),
        'width': w + wu,
        'height': h + hu,
        'align': al,
        'class': cl,
      };
    }
    else if ((info = _imageClassRegExp.firstMatch(imageUri)) != null)
    {
      return <String, String?>
      {
        'image': imageUri.substring(0, info!.start).trim(),
        'class': info.group(1),
      };
    }
    else
    {
      return <String, String?>{'image': imageUri};
    }
  }

  static String matchVal(Match? match)
  {
    //return match?.input.substring(match.start, match.end) ?? '';
    return match?.group(0) ?? '';
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
    for (var word in src.words)
    {
      words.add(word);
    }
  }

  bool get isBlankLine => masterClass == 'p' && words.isEmpty;

  bool get isEmpty => words.isEmpty;
}

enum MarkdownParagraphType { normalParagraph, linkReferece }

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
    if (ch >= /*$a*/(0x61) && ch <= /*$z*/(0x7A))
    {
      decor = 'a';
    }
    if (ch >= /*$A*/(0x41) && ch <= /*$Z*/(0x5A))
    {
      decor = 'A';
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

          /*if (c.decoration != p.decoration)
          {
            return true;
          }
          else*/
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

  static void create(List<MarkdownParagraph> para)
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
      final ch = text.substring(i, i + 1);
      if (ch != ' ')
      {
        if ((result.isNotEmpty) && (ch == result.last.decoration))
        {
          result.last.level++;
          i++;
        }
        else
        {
          result.add(MarkdownDecoration(text, i++));
        }

        while (i < text.length && text.codeUnitAt(i) == /*$.*/(0x2E))
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
  final attribs = <String, String?>{};

  MarkdownWord();

  factory MarkdownWord.newLine()
  {
    return MarkdownWord()..lineBreak = true;
  }

  _matchAttrib(String attrib, Match match, int index)
  {
    final data = match[index];

    if (data != null)
    {
      attribs[attrib] = data;
    }
  }

  factory MarkdownWord.fromMatch(Match match)
  {
    final result = MarkdownWord()
    ..type = (match[LinkPattern.GR_EXCLAMATION] == '!') ? MarkdownWord_Type.image : MarkdownWord_Type.link;

    result.text = match[LinkPattern.GR_ALT] ?? '';
    result._matchAttrib('width', match, LinkPattern.GR_WIDTH);
    result._matchAttrib('height', match, LinkPattern.GR_HEIGHT);
    result._matchAttrib('align', match, LinkPattern.GR_ALIGN);
    result._matchAttrib('class', match, LinkPattern.GR_CLASS);
    result._matchAttrib('title', match, LinkPattern.GR_TITLE);
    result._matchAttrib('voice', match, LinkPattern.GR_VOICE);

    if (result.type == MarkdownWord_Type.image)
    {
      result._matchAttrib('image', match, LinkPattern.GR_URL);
    }
    else
    {
      result._matchAttrib('link', match, LinkPattern.GR_LINK);
      result._matchAttrib('image', match, LinkPattern.GR_LINK);
    }

    return result;
  }

  @override
  String toString()
  {
    final s = stickToNext ? '+' : ' ';
    final t = lineBreak ? '<break>' : text;
    final builder = StringBuffer("[$style]$s '$t' ${type.toString().replaceAll('MarkdownWord_Type.', '')}");

    for (final attr in attribs.entries)
    {
      builder.write(' ${attr.key}=${attr.value ?? "(null)"}');
    }

    return builder.toString();
  }
}

enum MarkdownWord_Type { word, link, image, link_image, reference_definition }