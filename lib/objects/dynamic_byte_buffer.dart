// ignore_for_file: omit_local_variable_types

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

class DynamicByteBuffer //extends TypedData
{
  static const Utf8Codec utf8 = Utf8Codec(allowMalformed: true);

  late ByteData _data;
  var _count = 0;
  var readOffset = 0;
  var writeOffset = 0;

  DynamicByteBuffer([int capacity = 16])
  {
    _data = ByteData(math.max(16, capacity));
  }

  //@override
  ByteBuffer get byteBuffer => _data.buffer;

  //@override
  int get elementSizeInBytes => 1;

  //@override
  int get lengthInBytes => _count;

  //@override
  int get offsetInBytes => 0;

  int get count => _count;

  set count(int newCount)
  {
    if (_count < newCount)
    {
      fillBytes(0, _count, newCount - _count);
    }
    else if (_count > newCount)
    {
      fillBytes(0, newCount, _count - newCount);
    }

    _count = newCount;
  }

  static ByteData copyByteData(ByteData src, int srcIndex, ByteData dst, int dstIndex, int count)
  {
    while (count > 0)
    {
      if (count >= 4)
      {
        dst.setInt32(dstIndex, src.getInt32(srcIndex));
        count -= 4;
        srcIndex += 4;
        dstIndex += 4;
      }
      else
      {
        dst.setUint8(dstIndex++, src.getUint8(srcIndex++));
        count--;
      }
    }

    return dst;
  }

  void _expandCapacity(int capacity)
  {
    if (capacity > _data.lengthInBytes)
    {
      final newCpapacity = capacity > 2 * _data.lengthInBytes ? capacity : 2 * _data.lengthInBytes;
      _data = copyByteData(_data, 0, ByteData(newCpapacity), 0, _data.lengthInBytes);
    }

    if (capacity > _count)
    {
      _count = capacity;
    }
  }

  int get capacity => _data.lengthInBytes;

