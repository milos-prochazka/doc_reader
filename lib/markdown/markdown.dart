// ignore_for_file: constant_identifier_names

import 'dart:ui';

import 'package:doc_reader/objects/json_utils.dart';

import 'patterns.dart';
import '../objects/applog.dart';
import '../objects/text_load_provider.dart';
import '../objects/utils.dart';
import 'package:tuple/tuple.dart';

/// Deleni textu na radky
final _newLineRegex = RegExp(r'\r\n|\n|\r]', multiLine: true);

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
//final _charClassRegExp = RegExp(r'((\_{1,3})|(\*{1,3}))|(\`{3}(@\w+\s))', multiLine: false);
final _charClassRegExp = RegExp(r'([\_\*]{1,3})|(\`{3}(.\w+\s)?)', multiLine: false);

/// Dlouhy link (obsahuje URL)
final _longLinkRegExp = LinkPattern(LinkPattern.TYPE_LINK);

/// Kratky link [link] , nebo ![_image]
/// ![myImage][id] g1=! g2=image
final _shortLinkRegExp = RegExp(r'(\!?)\[([^\]]+)\]', multiLine: false);

/// Obrazek s popisem a odkazem na definici obrazku ![popis obrazku][id]
/// ![myImage][id] g1=muImage g2=id
final _idImageRegExp = RegExp(r'\!\[([^\]]+)\]\[([^\]]+)\]', multiLine: false);

/// Special attributes {.class}  {#anchor} {*name=dddd}
final _attributeLikRegExp = RegExp(r'\{([\.\#\*])([^}]+)\}');

/// Url link: http://www.any.org nebo <http://www.any.org>
final _urlRegExp = RegExp
(
  r'(\`)?\<?([a-zA-Z0-9]{2,32}:\/\/[a-zA-Z0-9@:%\._\\+~#?&\/=\u00A0-\uD7FF\uE000-\uE080]{2,256})\>?(\`)?',
  multiLine: false
);

/// Email link: aaaa@dddd.org nebo <aaaa@dddd.org>
final _emailRegExp = RegExp
(
  r'(\`)?\<?([a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9\u00A0-\uD7FF\uE000-\uE080)]+(?:\.[a-zA-Z0-9-]+)*)\>?(\`)?',
  multiLine: false
);

/// Horizontalni cara --- , === , ___ , ***
final _hrRegExp = RegExp(r'^\s*(([\*]{3,})|([\-]{3,})|([\_]{3,})|([\=]{3,}))\s*$', multiLine: false);

/// Reference na link:
///  [aaa]: http://wwww.seznam.cz g2='' g3=aaa g4=http://wwww.seznam.cz
/// Nebo definice tridy:
///  [.myclass]: width=100em height=50em color=#cfa g2=. g3=myclass g4=width=100em height=50em color=#cfa
final _refLinkLinkRegExp = LinkPattern(LinkPattern.TYPE_LINK_REFERENCE);

// Pojemnovany atroibitu: width=100em  g1=width g2=100em
//final _namedAttributeRegExp = RegExp(r'(\w+)\=(\S+)', multiLine: false);
final _namedAttributeRegExp = RegExp(r'\s([-_%\w]+)\=', multiLine: false);

/// Vyhledani escape eskvenci ve vstupnim textu
//final _escapeCharRegExp = RegExp(r'\\[\\\`\*\_\{\}\[\]\(\)\#\+\-\.\!\|\:\s]', multiLine: false);
final _escapeCharRegExp = RegExp(r'\\[\x21-0x2f\x3a-\x40\x5b-\x60\x7b-\x7e]', multiLine: false);

/// Vyhledani escapovanych znaku
final _escapedCharRegExp = RegExp(r'[\uE000-\uE0FF]', multiLine: false, unicode: true);

/// Vyhledani mezer (vyhleda bloky vice mezer za sebou mezer), hlavne pro split
final _spacesRegEx = RegExp(r'\s+', multiLine: true, unicode: true);

