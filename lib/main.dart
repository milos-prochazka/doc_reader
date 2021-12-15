import 'package:doc_reader/doc_reader.dart';
import 'package:doc_reader/doc_span/basic/basic_text_span.dart';
import 'package:doc_reader/markdown/patterns.dart';
import 'package:doc_reader/markdown/value_unit.dart';
import 'package:doc_reader/objects/asset_text_load.dart';
import 'package:doc_reader/objects/utils.dart';
import 'package:flutter/services.dart';
import 'doc_span/color_text.dart';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/document.dart';
import 'package:doc_reader/markdown/markdown.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:flutter/material.dart';
import 'package:doc_reader/objects/applog.dart';
import 'doc_touch.dart';
import 'markdown/markdown_text_span.dart';

void main()
{
  /*final sp = StringPattern();

  final patt = LinkPattern(LinkPattern.TYPE_LINK);
  var match = patt.firstMatch(r'''[kokolex](fff.jpg "doplkovy popis" "voice"  10.34em x 76.5% left .myclass)''');
  final word= MarkdownWord.fromMatch(match!);
  print(word.toString());*/

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
    textConfig = MarkdownTextConfig();
    document.config = textConfig;
    document.onOpenFile = MarkdownTextSpan.fileOpen;
    document.onOpenFileConfig = AssetLoadTextLoad();
    Future.microtask
    (
      () async
      {
        await document.openFile('media/test-mini.md');
      }
    );
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