// ignore_for_file: non_constant_identifier_names, unnecessary_this

import 'i_cloneable.dart';
import 'package:collection/collection.dart';

String enum_ToString(Object param)
{
  String str = param.toString();
  int i = str.indexOf('.');

  return (i > 0) ? str.substring(i + 1) : str;
}

extension DoubleExt on double
{
  /// Desetinna cast cisla
  /// * -10.75.frac() => -0.75
  /// *  10.75.frac() => 0.75
  double frac()
  {
    return this - this.floorToDouble();
  }
}

extension StringExt on String
{
  /// Test mezery na posizi v retezci
  /// - true pokud na pozici [index] je mezera (tabulator,vertikalni mezera, nedelitelna mezera)
  /// - false pokud na pozici [index] neni mezera
  /// - false pokud [index] nelezi v rozsahu retezce
  bool hasSpaceAtIndex(int index)
  {
    if (index < 0 || index >= this.length)
    {
      return false;
    }
    else
    {
      return ' \t\v\u00a0'.contains(this.substring(index, index + 1));
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
/// - Obejkty ktere nejsou potomkem [ICloneable] se vraci odkazem na puvodni objekt
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

/// Nastaveni dynamic objektu
/// - Provede nastaveni [dest] objektu ze [source].
/// - Pokud je [source] typu Map provede kopirovani objektu.
///   Pokud neni [dest] typu Map vytvori se nove Map jako vysledek.
///   Pokud [dest] i [source] obsahuji objekt se stejnym klicem provade se vnorene kopirovani do tohoto objektu
/// - Pokud je [source] typu List provede se pridani dalsi polozek do List.
///   Pokud neni [dest] typu List vytvori se nove List jako vysledek.
/// - V jinych pripadech se vraci [source]
/// - [dest] se zmeni (v pripade kopirovani Map, nebo List)
/// - [source] se nemeni
dynamic setDynamic(dynamic dest, dynamic source)
{
  dynamic result;
  if (source is Map)
  {
    result = dest is Map ? dest : {};
    for (var item in source.entries)
    {
      result[item.key] = setDynamic(result[item.key], item.value);
    }
  }
  else if (source is List)
  {
    result = dest is List ? dest : [];
    for (var item in source)
    {
      dest.add(setDynamic(null, item.value));
    }
  }
  else
  {
    result = source;
  }

  return result;
}

/// ### Porovná dva dynamic objekty zda jsou shodné
///
/// - Vrací **true** pokud jsou objekty shodné.
/// - Provádí hloubkové porovnání pokud dynamic obsahuje List nebo Map.
/// - Pokud objekt implementuje [Comparable] použije rozhraní pro porovnání.
///
bool compareDynamic(dynamic a, dynamic b)
{
  if (a is bool && b is bool)
  {
    return a == b;
  }
  else if (a is int && b is int)
  {
    return a == b;
  }
  else if (a is double && b is double)
  {
    return a == b;
  }
  else if (a is String && b is String)
  {
    return a == b;
  }
  else if (a is List && b is List)
  {
    if (a.length != b.length)
    {
      return false;
    }
    else
    {
      for (var i = 0; i < a.length; i++)
      {
        if (!compareDynamic(a[i], b[i]))
        {
          return false;
        }
      }
      return true;
    }
  }
  else if (a is Map && b is Map)
  {
    if (a.length != b.length)
    {
      return false;
    }
    else
    {
      for (final item in a.entries)
      {
        if (!b.containsKey(item.key))
        {
          return false;
        }
        else if (!compareDynamic(item.value, b[item.key]))
        {
          return false;
        }
      }

      return true;
    }
  }
  else if (a == null && b == null)
  {
    return true;
  }
  else if (a is Comparable && b is Comparable)
  {
    try
    {
      return a.compareTo(b) == 0;
    }
    catch (_)
    {
      return false;
    }
  }
  else
  {
    return false;
  }
}