/// Escapovane znaky:
/// \ E0C0
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

  Markdown();

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
          namedLinks[name] = MarkdownWord.fromMatch(match, _StyleStack.empty);
        }
      }
      else if (_hrRegExp.hasMatch(line))
      {
        final ch = line.trim()[0];
        switch (ch)
        {
          case '=':
          case '-':
          if (paragraphs.isNotEmpty && paragraphs.last.isNotEmpty)
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
                word.attribs.addAll({'link': MarkdownParagraph.unescape(link)});
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
      para.removeAll(remove);
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
    const mergeCls = ['p.p', 'p.indent', 'indent.p', 'indent.indent'];

    for (int i = 1; i < paragraphs.length;)
    {
      final para = paragraphs[i];
      final prevPara = paragraphs[i - 1];

      if
      (
        !para.isBlankLine &&
        para.lineDecoration.isEmpty &&
        prevPara.lineDecoration.isNotEmpty &&
        para.subClass.isEmpty &&
        para.anchors.isEmpty &&
        mergeCls.contains('${prevPara.masterClass}.${para.masterClass}')
      )
      {
        prevPara.add(MarkdownWord.newLine());
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
        //print('indent: $para');
        int j = i + 1;
        if (j < paragraphs.length)
        {
          if (paragraphs[j].isEmpty)
          {
            //print('empty: ${paragraphs[j]}');
            for (; j < paragraphs.length; j++)
            {
              final nextPara = paragraphs[j];
              if (!nextPara.isEmpty)
              {
                if (_indentParas.contains(nextPara))
                {
                  for (var k = i + 1; k < j; k++)
                  {
                    final indentPara = paragraphs[k];
                    _indentParas.add(indentPara);
                    indentPara.masterClass = 'indent';
                    indentPara.add(MarkdownWord.newLine());
                  }
                }
                break;
              }
            }
          }
        }
      }
    }
  }

  static String detab(String text, int tabSize)
  {
    if (!text.contains('\t'))
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

  /// Vypusteni prazdnych odstavcu
  /// - Pokud za sebou nasleduje dva a vice prazdnych odstavcu ponecha pouze jeden
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
            prevPara.add(MarkdownWord.newLine());
          }
        }
      }
      else if (prevPara.isEmpty)
      {
        prevPara.add(MarkdownWord.newLine());
      }
    }
  }

  /// Nalezeni odstavcu tesne za sebou (zobrazene bez mezery)
  /// - provede slouceni do bloku pomoci lastInClass a firstInClass
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
        para.listIndent = MarkdownListIndentation.fromText(para.lineDecoration);
        para.blockquoteLevel = MarkdownListIndentation.blockque(para.lineDecoration);
        i++;
      }
    }

    // Spocitani urvni odsazeni a poradi v seznamech ¡¡
    MarkdownListIndentation.create(paragraphs);
  }

  /// Načtení markdown textu
  /// - Podporuje TextLoadProvider pro načítání textu
  /// - Podporuje direktivu:
  /// ```
  /// [#include] file.md
  /// ```
  /// Tato direktiva se píše na samostatném řádku a vloží text souboru **file.md** do načteného textu.
  ///
  static Future<String> loadText(String name, TextLoadProvider provider, [int level = 0]) async
  {
    String text;

    try
    {
      text = name.isNotEmpty ? await provider.loadText(name, level > 0) : '';
    }
    catch (e, stackTrace)
    {
      appLogEx(e, msg: "Can't load file:$name", stackTrace: stackTrace);
      throw TextLoadException(name);
    }

    final includeRegEx = RegExp(r'^\s{0,3}\[#include\]:\s*(\S+).*$', multiLine: true, caseSensitive: false);
    final matches = includeRegEx.allMatches(text);

    if (matches.isNotEmpty)
    {
      var index = 0;
      final builder = StringBuffer();

      for (final match in matches)
      {
        builder.write(text.substring(index, match.start));
        if (level < 5)
        {
          final include = await loadText(match[1] ?? '', provider, level + 1);
          builder.write(include);
        }
        index = match.end;
      }

      if (index < text.length)
      {
        builder.write(text.substring(index, text.length));
      }

      text = builder.toString();
    }

    return text;
  }

  /// Oprava umisteni interpunkcnich znamenek
  /// - Vice mezer zameni za jednu mezeru (kromne zacatku radku)
  /// - Mezery pred teckou, carkou a dvojteckou
  static String spellCorrect(String text)
  {
    // Slouceni mezer
    final multispace = RegExp(r'([^\s\r\n])([^\S\r\n\t]{2,})([\S\r\n$])', multiLine: true, unicode: true);
    text = text.replaceAllMapped
    (
      multispace, (Match m) => (m[3] == '\r' || m[3] == '\n') ? '${m[1]}${m[3]}' : '${m[1]} ${m[3]}'
    );

    final canAfterDot = RegExp(r"[\d\s\r\n\u0022\']");
    final dot = RegExp(r'(.)([\.\,\:])(.|\r|\n)', multiLine: true);
    text = text.replaceAllMapped
    (
      dot, (Match m)
      {
        var first = m[1];
        if (first == ' ')
        {
          first = '';
        }

        var last = m[3] ?? '';
        if (!canAfterDot.hasMatch(last))
        {
          last = ' ' + last;
        }

        return '$first${m[2]}$last';
      }
    );

    return text;
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

  dynamic toJson([bool compress = false])
  {
    final paraList = <dynamic>[];
    for (final para in paragraphs)
    {
      paraList.add(para.toJson(compress));
    }

    final links = <String, dynamic>{};

    for (final link in namedLinks.entries)
    {
      links[link.key.toString()] = link.value.toJson(compress);
    }

    final result = <String, dynamic>{};

    if (!compress || paraList.isNotEmpty)
    {
      result['para'] = paraList;
    }

    if (!compress || links.isNotEmpty)
    {
      result['links'] = links;
    }

    return result;
  }

  Markdown.fromJson(dynamic json)
  {
    final paraList = json['para'];
    if (paraList is List)
    {
      for (final para in paraList)
      {
        paragraphs.add(MarkdownParagraph.fromJson(para));
      }
    }

    final links = json['links'];
    if (links is Map)
    {
      for (final link in links.entries)
      {
        namedLinks[link.key.toString()] = MarkdownWord.fromJson(link.value);
      }
    }
  }
}

