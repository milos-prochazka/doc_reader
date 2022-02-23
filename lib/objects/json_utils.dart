// ignore_for_file: constant_identifier_names, camel_case_types

import 'dynamic_byte_buffer.dart';

class JsonUtils
{
  static T getValue<T>(dynamic json, String key, T defValue)
  {
    try
    {
      if (json is Map && json.containsKey(key))
      {
        json = json[key];
        if (json is T)
        {
          return json;
        }
        else if (defValue is double)
        {
          return json.toDouble() as T;
        }
        else if (defValue is String)
        {
          return json.toString() as T;
        }
        else
        {
          return defValue;
        }
      }
      else
      {
        return defValue;
      }
    }
    catch (e)
    {
      return defValue;
    }
  }

  static T getValueByPath<T>(dynamic json, List<dynamic> path, {T? defValue, bool lastInArray = true})
  {
    try
    {
      for (var item in path)
      {
        if (item is num)
        {
          if (json is List)
          {
            final index = item.toInt();
            final count = json.length;

            if (index >= count)
            {
              if (!lastInArray)
              {
                return defValue as T;
              }
              else
              {
                json = json[count - 1];
              }
            }
            else
            {
              json = json[index];
            }
          }
          else
          {
            return defValue as T;
          }
        }
        else if (item is String)
        {
          if (json is Map)
          {
            // ignore: unnecessary_cast
            final key = item as String;

            if (json.containsKey(key))
            {
              json = json[key];
            }
            else
            {
              return defValue as T;
            }
          }
          else
          {
            return defValue as T;
          }
        }
      }

      if (json is T)
      {
        return json;
      }
      else if (defValue is double)
      {
        return json.toDouble() as T;
      }
      else if (defValue is String)
      {
        return json.toString() as T;
      }
      else
      {
        return defValue as T;
      }
    }
    catch ($)
    {
      return defValue as T;
    }
  }

  static T getEnum<T>(dynamic json, String key, Map<String, T> enumMap, T defValue)
  {
    if (json is Map && json.containsKey(key))
    {
      final k = (json[key]?.toString());

      if (enumMap.containsKey(k))
      {
        return enumMap[k]!;
      }
    }

    return defValue;
  }

  static dynamic _setValueByPath(dynamic json, List<dynamic> path, int pathIndex, dynamic value)
  {
    if (pathIndex >= path.length)
    {
      json = value;
    }
    else
    {
      final item = path[pathIndex];
      if (item is num)
      {
        if (json is! List)
        {
          json = <dynamic>[];
        }

        final index = item.toInt();
        final count = json.length;

        if (index >= count)
        {
          json.add(_setValueByPath(null, path, pathIndex + 1, value));
        }
        else
        {
          json[index] = _setValueByPath(json[index], path, pathIndex + 1, value);
        }
      }
      else if (item is String)
      {
        if (json is! Map)
        {
          json = <dynamic, dynamic>{};
        }

        json[item] = _setValueByPath(json.containsKey(item) ? json[item] : null, path, pathIndex + 1, value);
      }
    }

    return json;
  }

  static dynamic setValueByPath(dynamic json, List<dynamic> path, dynamic value)
  {
    return _setValueByPath(json, path, 0, value);
  }
}

//#if 0
/// ## Formát CBJ
/// - Binární formát pro uložení JSON dat (v DARTu zakódovaný do proměnné dynamic)
/// - Každá data jsou uvedena bytem udávajícím typ dat, jejch délku, nebo index (podle typu) a blokem dalších
///   byte podle typu.
/// ### Typy dat:
/// - 0 - 191 (0-BF) - String - index v tabulce
/// - 0 - 239 (C0-EF) String delka 0 - 47
/// - F0 - Null
/// - F1 - False
/// - F2 - True
/// - F3 - String delka 1 byte
/// - F4 - String delka 2 byte
/// - F5 - String delka 4 byte
/// - F6 - String index 2 byte
/// - F7 - String index 3 byte
/// - F8 - int8
/// - F9 - int32
/// - FA - double
/// - FB - array
/// - FC - map
/// - FD - end (map,array)
/// - FE -
/// - FF -
class CBJ
{
  static const _CBJ_SHORT_STRING = 0xc0;
  static const _CBJ_SHORT_STRING_MAX_LEN = 47;

