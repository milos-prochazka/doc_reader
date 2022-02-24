import 'dart:async';

import 'package:doc_reader/doc_menu.dart';

import 'default_config.dart';
import 'doc_tbl_contents.dart';
import 'objects/applog.dart';
import 'objects/config.dart';
import 'objects/json_utils.dart';
import 'objects/utils.dart';
import 'top_button/top_buttons.dart';
import 'top_button/topbutton.dart';

import 'markdown/markdown_text_config.dart';
import 'objects/asset_text_load.dart';
import 'document.dart';
import 'markdown/markdown.dart';
import 'property_binder.dart';
import 'package:flutter/material.dart';
import 'doc_touch.dart';
import 'markdown/markdown_text_span.dart';

void main() async
{
  runZonedGuarded
  (
    () async
    {
      WidgetsFlutterBinding.ensureInitialized(); //<= the key is here
      FlutterError.onError = (FlutterErrorDetails errorDetails)
      {
        appLogEx(errorDetails.exception, msg: 'FLUTTER ERROR', stackTrace: errorDetails.stack);
      };

      await initConfig();
      runApp(MyApp()); // starting point of app
    }, (ex, stackTrace)
    {
      appLogEx(ex, msg: 'UNHANDLED EXCEPTION', stackTrace: stackTrace);
    }
  );
}

initConfig() async
{
  var cfg = Config.instance;
  cfg.data = setDynamic(cfg.data, defaultAppConfig);

  if (!await cfg.load())
  {
    // default
  }

  await cfg.save(true);
  var brk = 1;
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
  //TopButtons? topButtons;
  final menu = DocMenu();

  @override
  Widget build(BuildContext buildContext)
  {
    widget.document.onReload = (document) => setState(() {});

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
          body: Center(child: _buildBody(context)),
        );
      }
    );

    binder.setProperty(Document.documentProperty, widget.document);

    /*for (int i = 1; i < 1000000; i++)
    {
      document.docSpans.add(DocumentSpanContainer(BasicTextSpan
          (
            ':${i.toString().padLeft(5, '0')}: skkkc sdksdsdksd fdfdfkl dfldf asdsaaskl xcnxcxmbc nsdswdesdbn jksdsdjksdjk jkdssdjksdjk jksdsdjksdjk dflk ddfdf kdfkl dkdk dskdkd dskdkd dfkldf dfdfdfl dfdfdfl :$i:'
          )));
    }*/

    return binder;
  }

  Widget _buildBody(BuildContext context)
  {
    final document = Document.of(context);

    var children = [DocTouch.build(context: context, documentProperty: Document.documentProperty)];

    switch (document.mode)
    {
      case DocumentShowMode.content:
        {
          children.add(const DocTableContents());
        }
        break;

      case DocumentShowMode.menu:
        {
          children.add(menu.build(context));
        }
        break;

      default:
        break;
    }

    return Stack(children: children);
  }
}