class MarkdownParagraph
{
  // TODO nevyuziva se
//MarkdownParagraphType type = MarkdownParagraphType.normalParagraph;
  String lineDecoration = '';
  MarkdownListIndentation? listIndent;
  String masterClass;
  String subClass;
  final anchors = <String>[];
  final _words = <MarkdownWord>[];
  final attributes = <String, String>{};
  bool lastInClass = true;
  bool firstInClass = true;
  int blockquoteLevel = 0;

  MarkdownParagraph({required String text, this.lineDecoration = '', pargraphClass = ''})
  : masterClass = pargraphClass.isEmpty ? 'p' : pargraphClass,
  subClass = ''
  {
    writeText(text);
  }

  // TODO nevyuziva se
  /*MarkdownParagraph.referenceLink(String linkName, String linkUrl)
  : type = MarkdownParagraphType.linkReferece,
  masterClass = linkName,
  subclass = linkUrl;*/

  ///
  //String get linkName => masterClass;

  ///
  //String get linkUrl => subclass;

  MarkdownWord operator [](int index)
  {
    return _words[index];
  }

  Iterable<MarkdownWord> get words
  {
    return _words;
  }

  String fullClassName([MarkdownWord? word, bool bullet = false, bool link = false])
  {
    final builder = StringBuffer(masterClass);

    if (subClass.isNotEmpty)
    {
      builder.write('.');
      builder.write(subClass);
    }

    if (word?.style.isNotEmpty ?? false)
    {
      builder.write('.');
      builder.write(word?.style);
    }

    if (bullet)
    {
      builder.write('.\u2022');
    }
    else
    {
      switch (word?.script)
      {
        case MarkdownScript.subscript:
        builder.write('~');
        break;

        case MarkdownScript.superscript:
        builder.write('^');
        break;

        default:
        break;
      }
      switch (word?.decoration)
      {
        case MarkdownDecoration.striketrough:
        builder.write('-');
        break;

        case MarkdownDecoration.underline:
        builder.write('_');
        break;

        default:
        break;
      }
      if (link)
      {
        builder.write('@');
      }
    }

    return builder.toString();
  }

