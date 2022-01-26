import 'dart:async';

import 'package:doc_reader/objects/applog.dart';
import 'package:doc_reader/objects/speech.dart';
import 'package:yaml/yaml.dart';

import 'markdown/markdown_text_config.dart';
import 'objects/asset_text_load.dart';
import 'document.dart';
import 'markdown/markdown.dart';
import 'property_binder.dart';
import 'package:flutter/material.dart';
import 'doc_touch.dart';
import 'markdown/markdown_text_span.dart';

void main()
{
  runZonedGuarded
  (
    ()
    {
      WidgetsFlutterBinding.ensureInitialized(); //<= the key is here
      FlutterError.onError = (FlutterErrorDetails errorDetails)
      {
        appLogEx(errorDetails.exception, msg: 'FLUTTER ERROR', stackTrace: errorDetails.stack);
      };
      runApp(MyApp()); // starting point of app
    }, (ex, stackTrace)
    {
      appLogEx(ex, msg: 'UNHANDLED EXCEPTION', stackTrace: stackTrace);
    }
  );
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
          body: Center(child: DocTouch.build(context: context, documentProperty: documentProperty)),
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