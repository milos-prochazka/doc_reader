// ignore_for_file: constant_identifier_names

import 'dynamic_byte_buffer.dart';

class JsonUtils
{
  static T getValue<T>(dynamic json, String key, T defValue)
  {
    try
    {
      if (json is Map && json.containsKey(key))
      {
        return json[key];
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
}

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