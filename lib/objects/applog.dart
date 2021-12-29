//#define -FULL_NAME
//#define DISABLE_LOG
import 'dart:developer';

// ignore_for_file: non_constant_identifier_names

final _stackRegEx1 = RegExp(r'\#2.*$', multiLine: true);
final _stackRegEx2 = RegExp(r'(?<=[\:\/]).*\:\d*(?=\:)', multiLine: true);

String getLocation()
{
  final stack = StackTrace.current.toString();

//#if WEB
//##  {
//##    int start = 0;
//##    int end = 0;
//##
//##    for (int c = 0; c < 4; c++)
//##    {
//##      end = stack.indexOf('\n', start);
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
//##    return stackLine;
//##  }
//##//#else
  {
    final m1 = _stackRegEx1.firstMatch(stack);
    String? name;

    if (m1 != null)
    {
      name = m1[0];
      final m2 = _stackRegEx2.firstMatch(name ?? '');
      if (m2 != null)
      {
//#if FULL_NAME
//##        name = m2[0];
//##//#else
        final s = m2.input.substring(m2.start, m2.end);
        final p = s.lastIndexOf('/');
        name = (p > 0) ? s.substring(p + 1) : s;
//#end if line:51
      }
    }
    return name ?? '';
  }
//#end if line:14
}

void appLog([Object? msg])
{
//#if -DISABLE_LOG
//##  log(msg?.toString() ?? '', name: getLocation());
//#end if line:67
}

void appLog_always([Object? msg])
{
//#if -DISABLE_LOG
//##  log(msg?.toString() ?? '', name: getLocation());
//#end if line:74
}

void appLog_warnig([Object? msg])
{
//#if -DISABLE_LOG
//##  log(msg?.toString() ?? '', name: 'WARN:${getLocation()}');
//#end if line:81
}

void appLog_error([Object? msg])
{
//#if -DISABLE_LOG
//##  log(msg?.toString() ?? '', name: 'ERR:${getLocation()}');
//#end if line:88
}

void appLog_debug([Object? msg])
{
//#if -DISABLE_LOG
//##  log(msg?.toString() ?? '', name: getLocation());
//#end if line:95
}

void appLogEx(Object ex, {String? msg, Object? stackTrace})
{
  final strStack = stackTrace?.toString() ?? StackTrace.current.toString();
  log((msg != null ? msg + '\r\n' : '') + ex.toString() + '\r\n' + strStack, name: 'EXCEPTION');
}