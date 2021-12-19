// ignore_for_file: non_constant_identifier_names

import 'i_cloneable.dart';

String enum_ToString(Object param)
{
  String str = param.toString();
  int i = str.indexOf('.');

  return (i > 0) ? str.substring(i + 1) : str;
}

extension StringExt on String
{
  /// Test mezery na posizi v retezci
  /// - true pokud na pozici [index] je mezera (tabulator,vertikalni mezera, nedelitelna mezera)
  /// - false pokud na pozici [index] neni mezera
  /// - false pokud [index] nelezi v rozsahu retezce
  bool hasSpaceAtIndex(int index)
  {
    if (index < 0 || index >= length)
    {
      return false;
    }
    else
    {
      return ' \t\v\u00a0'.contains(substring(index, index + 1));
    }
  }

  /// Porohozeni znaku ABC => CBA
  String swap()
  {
    var chars = codeUnits;
    var result = List.filled(chars.length, chars.length);

    for (int i = 0; i < chars.length; i++)
    {
      result[result.length - i - 1] = chars[i];
    }

    return String.fromCharCodes(result);
  }
}

/// Konverze na cislo
String numberToCharacters(int param, String charList)
{
  String result = '';
  int n = charList.length;

  do
  {
    var x = param % n;
    param ~/= n;
    if (result.isNotEmpty && param == 0)
    {
      x--;
    }
    result = charList.substring(x, x + 1) + result;
  }
  while (param > 0);

  return result;
}

/// Klonovani dynamic objektu
/// - Klonuje objekt slozeny z Map,List,Set,String,double,int a bool (odpovida Json)
/// - Objekty ktere jsou potomkem [ICloneable] jsou kopirovany pomoci metody clone
/// - Opbejkt ktere nesjou potomkem [ICloneable] se vraci odkazem na puvodni objekt
dynamic clone(dynamic value)
{
  dynamic result;

  if (value != null)
  {
    if (value is Map)
    {
      result = <String, dynamic>{};
      for (final v in value.entries)
      {
        result[v.key] = clone(v.value);
      }
    }
    else if (value is List)
    {
      result = <dynamic>[];
      for (final v in value)
      {
        result.add(clone(v));
      }
    }
    else if (value is Set)
    {
      result = <dynamic>{};
      for (final v in value)
      {
        result.add(clone(v));
      }
    }
    else if (value is ICloneable)
    {
      result = value.clone();
    }
    else
    {
      result = value;
    }
  }

  return result;
}