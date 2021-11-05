import 'package:doc_reader/doc_reader.dart';
import 'package:doc_reader/doc_span/basic/basic_text_span.dart';
import 'package:doc_reader/doc_span/doc_span_interface.dart';
import 'package:doc_reader/document.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:flutter/material.dart';

void main()
{
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
            child: DocReader(documentProperty: documentProperty),
          ),
        );
      }
    );

    final document = Document();
    binder.setProperty(documentProperty, document);

    for (int i = 1; i < 1000000; i++)
    {
      document.docSpans.add(DocumentSpanContainer(BasicTextSpan
          (
            ':${i.toString().padLeft(5, '0')}: skkkc sdksdsdksd fdfdfkl dfldfdflk ddfdf kdfkldfkldf dfdfdfl dfdfdfl :$i:'
          )));
    }

    return binder;
  }
}