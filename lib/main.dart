import 'dart:async';

import 'objects/applog.dart';
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
  TopButtons? topButtons;

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
          body: Center(child: _buildBody(context)),
        );
      }
    );

    binder.setProperty(documentProperty, widget.document);
    widget.document.onShowMenu = showMenu;

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
    return Stack
    (
      children: [DocTouch.build(context: context, documentProperty: documentProperty), _buildButtons(context)]
    );
  }

  showMenu(Document document)
  {
    ///
    topButtons?.control.visible = !(topButtons?.control.visible ?? true);
  }

  Widget _buildButtons(BuildContext context)
  {
    final result = TopButtons
    (
      [
        TopButtonItem
        (
          type: TopButtonType.top,
          builder: (c, i)
          {
            return TopButton();
          }
        ),
        TopButton.createItem(id: 'a', type: TopButtonType.top, relativeWidth: 1, text: 'Tlac 2'),
        TopButton.createItem(id: 'b', type: TopButtonType.bottom, relativeWidth: 1, text: 'Tlac B1'),
        TopButton.createItem(id: 'c', type: TopButtonType.bottom, relativeWidth: 1, text: 'Tlac B2'),
        TopButton.createItem(id: 'd', type: TopButtonType.bottom, relativeWidth: 1, text: 'Tlac B3'),
      ],
      backgroundColor: Color.fromARGB(0xcc, 0x20, 0x40, 0x40),
      foregroundColor: Colors.white70,
      event: (param)
      {
        PropertyBinder.doOnProperty
        (
          context, 'cnt', (binder, property)
          {
            var cnt = property.valueT(0.0);
            property.setValue(binder, cnt + 1);
          }
        );
        topButtons?.control.visible = false;

        /*var i = param.cmdType;
                PropertyBinder.doOn
                (
                  context, (binder)
                  {
                    var c = binder.getProperty('cnt', 0.0);
                    binder.setProperty('cnt', c + 1.0);
                  }
                );*/
      },
    );

    topButtons = result;
    return result;
  }
}