import 'package:doc_reader/doc_reader.dart';
import 'package:doc_reader/doc_span/basic/basic_text_span.dart';
import 'doc_span/color_text.dart';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/document.dart';
import 'package:doc_reader/markdown/markdown.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:flutter/material.dart';
import 'package:doc_reader/objects/applog.dart';
import 'doc_touch.dart';
import 'markdown/markdown_text_span.dart';

const testMarkdown = r'''![toto je popis](https://d62-a.sdn.cz/d_62/c_img_gU_g/xuRBp/0-uvod.jpeg)
- xxx
   - yyyy
       - zzzz

První *italic* _italic_ **bold** __bold__ ***italic\ bold*** ___italic\ bold___
# Toto je nadpis 1
## Toto je nadpis 2
### Toto je nadpis 3
#### Toto je nadpis 4
##### Toto je nadpis 5
###### Toto je nadpis 6
Toto je běžný odstavec který se bude muset zalomit protože je příliš dlouhý aby se vešel na displej. Podruhé, toto je  běžný odstavec který se bude muset zalomit protože je příliš dlouhý aby se vešel na displej.
''';

void testColor(String text)
{
  print('${text.padRight(24)} ${colorFormText(text)}');
}

void main()
{
  testColor('yellow green');
  testColor('My Pink');
  registerColorName('my piNk', 0xFFE91E63);
  testColor('yellow green');
  testColor('My Pink');
  testColor('#ABC');
  testColor('#Abc');
  testColor('#1789');
  testColor('#17891');
  testColor('#2A3C4F');
  testColor('#30FFA7B3');
  testColor('#FF00FF00');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({Key? key}) : super(key: key);

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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget
{
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

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

    final document = Document();
    binder.setProperty(documentProperty, document);

    /*for (int i = 1; i < 1000000; i++)
    {
      document.docSpans.add(DocumentSpanContainer(BasicTextSpan
          (
            ':${i.toString().padLeft(5, '0')}: skkkc sdksdsdksd fdfdfkl dfldf asdsaaskl xcnxcxmbc nsdswdesdbn jksdsdjksdjk jkdssdjksdjk jksdsdjksdjk dflk ddfdf kdfkl dkdk dskdkd dskdkd dfkldf dfdfdfl dfdfdfl :$i:'
          )));
    }*/

    final md = Markdown();
    md.writeMarkdownString(testMarkdown);
    final cfg = MarkdownTextConfig();
    final ms = MarkdownTextSpan.create(md, cfg);
    for (final s in ms)
    {
      document.docSpans.add(DocumentSpanContainer(s));
    }
    return binder;
  }
}