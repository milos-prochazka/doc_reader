import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'applog.dart';
import 'json_utils.dart';
import 'utils.dart';

class Config
{
  bool reqSave;
  bool autoSave;
  dynamic data;
  String? fileName;

  Config._internal()
  : reqSave = false,
  autoSave = false;

  Future<bool> load([String? fileName])
  {
    return _platformLoad(fileName);
  }

  Future<bool> save([bool force = false]) async
  {
    if (reqSave || force)
    {
      final result = await _platformStore();
      if (result)
      {
        reqSave = false;
      }
      return result;
    }
    else
    {
      return true;
    }
  }

  static Config? _instance;

  static Config get instance
  {
    return _instance ??= Config._internal();
  }

  T getValue<T>(dynamic json, String key, T defValue)
  {
    return JsonUtils.getValue(data, key, defValue);
  }

  T getValueByPath<T>(List<dynamic> path, {dynamic defValue, bool lastInArray = true})
  {
    return JsonUtils.getValueByPath(data, path, defValue: defValue, lastInArray: lastInArray);
  }

  setValueByPath(List<dynamic> path, dynamic value)
  {
    data = JsonUtils.setValueByPath(data, path, value);
    if (autoSave)
    {
      save(true);
    }
    else
    {
      reqSave = true;
    }
  }

  Map getOrCreateMap(List<dynamic> path)
  {
    var map = getValueByPath<Map?>(path);
    if (map == null)
    {
      map = {};
      setValueByPath(path, map);
    }

    return map;
  }

  List getOrCreateList(List<dynamic> path)
  {
    var list = getValueByPath<List?>(path);
    if (list == null)
    {
      list = [];
      setValueByPath(path, list);
    }

    return list;
  }

  Future<File> get defaultConfigFile async
  {
    final directory = await pathProvider.getApplicationSupportDirectory();
    return File(path.join(directory.path, 'config.json'));
  }

  Future<File> _configFile(String? fName) async
  {
    fName ??= fileName;
    final cfgFile = (fName == null) ? await defaultConfigFile : File(fName);
    fileName = cfgFile.path;

    return cfgFile;
  }

  Future<bool> _platformLoad([String? fName]) async
  {
    bool result = false;

    try
    {
      final cfgFile = await _configFile(fName);

      if (await cfgFile.exists())
      {
        final contents = await cfgFile.readAsString();
        data = setDynamic(data, jsonDecode(contents));
        result = true;
      }
    }
    catch (ex, stackTrace)
    {
      appLogEx(ex, stackTrace: stackTrace);
    }
    return result;
  }

  Future<bool> _platformStore([String? fName]) async
  {
    bool result = false;

    try
    {
      final cfgFile = await _configFile(fName);

      final contents = jsonEncode(data);
      await cfgFile.writeAsString(contents, flush: true);
      result = true;
    }
    catch (ex, stackTrace)
    {
      appLogEx(ex, stackTrace: stackTrace);
    }
    return result;
  }
}