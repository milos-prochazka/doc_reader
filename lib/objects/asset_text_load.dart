import 'package:doc_reader/objects/text_load_provider.dart';
import 'package:flutter/services.dart';

class AssetLoadTextLoad extends TextLoadProvider
{
  @override
  Future<String> loadText(String name, bool usePath) async
  {
    return await rootBundle.loadString(getPath(name, usePath).replaceAll('\\', '/'));
  }
}