  static const _CBJ_NULL = 0xf0;
  static const _CBJ_TRUE = 0xf1;
  static const _CBJ_FALSE = 0xf2;

  static const _CBJ_STRING8 = 0xf3;
  static const _CBJ_STRING16 = 0xf4;
  static const _CBJ_STRING32 = 0xf5;

  static const _CBJ_DICT8_MAX = 0xbf;
  static const _CBJ_DICT16 = 0xf6;
  static const _CBJ_DICT24 = 0xf7;

  static const _CBJ_INT8 = 0xf8;
  static const _CBJ_INT32 = 0xf9;
  static const _CBJ_DOUBLE = 0xfa;
  static const _CBJ_ARRAY = 0xfb;
  static const _CBJ_MAP = 0xfc;
  static const _CBJ_END = 0xfd;

  static _encodeCBJInternal(dynamic data, DynamicByteBuffer buffer, Map<String, int> dictionary)
  {
    if (data == null)
    {
      buffer.writeUint8(_CBJ_NULL);
    }
    else if (data is bool)
    {
      buffer.writeUint8(data ? _CBJ_TRUE : _CBJ_FALSE);
    }
    else if (data is num)
    {
      if (data is int && data >= -128 && data <= 127)
      {
        buffer.writeUint8(_CBJ_INT8);
        buffer.writeInt8(data);
      }
      else if (data is int && data >= -2147483648 && data <= 2147483647)
      {
        buffer.writeUint8(_CBJ_INT32);
        buffer.writeInt32(data);
      }
      else
      {
        buffer.writeUint8(_CBJ_DOUBLE);
        buffer.writeFloat64(data.toDouble());
      }
    }
    else if (data is String)
    {
      final dictIndex = dictionary[data];

      if (dictIndex != null)
      {
        if (dictIndex <= _CBJ_DICT8_MAX)
        {
          buffer.writeUint8(dictIndex);
        }
        else if (dictIndex <= 65535)
        {
          buffer.writeUint8(_CBJ_DICT16);
          buffer.writeUint16(dictIndex);
        }
        else if (dictIndex <= 16777215)
        {
          buffer.writeUint8(_CBJ_DICT24);
          buffer.writeUint8((dictIndex >> 16) & 0xff);
          buffer.writeUint16(dictIndex & 0xffff);
        }
      }
      else
      {
        if (data.isNotEmpty)
        {
          dictionary[data] = dictionary.length;
        }
        final bytes = DynamicByteBuffer.utf8.encode(data);
        if (bytes.length <= _CBJ_SHORT_STRING_MAX_LEN)
        {
          buffer.writeUint8(_CBJ_SHORT_STRING + bytes.length);
        }
        else if (bytes.length <= 255)
        {
          buffer.writeUint8(_CBJ_STRING8);
          buffer.writeUint8(bytes.length);
        }
        else if (bytes.length <= 65535)
        {
          buffer.writeUint8(_CBJ_STRING16);
          buffer.writeUint16(bytes.length);
        }
        else
        {
          buffer.writeUint8(_CBJ_STRING32);
          buffer.writeUint32(bytes.length);
        }
        buffer.writeBytes(bytes);
      }
    }
    else if (data is List)
    {
      buffer.writeUint8(_CBJ_ARRAY);

      for (final item in data)
      {
        _encodeCBJInternal(item, buffer, dictionary);
      }

      buffer.writeUint8(_CBJ_END);
    }
    else if (data is Map)
    {
      buffer.writeUint8(_CBJ_MAP);

      for (final item in data.entries)
      {
        _encodeCBJInternal(item.key.toString(), buffer, dictionary);
        _encodeCBJInternal(item.value, buffer, dictionary);
      }

      buffer.writeUint8(_CBJ_END);
    }
  }

  static List<int> encode(dynamic data)
  {
    final buffer = DynamicByteBuffer(1024);

    _encodeCBJInternal(data, buffer, <String, int>{});

    return buffer.toList();
  }

