//#define -FULL_NAME
//#define -DISABLE_LOG
// ignore_for_file: constant_identifier_names

import 'dart:developer';

// ignore_for_file: non_constant_identifier_names

const LOG_ERROR = 0x0001;
const LOG_WARNING = 0x0002;
const LOG_NORMAL = 0x0004;
const LOG_DEBUG = 0x0008;
const LOG_VERBOSE = 0x0010;

int logLevel = LOG_ERROR | LOG_WARNING | LOG_NORMAL | LOG_DEBUG | LOG_VERBOSE;

final _stackRegEx1 = RegExp(r'\#2.*$', multiLine: true);
final _stackRegEx2 = RegExp(r'(?<=[\:\/]).*\:\d*(?=\:)', multiLine: true);

String getLocation()
{
  final stack = StackTrace.current.toString();

//#if WEB
  {
    int start = 0;
    int end = 0;

    for (int c = 0; c < 4; c++)
    {
      end = stack.indexOf('\n', start);
      if (end == -1)
      {
        end = stack.length;
        break;
      }
      else
      {
        if (c < 3)
        {
          start = end + 1;
        }
      }
    }

    final stackLine = stack.substring(start, end);

    return stackLine;
  }
//#else
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
        name = m2[0];
//#else
        final s = m2.input.substring(m2.start, m2.end);
        final p = s.lastIndexOf('/');
        name = (p > 0) ? s.substring(p + 1) : s;
//#end if line:61
      }
    }
    return name ?? '';
  }
//#end if line:24
}

setLogLevel(int level)
{
  logLevel = level | (level - 1);
}

void appLog([Object? msg])
{
//#if -DISABLE_LOG
  if ((logLevel & LOG_NORMAL) != 0)
  {
    log(msg?.toString() ?? '', name: getLocation());
  }
//#end if line:82
}

void appLog_always([Object? msg])
{
//#if -DISABLE_LOG
  log(msg?.toString() ?? '', name: getLocation());
//#end if line:92
}

void appLog_warnig([Object? msg])
{
//#if -DISABLE_LOG
  if ((logLevel & LOG_WARNING) != 0)
  {
    log(msg?.toString() ?? '', name: 'WARN:${getLocation()}');
  }
//#end if line:99
}

void appLog_error([Object? msg])
{
//#if -DISABLE_LOG
  if ((logLevel & LOG_ERROR) != 0)
  {
    log(msg?.toString() ?? '', name: 'ERR:${getLocation()}');
  }
//#end if line:109
}

void appLog_debug([Object? msg])
{
//#if -DISABLE_LOG
  if ((logLevel & LOG_DEBUG) != 0)
  {
    log(msg?.toString() ?? '', name: getLocation());
  }
//#end if line:119
}

//#if VERBOSE
void appLog_verbose([Object? msg])
{
//#if -DISABLE_LOG
  if ((logLevel & LOG_VERBOSE)!=0)
  {
    log(msg?.toString() ?? '', name: getLocation());
  }
//#end if line:123
}
//#end if line:127

void appLogEx(Object ex, {String? msg, Object? stackTrace})
{
  final strStack = stackTrace?.toString() ?? StackTrace.current.toString();
  log((msg != null ? msg + '\r\n' : '') + ex.toString() + '\r\n' + strStack, name: 'EXCEPTION');
}