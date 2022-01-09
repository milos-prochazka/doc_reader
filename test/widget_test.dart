// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';

import 'package:doc_reader/objects/json_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:doc_reader/main.dart';

testCbjCompare(String title, dynamic data)
{
  final json1 = jsonEncode(data);
  final cbj = DBJ.encode(data, dictionaryCountTreshold: 1);
  final data1 = DBJ.decode(cbj);
  final json2 = jsonEncode(data1);

  print('TEST:$title');
  expect(json2, json1, reason: title);
}

cbjTestBasic()
{
  testCbjCompare('null', null);
  testCbjCompare('100', 100);
  testCbjCompare('-100', -100);
  testCbjCompare('0x1234567', 0x1234567);
  testCbjCompare('-0x1234567', -0x1234567);
  testCbjCompare('3.1415926', 3.1415926);

  testCbjCompare('["a","a","a","a","a","a"]', ['a', 'a', 'a', 'a', 'a', 'a']);
  final buff = StringBuffer();
  for (var i = 0; i < 47; i++) buff.writeCharCode(i + 48);
  testCbjCompare('["<string 47>","<string 47>","<string 47>",]', [buff.toString(), buff.toString(), buff.toString()]);
  buff.write('x');
  testCbjCompare('["<string 48>","<string 48>","<string 48>",]', [buff.toString(), buff.toString(), buff.toString()]);
  while (buff.length < 255) buff.writeCharCode(buff.length % 64 + 48);
  testCbjCompare
  (
    '["<string 255>","<string 255>","<string 255>",]', [buff.toString(), buff.toString(), buff.toString()]
  );
  buff.write('h');
  testCbjCompare
  (
    '["<string 256>","<string 256>","<string 256>",]', [buff.toString(), buff.toString(), buff.toString()]
  );
  while (buff.length < 70000) buff.writeCharCode(buff.length % 64 + 48);
  testCbjCompare
  (
    '["<string 70000>","<string 70000>","<string 70000>",]', [buff.toString(), buff.toString(), buff.toString()]
  );
  buff.clear();
  while (buff.length < 30000) buff.writeCharCode(buff.length + 48);
  testCbjCompare('["<string unicode>","<string unicode>","<string unicode>",]',
    [buff.toString(), buff.toString(), buff.toString()]);

  final map = <String, dynamic>{};
  while (map.length < 40000)
  {
    final index = map.length;

    map['Index$index'] = 'Text$index';
  }
  testCbjCompare('big map', [map, map, map, map]);

  final list = <dynamic>[];
  while (list.length < 1000000)
  {
    list.add(list.length);
    list.add(list.length < 30000);
    list.add(null);
    list.add(3.123 * list.length);
    list.add('Testovaci text cislo ${list.length}');
  }
  testCbjCompare('big list', list);
}

void main()
{
  //cbjTestBasic();

  testWidgets
  (
    'CBJ test basic', (WidgetTester tester) async
    {
      cbjTestBasic();
      /*// Build our app and trigger a frame.
      await tester.pumpWidget(MyApp());

      // Verify that our counter starts at 0.
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsNothing);

      // Tap the '+' icon and trigger a frame.
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      // Verify that our counter has incremented.
      expect(find.text('0'), findsNothing);
      expect(find.text('1'), findsOneWidget);*/
    }
  );
}