  set capacity(int newCapacity)
  {
    if (newCapacity != _data.lengthInBytes)
    {
      var size = math.min(newCapacity, _data.lengthInBytes);
      _data = copyByteData(_data, 0, ByteData(newCapacity), 0, size);
      if (_count > newCapacity)
      {
        _count = newCapacity;
      }
    }
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeUint8(int value)
  {
    _expandCapacity(writeOffset + 1);
    _data.setUint8(writeOffset++, value);
    return this;
  }

  DynamicByteBuffer setUint8(int value, int offset)
  {
    _expandCapacity(offset + 1);
    _data.setUint8(offset, value);

    return this;
  }

  int readUint8()
  {
    return _data.getUint8(readOffset++);
  }

  int getUint8(int offset)
  {
    return _data.getUint8(offset);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeInt8(int value)
  {
    _expandCapacity(writeOffset + 1);
    _data.setInt8(writeOffset++, value);
    return this;
  }

  DynamicByteBuffer setInt8(int value, int offset)
  {
    _expandCapacity(offset + 1);
    _data.setInt8(offset, value);
    return this;
  }

  int readInt8()
  {
    return _data.getInt8(readOffset++);
  }

  int getInt8(int offset)
  {
    return _data.getInt8(offset);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeUint16(int value, [Endian endian = Endian.big])
  {
    _expandCapacity(writeOffset + 2);
    _data.setUint16(writeOffset, value, endian);
    writeOffset += 2;
    return this;
  }

  DynamicByteBuffer setUint16(int value, int offset, [Endian endian = Endian.big])
  {
    _expandCapacity(offset + 2);
    _data.setUint16(offset, value, endian);
    return this;
  }

  int readUint16([Endian endian = Endian.big])
  {
    var result = _data.getUint16(readOffset, endian);
    readOffset += 2;
    return result;
  }

  int getUint16(int offset, [Endian endian = Endian.big])
  {
    return _data.getUint16(offset, endian);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeInt16(int value, [Endian endian = Endian.big])
  {
    _expandCapacity(writeOffset + 2);
    _data.setInt16(writeOffset, value, endian);
    writeOffset += 2;
    return this;
  }

  DynamicByteBuffer setInt16(int value, int offset, [Endian endian = Endian.big])
  {
    _expandCapacity(offset + 2);
    _data.setInt16(offset, value, endian);
    return this;
  }

  int readInt16([Endian endian = Endian.big])
  {
    var result = _data.getInt16(readOffset, endian);
    readOffset += 2;
    return result;
  }

  int getInt16(int offset, [Endian endian = Endian.big])
  {
    return _data.getInt16(offset, endian);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeUint32(int value, [Endian endian = Endian.big])
  {
    _expandCapacity(writeOffset + 4);
    _data.setUint32(writeOffset, value, endian);
    writeOffset += 4;
    return this;
  }

  DynamicByteBuffer setUint32(int value, int offset, [Endian endian = Endian.big])
  {
    _expandCapacity(offset + 4);
    _data.setUint32(offset, value, endian);
    return this;
  }

  int readUint32([Endian endian = Endian.big])
  {
    var result = _data.getUint32(readOffset, endian);
    readOffset += 4;
    return result;
  }

  int getUint32(int offset, [Endian endian = Endian.big])
  {
    return _data.getUint32(offset, endian);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeInt32(int value, [Endian endian = Endian.big])
  {
    _expandCapacity(writeOffset + 4);
    _data.setInt32(writeOffset, value, endian);
    writeOffset += 4;
    return this;
  }

  DynamicByteBuffer setInt32(int value, int offset, [Endian endian = Endian.big])
  {
    _expandCapacity(offset + 4);
    _data.setInt32(offset, value, endian);
    return this;
  }

  int readInt32([Endian endian = Endian.big])
  {
    var result = _data.getInt32(readOffset, endian);
    readOffset += 4;
    return result;
  }

  int getInt32(int offset, [Endian endian = Endian.big])
  {
    return _data.getInt32(offset, endian);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeUint64(int value, [Endian endian = Endian.big])
  {
    _expandCapacity(writeOffset + 4);
    _data.setUint64(writeOffset, value, endian);
    writeOffset += 8;
    return this;
  }

  DynamicByteBuffer setUint64(int value, int offset, [Endian endian = Endian.big])
  {
    _expandCapacity(offset + 8);
    _data.setUint64(offset, value, endian);
    return this;
  }

  int readUint64([Endian endian = Endian.big])
  {
    var result = _data.getUint64(readOffset, endian);
    readOffset += 8;
    return result;
  }

  int getUint64(int offset, [Endian endian = Endian.big])
  {
    return _data.getUint64(offset, endian);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeInt64(int value, [Endian endian = Endian.big])
  {
    _expandCapacity(writeOffset + 8);
    _data.setInt64(writeOffset, value, endian);
    writeOffset += 8;
    return this;
  }

  DynamicByteBuffer setInt64(int value, int offset, [Endian endian = Endian.big])
  {
    _expandCapacity(offset + 8);
    _data.setInt64(offset, value, endian);
    return this;
  }

  int readInt64([Endian endian = Endian.big])
  {
    var result = _data.getInt64(readOffset, endian);
    readOffset += 8;
    return result;
  }

  int getInt64(int offset, [Endian endian = Endian.big])
  {
    return _data.getInt64(offset, endian);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeFloat32(double value, [Endian endian = Endian.big])
  {
    _expandCapacity(writeOffset + 4);
    _data.setFloat32(writeOffset, value, endian);
    writeOffset += 4;
    return this;
  }

  DynamicByteBuffer setFloat32(double value, int offset, [Endian endian = Endian.big])
  {
    _expandCapacity(offset + 4);
    _data.setFloat32(offset, value, endian);
    return this;
  }

  double readFloat32([Endian endian = Endian.big])
  {
    var result = _data.getFloat32(readOffset, endian);
    readOffset += 4;
    return result;
  }

  double getFloat32(int offset, [Endian endian = Endian.big])
  {
    return _data.getFloat32(offset, endian);
  }

  // ---------------------------------------------------------------------------------------------------

  DynamicByteBuffer writeFloat64(double value, [Endian endian = Endian.big])
  {
    _expandCapacity(writeOffset + 8);
    _data.setFloat64(writeOffset, value, endian);
    writeOffset += 8;
    return this;
  }

  DynamicByteBuffer setFloat64(double value, int offset, [Endian endian = Endian.big])
  {
    _expandCapacity(offset + 8);
    _data.setFloat32(offset, value, endian);
    return this;
  }

  double readFloat64([Endian endian = Endian.big])
  {
    var result = _data.getFloat64(readOffset, endian);
    readOffset += 8;
    return result;
  }

  double getFloat64(int offset, [Endian endian = Endian.big])
  {
    return _data.getFloat64(offset, endian);
  }

  // ---------------------------------------------------------------------------------------------------

  void setBytes(List<int> values, int offset)
  {
    _expandCapacity(offset + values.length);
    for (var value in values)
    {
      _data.setUint8(offset++, value);
    }

    if (offset > _count)
    {
      _count = offset;
    }
  }

  void writeBytes(List<int> values)
  {
    setBytes(values, writeOffset);
    writeOffset += values.length;
  }

  // ---------------------------------------------------------------------------------------------------

  void fillBytes
  (
    int value,
    int offset,
    int count,
  )
  {
    _expandCapacity(offset + count);

    while (count > 0)
    {
      _data.setUint8(offset++, value);
      count--;
    }
    if (offset > _count)
    {
      _count = offset;
    }
  }

  // ---------------------------------------------------------------------------------------------------

  int setString
  (
    String value,
    int offset,
    {
      Encoding? encoding,
      bool nullTerminated = false,
      int size = -1,
    }
  )
  {
    if (size > 0)
    {
      List<int> bytes = (encoding ?? utf8).encode(value);

      if (nullTerminated)
      {
        if (bytes.length + 1 > size)
        {
          setBytes(bytes.sublist(0, size - 1), offset);
          _data.setInt8(size - 1, 0);
        }
        else
        {
          setBytes(bytes, offset);
          fillBytes(0, offset + bytes.length, size - bytes.length);
        }

        return size;
      }
      else
      {
        if (bytes.length > size)
        {
          setBytes(bytes.sublist(0, size), offset);
        }
        else if (bytes.length < size)
        {
          setBytes(bytes, offset);
          fillBytes(0, offset + bytes.length, size - bytes.length);
        }
        return size;
      }
    }
    else
    {
      List<int> bytes = (encoding ?? utf8).encode(value);
      setBytes(bytes, offset);

      if (nullTerminated)
      {
        setUint8(0, offset + bytes.length);
        return bytes.length + 1;
      }
      else
      {
        return bytes.length;
      }
    }
  }

  int writeString
  (
    String value,
    {
      Encoding? encoding,
      bool nullTerminated = false,
      int size = -1,
    }
  )
  {
    var strLen = setString(value, writeOffset, encoding: encoding, nullTerminated: nullTerminated, size: size);

    writeOffset += strLen;
    if (writeOffset > _count)
    {
      _count = writeOffset;
    }

    return strLen;
  }

  String _getString(int offset, int size, Encoding? encoding, bool nullTerminated, bool exactSize, bool readMode)
  {
    var result = '';
    var readSize = size;

    if (nullTerminated)
    {
      int endPoint = offset + size;
      for (var i = offset; i < endPoint; i++)
      {
        if (_data.getUint8(i) == 0)
        {
          size = i - offset;
          if (!exactSize)
          {
            readSize = size + 1;
          }
          break;
        }
      }
    }

    var data = _data.buffer.asUint8List(offset, math.min(size, _count - offset));
    result = (encoding ?? utf8).decode(data);

    if (readMode)
    {
      readOffset = offset + readSize;
    }

    return result;
  }

  String getString(int offset, int size,
    {Encoding? encoding, bool zeroEnding = false, bool nullTerminated = false, bool exactSize = true})
  {
    return _getString(offset, size, encoding, nullTerminated, exactSize, false);
  }

  String readString(int size,
    {Encoding? encoding, bool zeroEnding = false, bool nullTerminated = false, bool exactSize = true})
  {
    return _getString(readOffset, size, encoding, nullTerminated, exactSize, true);
  }

  // ---------------------------------------------------------------------------------------------------

  void clear()
  {
    _count = 0;
    readOffset = 0;
    writeOffset = 0;
  }

  ByteBuffer asByteBuffer()
  {
    return _data.buffer;
  }

  ByteData asByteData([int offsetInBytes = 0, int? length])
  {
    return _data.buffer.asByteData(offsetInBytes, length ?? _count);
  }

  List<int> toList()
  {
    return _data.buffer.asUint8List().sublist(0, _count);
  }

  // ---------------------------------------------------------------------------------------------------

  void _hexChar(StringBuffer builder, int value)
  {
    value &= 0xf;
    builder.writeCharCode((value <= 9) ? (value + 0x30) : (value - 10 + 0x41));
  }

  String toHexString(int offset, int count, [String space = ' '])
  {
    var builder = StringBuffer();

    while (count > 0)
    {
      count--;
      var value = _data.getUint8(offset++);
      _hexChar(builder, value >> 4);
      _hexChar(builder, value);
      if (count > 0)
      {
        builder.write(space);
      }
    }

    return builder.toString();
  }

  @override
  String toString()
  {
    return toHexString(0, _count);
  }
}