  static dynamic _decodeCBJInternal(DynamicByteBuffer buffer, List<String> dictionary)
  {
    final data = buffer.readUint8();
    if (data <= _CBJ_DICT8_MAX)
    {
      return dictionary[data];
    }
    else if (data >= _CBJ_SHORT_STRING && data <= (_CBJ_SHORT_STRING + _CBJ_SHORT_STRING_MAX_LEN))
    {
      final result = buffer.readString(data - _CBJ_SHORT_STRING, exactSize: true);
      if (result.isNotEmpty)
      {
        dictionary.add(result);
      }
      return result;
    }
    else
    {
      switch (data)
      {
        case _CBJ_NULL:
        {
          return null;
        }

        case _CBJ_TRUE:
        {
          return true;
        }

        case _CBJ_FALSE:
        {
          return false;
        }

        case _CBJ_STRING8:
        {
          final result = buffer.readString(buffer.readUint8(), exactSize: true);
          dictionary.add(result);
          return result;
        }

        case _CBJ_STRING16:
        {
          final result = buffer.readString(buffer.readUint16(), exactSize: true);
          dictionary.add(result);
          return result;
        }

        case _CBJ_STRING32:
        {
          final result = buffer.readString(buffer.readUint32(), exactSize: true);
          dictionary.add(result);
          return result;
        }

        case _CBJ_DICT16:
        {
          return dictionary[buffer.readUint16()];
        }

        case _CBJ_DICT24:
        {
          final int index = (buffer.readUint8() << 16) + buffer.readUint16();
          return dictionary[index];
        }

        case _CBJ_INT8:
        {
          return buffer.readInt8();
        }

        case _CBJ_INT32:
        {
          return buffer.readInt32();
        }

        case _CBJ_DOUBLE:
        {
          return buffer.readFloat64();
        }

        case _CBJ_ARRAY:
        {
          final result = <dynamic>[];
          while (buffer.getUint8(buffer.readOffset) != _CBJ_END)
          {
            result.add(_decodeCBJInternal(buffer, dictionary));
          }
          buffer.readUint8();
          return result;
        }

        case _CBJ_MAP:
        {
          final result = <String, dynamic>{};

          while (buffer.getUint8(buffer.readOffset) != _CBJ_END)
          {
            final key = _decodeCBJInternal(buffer, dictionary).toString();
            result[key] = _decodeCBJInternal(buffer, dictionary);
          }
          buffer.readUint8();
          return result;
        }

        default:
        {
          return null;
        }
      }
    }
  }

  static decode(List<int> data)
  {
    final buffer = DynamicByteBuffer(data.length)..writeBytes(data);

    return _decodeCBJInternal(buffer, <String>[]);
  }
}

//#end
//////////////////////////////////////////////////////////////////
class DBJ
{
  static const _DBJ_SHORT_STRING_MAX = 0xdf;
  static const _DBJ_MID_STRING_MAX = 0x0dff;
  static const _DBJ_LONG_STRING = 0xef;
  static const _DBJ_END_DICT = 0xff;

  static const _DBJ_DICT8_MAX = 0xbf;

  static const _DBJ_NULL = 0xf0;
  static const _DBJ_TRUE = 0xf1;
  static const _DBJ_FALSE = 0xf2;

  static const _DBJ_SHORT_STRING = 0xc0;
  static const _DBJ_SHORT_STRING_MAX_LEN = 47;
  static const _DBJ_STRING8 = 0xf3;
  static const _DBJ_STRING16 = 0xf4;
  static const _DBJ_STRING32 = 0xf5;

  static const _DBJ_DICT16 = 0xf6;
  static const _DBJ_DICT24 = 0xf7;

  static const _DBJ_INT8 = 0xf8;
  static const _DBJ_INT32 = 0xf9;
  static const _DBJ_DOUBLE = 0xfa;
  static const _DBJ_ARRAY = 0xfb;
  static const _DBJ_MAP = 0xfc;
  static const _DBJ_END = 0xff;

  static _incrementItem(String text, Map<String, _DBJ_Item> list)
  {
    final item = list[text];
    if (item != null)
    {
      item.count++;
    }
    else
    {
      list[text] = _DBJ_Item(text);
    }
  }

