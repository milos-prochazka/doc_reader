import 'dart:developer';

// ignore_for_file: non_constant_identifier_names

final _stackRegEx1 = RegExp(r'\#2.*$', multiLine: true);
final _stackRegEx2 = RegExp(r'(?<=[\:\/]).*\:\d*(?=\:)', multiLine: true);

String getLocation()
{
  String? name;
  final stack = StackTrace.current.toString();
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

void appLogEx(Object ex, {String? msg})
{
  log((msg != null ? msg + '\r\n' : '') + ex.toString() + '\r\n' + StackTrace.current.toString(), name: 'EXCEPTION');
}