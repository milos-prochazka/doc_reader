import 'dart:developer';
import 'package:flutter/foundation.dart' show kIsWeb;

// ignore_for_file: non_constant_identifier_names

final _stackRegEx1 = RegExp(r'\#2.*$', multiLine: true);
final _stackRegEx2 = RegExp(r'(?<=[\:\/]).*\:\d*(?=\:)', multiLine: true);

String getLocation() 
{
  String? name;
  final stack = StackTrace.current.toString();

//#if WEB
//##  {
//##    int start = 0;
//##    int end = 0;
//##
//##    for (int c = 0; c < 4; c++)
//##    {
//##      end = stack.indexOf("\n", start);
//##      if (end == -1)
//##      {
//##        end = stack.length;
//##        break;
//##      }
//##      else
//##      {
//##        if (c < 3)
//##        {
//##          start = end + 1;
//##        }
//##      }
//##    }
//##
//##    final stackLine = stack.substring(start, end);
//##
//##    name = stackLine;
//##  }
//##//#else
  {
    final m1 = _stackRegEx1.firstMatch(stack);

    if (m1 != null) 
    {
      final m2 = _stackRegEx2.firstMatch(m1.input.substring(m1.start, m1.end));
      if (m2 != null) 
      {
        final s = m2.input.substring(m2.start, m2.end);
        final p = s.lastIndexOf('/');
        name = (p > 0) ? s.substring(p + 1) : s;
      }
    }
  }
//#end if line:14

  return name ?? '';
}

void appLog([Object? msg]) 
{
  log(msg?.toString() ?? "", name: getLocation());
}

void appLog_always([Object? msg]) 
{
  log(msg?.toString() ?? "", name: getLocation());
}

void appLog_warnig([Object? msg]) 
{
  log(msg?.toString() ?? "", name: 'WARN:${getLocation()}');
}

void appLog_error([Object? msg]) 
{
  log(msg?.toString() ?? "", name: 'ERR:${getLocation()}');
}

void appLog_debug([Object? msg]) 
{
  log(msg?.toString() ?? "", name: getLocation());
}

void appLogEx(Object ex, {String? msg, Object? stackTrace}) 
{
  final strStack = stackTrace?.toString() ?? StackTrace.current.toString();
  log((msg != null ? msg + '\r\n' : '') + ex.toString() + '\r\n' + strStack, name: 'EXCEPTION');
}