  static _getDictionary(dynamic data, Map<String, _DBJ_Item> dictionary)
  {
    if (data is String)
    {
      _incrementItem(data, dictionary);
    }
    else if (data is List)
    {
      for (final item in data)
      {
        _getDictionary(item, dictionary);
      }
    }
    else if (data is Map)
    {
      for (final item in data.entries)
      {
        _incrementItem(item.key.toString(), dictionary);
        _getDictionary(item.value, dictionary);
      }
    }
  }

  static List<String> getDictionary(dynamic data, dictionaryCountTreshold)
  {
    final dictionary = <String, _DBJ_Item>{};
    _getDictionary(data, dictionary);

    //final dictList = dictionary.values.toList();
    final dictList = <_DBJ_Item>[];

    for (final item in dictionary.values)
    {
      if (item.count >= dictionaryCountTreshold)
      {
        dictList.add(item);
      }
    }

    dictList.sort((a, b) => b.count.compareTo(a.count));

    final result = <String>[];

    for (final item in dictList)
    {
      result.add(item.text);
    }

    return result;
  }

  static _encodeInternal(dynamic data, DynamicByteBuffer buffer, Map<String, int> dictionary)
  {
    if (data == null)
    {
      buffer.writeUint8(_DBJ_NULL);
    }
    else if (data is bool)
    {
      buffer.writeUint8(data ? _DBJ_TRUE : _DBJ_FALSE);
    }
    else if (data is num)
    {
      if (data is int && data >= -128 && data <= 127)
      {
        buffer.writeUint8(_DBJ_INT8);
        buffer.writeInt8(data);
      }
      else if (data is int && data >= -2147483648 && data <= 2147483647)
      {
        buffer.writeUint8(_DBJ_INT32);
        buffer.writeInt32(data);
      }
      else
      {
        buffer.writeUint8(_DBJ_DOUBLE);
        buffer.writeFloat64(data.toDouble());
      }
    }
    else if (data is String)
    {
      final dictIndex = dictionary[data];

      if (dictIndex != null)
      {
        if (dictIndex <= _DBJ_DICT8_MAX)
        {
          buffer.writeUint8(dictIndex);
        }
        else if (dictIndex <= 65535)
        {
          buffer.writeUint8(_DBJ_DICT16);
          buffer.writeUint16(dictIndex);
        }
        else if (dictIndex <= 16777215)
        {
          buffer.writeUint8(_DBJ_DICT24);
          buffer.writeUint8((dictIndex >> 16) & 0xff);
          buffer.writeUint16(dictIndex & 0xffff);
        }
      }
      else
      {
        if (data.isNotEmpty)
        {
          dictionary[data] = dictionary.length;
        }
        final bytes = DynamicByteBuffer.utf8.encode(data);
        if (bytes.length <= _DBJ_SHORT_STRING_MAX_LEN)
        {
          buffer.writeUint8(_DBJ_SHORT_STRING + bytes.length);
        }
        else if (bytes.length <= 255)
        {
          buffer.writeUint8(_DBJ_STRING8);
          buffer.writeUint8(bytes.length);
        }
        else if (bytes.length <= 65535)
        {
          buffer.writeUint8(_DBJ_STRING16);
          buffer.writeUint16(bytes.length);
        }
        else
        {
          buffer.writeUint8(_DBJ_STRING32);
          buffer.writeUint32(bytes.length);
        }
        buffer.writeBytes(bytes);
      }
    }
    else if (data is List)
    {
      buffer.writeUint8(_DBJ_ARRAY);

      for (final item in data)
      {
        _encodeInternal(item, buffer, dictionary);
      }

      buffer.writeUint8(_DBJ_END);
    }
    else if (data is Map)
    {
      buffer.writeUint8(_DBJ_MAP);

      for (final item in data.entries)
      {
        _encodeInternal(item.key.toString(), buffer, dictionary);
        _encodeInternal(item.value, buffer, dictionary);
      }

      buffer.writeUint8(_DBJ_END);
    }
  }

