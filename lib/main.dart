import 'package:doc_reader/doc_reader.dart';
import 'package:doc_reader/doc_span/basic/basic_text_span.dart';
import 'package:doc_reader/objects/utils.dart';
import 'doc_span/color_text.dart';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/document.dart';
import 'package:doc_reader/markdown/markdown.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:flutter/material.dart';
import 'package:doc_reader/objects/applog.dart';
import 'doc_touch.dart';
import 'markdown/markdown_text_span.dart';

// **![toto je popis obrázku](media/pngegg.png)**
const testMarkdown = r'''
# Nadpis
> odsazeno 1
> odsazeno 2
''';
const test = r'''
a**h**oj ![toto je popis obrázku](media/vector.svg = 5em x  tight-center-line) aasjkaskjasas jakokoles mikrosek jarosek marosek doloker
Dlouhy odstacec na zacatku textu. Dlouhy odstacec na zacatku textu. Dlouhy odstavec na zacatku textu.
[.myclass]: width=10em height=50em
## ZACATEK {.trida} {#kotva} {*aaa=123} {*bbb} {*aja = paja }
\* a\*\aaaa
![KOLOKOL]

[KOLOKOL]: media/vector.svg = 5em x  tight-line



------------------------------

  Jakamarus
  ---------

 ***************
A. fkfkff
B. keddjdjd
C. dskdkdsjds
D. xxx

--------------------
- dddkddkdk
   1. yyyy
       A. zzzz
       A. dkkdd
       A. ddskdsksd
    2. kdkdsdkdkdfk
    1. treti
1. kdkdfkfd

První *italic* _italic_ **bold** __bold__ ***italic\ bold*** ___italic\ bold___
# Toto je nadpis 1  ![c](media/vector.svg =  x 1em  left)
## Toto je nadpis 2 ![c](media/vector.svg =  x 1em left)
### Toto je nadpis 3 ![c](media/vector.svg =  x 1em left)
#### Toto je nadpis 4 ![c](media/vector.svg =  x 1em left)
##### Toto je nadpis 5 ![c](media/vector.svg =  x 1em left)
###### Toto je nadpis 6 ![c](media/vector.svg =  x 1em left)
  [aaaaaa]: (wwww.sss.cz)
Toto jojo@email.cz je běžný odstavec který se bude muset zalomit protože je příliš dlouhý aby se vešel na displej. Podruhé, toto je  běžný odstavec který se bude muset zalomit protože je příliš dlouhý aby se vešel na displej.
Pokračování odstavce za přechodem na nový řádek

Další odstavec
''';

void testColor(String text)
{
  print('${text.padRight(24)} ${colorFormText(text)}');
}

void main()
{
  appLog("Testovaci log");
  runApp(MyApp());
}

class MyApp extends StatelessWidget
{
  late Markdown markdown;
  late MarkdownTextConfig textConfig;
  late Document document;

  MyApp({Key? key}) : super(key: key)
  {
    document = Document();
    markdown = Markdown();
    markdown.writeMarkdownString(testMarkdown);
    textConfig = MarkdownTextConfig();
    print(markdown.toString());

    final ms = MarkdownTextSpan.create(markdown, textConfig, document);
    for (final s in ms)
    {
      document.docSpans.add(DocumentSpanContainer(s));
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context)
  {
    return MaterialApp
    (
      title: 'Flutter Demo',
      theme: ThemeData
      (
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', document: document),
    );
  }
}

class MyHomePage extends StatefulWidget
{
  const MyHomePage({Key? key, required this.title, required this.document}) : super(key: key);

  final String title;
  final Document document;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
{
  static const documentProperty = 'document';

  @override
  Widget build(BuildContext buildContext)
  {
    final binder = PropertyBinder
    (
      context: context,
      builder: (context)
      {
        return Scaffold
        (
          appBar: AppBar
          (
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text(widget.title),
          ),
          body: Center
          (
            child: DocTouch.build(context: context, documentProperty: documentProperty),
          ),
        );
      }
    );

    binder.setProperty(documentProperty, widget.document);

    /*for (int i = 1; i < 1000000; i++)
    {
      document.docSpans.add(DocumentSpanContainer(BasicTextSpan
          (
            ':${i.toString().padLeft(5, '0')}: skkkc sdksdsdksd fdfdfkl dfldf asdsaaskl xcnxcxmbc nsdswdesdbn jksdsdjksdjk jkdssdjksdjk jksdsdjksdjk dflk ddfdf kdfkl dkdk dskdkd dskdkd dfkldf dfdfdfl dfdfdfl :$i:'
          )));
    }*/

    return binder;
  }
}