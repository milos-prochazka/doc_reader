import 'package:path/path.dart' as path;

abstract class TextLoadProvider
{
  String rootPath = '';
  Future<String> loadText(String name, bool usePath);

  String getPath(String name, bool usePath)
  {
    if (usePath)
    {
      final result = path.normalize(path.join(rootPath, name));
      return result;
    }
    else
    {
      rootPath = path.normalize(path.dirname(name));
      return name;
    }
  }
}

class TextLoadException implements Exception
{
  final dynamic fileName;

  TextLoadException([this.fileName]);

  @override
  String toString()
  {
    if (fileName == null) return "TextLoadException";
    return "TextLoadException: $fileName";
  }
}