  ///
  /// Zmena znaku uvozenych \ za znaky 0xE000+\<ASCII kod znaku\>
  ///
  /// Zamenuji se pouze ASCII interpukcni znaky znaky < 0x80 (ne pismena a cislice)
  ///
  static String escape(String text)
  {
    if (!_escapeCharRegExp.hasMatch(text))
    {
      // Netreba escapovat
      return text;
    }
    else
    {
      // Provedeni escape sekvenci
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

  /// Zamena escapovannych znaku 0xE0## na jejich puvodni ASCII kod.
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
    final builder = StringBuffer('Paragraph:  ');

    builder.write("start='$lineDecoration' class='$masterClass' '$subClass'\r\n");
    var label = false;

    if (listIndent != null)
    {
      builder.write('Decorations: $listIndent\r\n');
      builder.write('\r\n');
      label = _words.isNotEmpty;
    }

    if (anchors.isNotEmpty)
    {
      builder.write('Anchors:');
      for (final dec in anchors)
      {
        builder.write(' ${dec.toString()}');
      }
      builder.write('\r\n');
      label = _words.isNotEmpty;
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

    for (int i = 0; i < _words.length; i++)
    {
      final word = _words[i].toString();
      builder.write('  $i: $word\r\n');
    }
    return builder.toString();
  }

  MarkdownWord makeWord(String text, _StyleStack styleStack,
    {MarkdownWord_Type type = MarkdownWord_Type.word, bool stickToNext = false, Map<String, String?>? attr})
  {
    final result = MarkdownWord()
    ..type = type
    ..text = MarkdownParagraph.unescape(text)
    ..style = styleStack.currentStyle
    ..script = styleStack.script
    ..decoration = styleStack.decoration
    ..stickToNext = stickToNext;

    if (attr != null)
    {
      for (var element in attr.entries)
      {
        result.attribs[MarkdownParagraph.unescape(element.key)] =
        element.value != null ? MarkdownParagraph.unescape(element.value!) : null;
      }
    }

    return result;
  }

  /// Zapis slova do seznamu [_words]
  /// - Zapisuje text z [wordBuffer]
  /// - Pokud je wordBuffer prazdny nezpisuje nic
  /// - [wordBuffer] - Text slova
  /// - [styleStack] - Stack stylu znaku (*, **, _, __ apod)
  /// - [stickToNext] - Prilepit k nasledujicimu slovu (bez mezery)
  void writeWord(StringBuffer wordBuffer, _StyleStack styleStack, bool stickToNext)
  {
    if (wordBuffer.isNotEmpty)
    {
      add
      (
        MarkdownWord()
        ..text = MarkdownParagraph.unescape(wordBuffer.toString())
        ..style = styleStack.currentStyle
        ..script = styleStack.script
        ..decoration = styleStack.decoration
        ..stickToNext = stickToNext
      );
      wordBuffer.clear();
    }
  }

  ///
  /// Zapis textu do odstavce
  /// - Vytvari slova
  /// - Vytvari i specialni slova jako linky a obrazky
  ///
  writeText(String text)
  {
    const MATCH_NONE = 0;
    const LONG_LINK = 1;
    const SHORT_LINK = 2;
    const ID_IMAGE = 3;
    const EMAIL_LINK = 4;
    const URL_LINK = 5;
    const ATTRIBUTE = 6;

    final wordBuffer = StringBuffer();
    final styleStack = _StyleStack();
    int readIndex = 0;
    final List<Match?> lineMatches = List.filled(text.length, null);
    final List<int> lineMatchType = List.filled(text.length, MATCH_NONE);

    // Nalezeni vsech vzorcu v odstavci
    for
    (
      final matchInfo in
      [
        Tuple2(SHORT_LINK, _shortLinkRegExp),
        Tuple2(ID_IMAGE, _idImageRegExp),
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

    // Zpracovani vsech znaku
    do
    {
      final ch = charAt(text, readIndex);
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

            final word = linkWordsFromMatch(match, styleStack);
            word.stickToNext = charAt(text, match.end) != ' ';
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
                word.attribs['alt'] = MarkdownParagraph.unescape(name);
              }
              else
              {
                word = makeWord(name, styleStack, type: MarkdownWord_Type.link);
              }

              word.stickToNext = charAt(text, match.end) != ' ';
              add(word);
            }
          }
          break;

          case ID_IMAGE:
          {
            final match = lineMatches[readIndex]!;
            MarkdownWord? word;

            if (match.groupCount >= 2)
            {
              final altText = match.group(1) ?? '';
              final id = match.group(2) ?? '!';

              word = makeWord(id, styleStack, type: MarkdownWord_Type.image);
              word.attribs['alt'] = MarkdownParagraph.unescape(altText);

              word.stickToNext = charAt(text, match.end) != ' ';
              add(word);
            }
          }
          break;

          case EMAIL_LINK:
          case URL_LINK:
          {
            final match = lineMatches[readIndex]!;
            final text = match[2] ?? '';
            final MarkdownWord word;

            if (match[1] == '`' && match[3] == '`')
            {
              word = makeWord(text, styleStack);
            }
            else
            {
              word = makeWord(text, styleStack, type: MarkdownWord_Type.link, attr: {'link': text});
            }

            word.stickToNext = charAt(text, match.end) != ' ';
            add(word);
          }
          break;

          case ATTRIBUTE:
          {
            final match = lineMatches[readIndex]!;
            if (match.groupCount >= 2)
            {
              final type = match.group(1) ?? '';
              final text = unescape(match.group(2) ?? '');
              switch (type)
              {
                case '.':
                subClass = text;
                break;

                case '#':
                anchors.add(text);
                break;

                case '*':
                {
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
                break;
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
              {
                writeWord(wordBuffer, styleStack, false);
                readIndex++;
              }
              break;

              case '\n': // Novy radek
              {
                writeWord(wordBuffer, styleStack, false);
                add(MarkdownWord.newLine());
                readIndex++;
              }
              break;

              case '~':
              {
                writeWord(wordBuffer, styleStack, !text.hasSpaceAtIndex(readIndex + 1));
                if (charAt(text, readIndex + 1) == '~')
                {
                  if (charAt(text, readIndex + 2) == '~')
                  {
                    styleStack.decoration = (styleStack.decoration == MarkdownDecoration.underline)
                    ? MarkdownDecoration.none
                    : MarkdownDecoration.underline;
                    readIndex += 3;
                  }
                  else
                  {
                    styleStack.decoration = (styleStack.decoration == MarkdownDecoration.striketrough)
                    ? MarkdownDecoration.none
                    : MarkdownDecoration.striketrough;
                    readIndex += 2;
                  }
                }
                else
                {
                  styleStack.script = (styleStack.script == MarkdownScript.subscript)
                  ? MarkdownScript.normal
                  : MarkdownScript.subscript;
                  readIndex++;
                }
              }
              break;

              case '^':
              {
                writeWord(wordBuffer, styleStack, !text.hasSpaceAtIndex(readIndex + 1));
                styleStack.script = (styleStack.script == MarkdownScript.superscript)
                ? MarkdownScript.normal
                : MarkdownScript.superscript;
                readIndex++;
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

                  if (styleStack.stack.isNotEmpty && compareClass(styleStack.stack.last, mValue))
                  {
                    // konec stylu
                    final ch = charAt(text, readIndex);
                    writeWord(wordBuffer, styleStack, ch != ' ' && ch != '');
                    styleStack.stack.removeLast();
                  }
                  else
                  {
                    // zacatek stylu
                    writeWord(wordBuffer, styleStack, true);
                    styleStack.stack.add(matchVal(match));
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

  static String matchVal(Match? match)
  {
    //return match?.input.substring(match.start, match.end) ?? '';
    return match?.group(0) ?? '';
  }

  static bool compareClass(String push, String pop)
  {
    return (push == pop) || (push == pop.swap()) || (pop == '```' && push.startsWith('```.'));
  }

  static String charAt(String text, int index)
  {
    return (index < 0 || index >= text.length) ? '' : text[index];
  }

  void copyWords(MarkdownParagraph src)
  {
    for (var word in src._words)
    {
      add(word);
    }
  }

  /// Seznam slov vztahujicich se k jednomu nalezenemu linku pro obrazek uklada jendine slovo
  MarkdownWord linkWordsFromMatch(Match match, _StyleStack styleStack)
  {
    final MarkdownWord result;

    if (match[LinkPattern.GR_EXCLAMATION] == '!')
    {
      result = MarkdownWord.fromMatch(match, styleStack);
      add(result);
    }
    else
    {
      final descWords = (match[LinkPattern.GR_ALT] ?? '').split(_spacesRegEx);
      if (descWords.isEmpty)
      {
        descWords.add(match[LinkPattern.GR_LINK] ?? match[LinkPattern.GR_URL] ?? 'link');
      }

      for (var i = 0; i < descWords.length; i++)
      {
        bool stick = (i + 1) < descWords.length;
        final strWord = descWords[i] + (stick ? ' ' : '');
        final word = MarkdownWord.fromMatch(match, styleStack, text: strWord);
        word.stickToNext = stick;
        add(word);
      }

      result = _words.last;
    }

    return result;
  }

  bool get isBlankLine => masterClass == 'p' && _words.isEmpty;

  bool get isEmpty => _words.isEmpty;

  bool get isNotEmpty => _words.isNotEmpty;

  remove(MarkdownWord word) => _words.remove(word);

  removeAll(Iterable<MarkdownWord> removeList)
  {
    for (var word in removeList)
    {
      _words.remove(word);
    }
  }

  add(MarkdownWord word)
  {
    MarkdownWord prev;
    if
    (
      _words.isNotEmpty &&
      (prev = _words.last).decoration != MarkdownDecoration.none &&
      prev.decoration == word.decoration
    )
    {
      prev.text += ' ' + word.text;
    }
    else
    {
      _words.add(word);
    }
  }

  dynamic toJson([bool compress = false])
  {
    final result = <String, dynamic>
    {
      'class': masterClass,
    };

    if (!compress || subClass.isNotEmpty)
    {
      result['subClass'] = subClass;
    }

    if (!compress || _words.isNotEmpty)
    {
      final words = <dynamic>[];

      for (final word in _words)
      {
        words.add(word.toJson(compress));
      }

      result['words'] = words;
    }

    if (!compress || anchors.isNotEmpty)
    {
      result['anchors'] = anchors;
    }

    if (!compress || attributes.isNotEmpty)
    {
      result['attributes'] = attributes;
    }

    if (!compress || !firstInClass)
    {
      result['firstInClass'] = firstInClass;
    }

    if (!compress || !lastInClass)
    {
      result['lastInClass'] = lastInClass;
    }

    if (!compress || lineDecoration != '')
    {
      result['lineDecoration'] = lineDecoration;
    }

    if (!compress || blockquoteLevel > 0)
    {
      result['blockquoteLevel'] = blockquoteLevel;
    }

    if (!compress || listIndent != null)
    {
      result['listIndent'] = listIndent?.toJson();
    }

    return result;
  }

  MarkdownParagraph.fromJson(dynamic json)
  : masterClass = JsonUtils.getValue(json, 'class', ''),
  subClass = JsonUtils.getValue(json, 'subClass', '')
  {
    final jsonWords = json['words'];
    if (jsonWords != null)
    {
      for (final jsonWord in jsonWords)
      {
        _words.add(MarkdownWord.fromJson(jsonWord));
      }
    }

    final jsonAnchors = json['anchors'];
    if (jsonAnchors != null)
    {
      for (final jsonAnchor in jsonAnchors)
      {
        anchors.add(jsonAnchor.toString());
      }
    }

    final jsonAttributes = json['attributes'];
    if (jsonAttributes is Map)
    {
      for (final jsonAttrribute in jsonAttributes.entries)
      {
        attributes[jsonAttrribute.key.toString()] = jsonAttrribute.value.toString();
      }
    }

    firstInClass = JsonUtils.getValue(json, 'firstInClass', true);
    lastInClass = JsonUtils.getValue(json, 'lastInClass', true);
    lineDecoration = JsonUtils.getValue(json, 'lineDecoration', '');
    blockquoteLevel = JsonUtils.getValue(json, 'blockquoteLevel', 0);

    final jsonIntent = json['listIndent'];
    if (jsonIntent != null)
    {
      listIndent = MarkdownListIndentation.fromJson(jsonIntent);
    }
  }
}

enum MarkdownParagraphType { normalParagraph, linkReferece }

class MarkdownListIndentation
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

  MarkdownListIndentation(String decor, this.column)
  {
    int ch = decor.codeUnitAt(column);
    if (ch >= /*$a*/(0x61) && ch <= /*$z*/(0x7A))
    {
      decor = 'a';
    }
    else if (ch >= /*$A*/(0x41) && ch <= /*$Z*/(0x5A))
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
    else if (ch == /*$>*/(0x3E))
    {
      decor = '>';
    }
    else
    {
      decor = decor.substring(column, column + 1);
      //decor = decor.trim();
    }

    decoration = decor;
  }

  static bool compareModify(MarkdownListIndentation? current, MarkdownListIndentation? prev)
  {
    if (current == null || prev == null)
    {
      return true;
    }
    else
    {
      ////
      final c = current;
      final p = prev;

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

      ///

    }

    return true;
  }

  static void create(List<MarkdownParagraph> para)
  {
    for (int index = 1; index < para.length; index++)
    {
      final cur = para[index];

      var prev = index - 1;
      while (prev >= 0 && !compareModify(cur.listIndent, para[prev].listIndent))
      {
        prev--;
      }
    }
  }

  static MarkdownListIndentation? fromText(String text)
  {
    final MarkdownListIndentation? result;

    final matches = _headRegExp.allMatches(text);
    if (matches.length > 0)
    {
      result = MarkdownListIndentation(text, matches.last.start);
    }
    else
    {
      result = null;
    }

    return result;
  }

  static int blockque(String lineDecoration)
  {
    var result = 0;
    for (var ch in lineDecoration.codeUnits)
    {
      if (ch == /*$>*/(0x3E))
      {
        result++;
      }
    }
    return result;
  }

  dynamic toJson()
  {
    final result = <String, dynamic>{'decoration': decoration, 'level': level, 'column': column, 'count': count};

    return result;
  }

  MarkdownListIndentation.fromJson(dynamic json)
  {
    decoration = JsonUtils.getValue(json, 'decoration', decoration);
    level = JsonUtils.getValue(json, 'level', level);
    column = JsonUtils.getValue(json, 'column', column);
    count = JsonUtils.getValue(json, 'count', count);
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
  MarkdownScript script = MarkdownScript.normal;
  MarkdownDecoration decoration = MarkdownDecoration.none;

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
      attribs[attrib] = MarkdownParagraph.unescape(data);
    }
  }

  ///
  /// Vytvari image, nebo link pomoci vysledku hledani vzoru LinkPattern
  ///
  factory MarkdownWord.fromMatch(Match match, _StyleStack styleStack, {String? text})
  {
    final result = MarkdownWord()
    ..type = (match[LinkPattern.GR_EXCLAMATION] == '!') ? MarkdownWord_Type.image : MarkdownWord_Type.link
    ..style = styleStack.currentStyle
    ..script = styleStack.script
    ..decoration = styleStack.decoration;

    result.text = MarkdownParagraph.unescape(text ?? match[LinkPattern.GR_ALT] ?? '');
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
      result._matchAttrib('link', match, LinkPattern.GR_URL);
      result._matchAttrib('link', match, LinkPattern.GR_LINK);
      //result._matchAttrib('image', match, LinkPattern.GR_LINK);
    }

    return result;
  }

  @override
  String toString()
  {
    final s = stickToNext ? '+' : ' ';
    final t = lineBreak ? '<break>' : text;

    final builder = StringBuffer
    (
      "[$style]$s '$t' ${enum_ToString(script.toString())} ${enum_ToString(decoration.toString())} ${enum_ToString(type.toString())}"
    );

    for (final attr in attribs.entries)
    {
      builder.write(' ${attr.key}=${attr.value ?? "(null)"}');
    }

    return builder.toString();
  }

  dynamic toJson([bool compress = false])
  {
    final result = <String, dynamic>{};
    if (!compress || type != MarkdownWord_Type.word)
    {
      result['type'] = enum_ToString(type);
    }

    if (!compress || decoration != MarkdownDecoration.none)
    {
      result['decoration'] = enum_ToString(decoration);
    }

    if (!compress || script != MarkdownScript.normal)
    {
      result['script'] = enum_ToString(script);
    }

    if (!compress || style.isNotEmpty)
    {
      result['style'] = style;
    }

    if (!compress || text.isNotEmpty)
    {
      result['text'] = text;
    }

    if (!compress || stickToNext)
    {
      result['stickToNext'] = stickToNext;
    }

    if (!compress || lineBreak)
    {
      result['lineBreak'] = lineBreak;
    }

    if (!compress || attribs.isNotEmpty)
    {
      result['attribs'] = attribs;
    }

    return result;
  }

  MarkdownWord.fromJson(dynamic json)
  {
    const typeMap =
    {
      'word': MarkdownWord_Type.word,
      'link': MarkdownWord_Type.link,
      'image': MarkdownWord_Type.image,
      'link_image': MarkdownWord_Type.link_image,
      'reference_definition': MarkdownWord_Type.reference_definition
    };

    const decorMap =
    {
      'none': MarkdownDecoration.none,
      'striketrough': MarkdownDecoration.striketrough,
      'underline': MarkdownDecoration.underline
    };

    const scriptMap =
    {
      'normal': MarkdownScript.normal,
      'subscript': MarkdownScript.subscript,
      'superscript': MarkdownScript.superscript
    };

    type = JsonUtils.getEnum(json, 'type', typeMap, type);
    decoration = JsonUtils.getEnum(json, 'decoration', decorMap, decoration);
    script = JsonUtils.getEnum(json, 'script', scriptMap, script);
    style = JsonUtils.getValue(json, 'style', style);
    text = JsonUtils.getValue(json, 'text', text);
    stickToNext = JsonUtils.getValue(json, 'stickToNext', stickToNext);
    lineBreak = JsonUtils.getValue(json, 'lineBreak', lineBreak);

    final jsonAttribs = json['attribs'];
    if (jsonAttribs is Map)
    {
      for (final jsonAttrib in jsonAttribs.entries)
      {
        attribs[jsonAttrib.key.toString()] = jsonAttrib.value?.toString();
      }
    }
  }
}

enum MarkdownWord_Type { word, link, image, link_image, reference_definition }

class _StyleStack
{
  static final empty = _StyleStack();
  final stack = <String>[];
  var script = MarkdownScript.normal;
  var decoration = MarkdownDecoration.none;

  String get currentStyle
  {
    if (stack.isEmpty)
    {
      return '';
    }
    else
    {
      final style = stack.last;

      if (style.startsWith('```.'))
      {
        return style.substring(4);
      }
      else
      {
        return stack.last;
      }
    }
  }
}

enum MarkdownScript { normal, subscript, superscript }
enum MarkdownDecoration { none, striketrough, underline }