  static List<int> encode(dynamic data, {dictionaryCountTreshold = 3})
  {
    final buffer = DynamicByteBuffer(1024);
    final dictionary = <String, int>{};

    if (dictionaryCountTreshold > 0)
    {
      final dictList = getDictionary(data, dictionaryCountTreshold);

      for (final item in dictList)
      {
        final bytes = DynamicByteBuffer.utf8.encode(item);
        if (bytes.length <= _DBJ_SHORT_STRING_MAX)
        {
          buffer.writeUint8(bytes.length);
        }
        else if (bytes.length <= _DBJ_MID_STRING_MAX)
        {
          buffer.writeUint8(0xf0 | ((bytes.length >> 8) & 0xf));
          buffer.writeUint8(bytes.length & 0xff);
        }
        else
        {
          buffer.writeInt8(_DBJ_LONG_STRING);
          buffer.writeUint32(bytes.length);
        }
        buffer.writeBytes(bytes);
        dictionary[item] = dictionary.length;
      }
    }

    buffer.writeInt8(_DBJ_END_DICT);

    _encodeInternal(data, buffer, dictionary);

    return buffer.toList();
  }

  static dynamic _decodeInternal(DynamicByteBuffer buffer, List<String> dictionary)
  {
    final data = buffer.readUint8();
    if (data <= _DBJ_DICT8_MAX)
    {
      return dictionary[data];
    }
    else if (data >= _DBJ_SHORT_STRING && data <= (_DBJ_SHORT_STRING + _DBJ_SHORT_STRING_MAX_LEN))
    {
      final result = buffer.readString(data - _DBJ_SHORT_STRING, exactSize: true);
      if (result.isNotEmpty)
      {
        dictionary.add(result);
      }
      return result;
    }
    else
    {
      switch (data)
      {
        case _DBJ_NULL:
        {
          return null;
        }

        case _DBJ_TRUE:
        {
          return true;
        }

        case _DBJ_FALSE:
        {
          return false;
        }

        case _DBJ_STRING8:
        {
          final result = buffer.readString(buffer.readUint8(), exactSize: true);
          dictionary.add(result);
          return result;
        }

        case _DBJ_STRING16:
        {
          final result = buffer.readString(buffer.readUint16(), exactSize: true);
          dictionary.add(result);
          return result;
        }

        case _DBJ_STRING32:
        {
          final result = buffer.readString(buffer.readUint32(), exactSize: true);
          dictionary.add(result);
          return result;
        }

        case _DBJ_DICT16:
        {
          return dictionary[buffer.readUint16()];
        }

        case _DBJ_DICT24:
        {
          final int index = (buffer.readUint8() << 16) + buffer.readUint16();
          return dictionary[index];
        }

        case _DBJ_INT8:
        {
          return buffer.readInt8();
        }

        case _DBJ_INT32:
        {
          return buffer.readInt32();
        }

        case _DBJ_DOUBLE:
        {
          return buffer.readFloat64();
        }

        case _DBJ_ARRAY:
        {
          final result = <dynamic>[];
          while (buffer.getUint8(buffer.readOffset) != _DBJ_END)
          {
            result.add(_decodeInternal(buffer, dictionary));
          }
          buffer.readUint8();
          return result;
        }

        case _DBJ_MAP:
        {
          final result = <String, dynamic>{};

          while (buffer.getUint8(buffer.readOffset) != _DBJ_END)
          {
            final key = _decodeInternal(buffer, dictionary).toString();
            result[key] = _decodeInternal(buffer, dictionary);
          }
          buffer.readUint8();
          return result;
        }

        default:
        {
          return null;
        }
      }
    }
  }

  static decode(List<int> data)
  {
    final buffer = DynamicByteBuffer(data.length)..writeBytes(data);
    final dictionary = <String>[];

    int strSz;
    while ((strSz = buffer.readUint8()) != _DBJ_END_DICT)
    {
      if (strSz > _DBJ_SHORT_STRING_MAX)
      {
        if (strSz == _DBJ_LONG_STRING)
        {
          strSz = buffer.readUint32();
        }
        else
        {
          strSz = ((strSz & 0xf) << 8) | buffer.readUint8();
        }
      }

      final str = buffer.readString(strSz);
      dictionary.add(str);
    }

    return _decodeInternal(buffer, dictionary);
  }
}

class _DBJ_Item
{
  String text;
  int count;

  _DBJ_Item(this.text) : count = 1;
}