class ValueUnit
{
  /// Dekodovani hodnoty a jednotky. 12.34em => gr1= 12.34 gr3=>em
  static RegExp valueUnitRegExp = RegExp(r'^(\-?\d+(\.\d+)?)\s*([%-_\w+])?', multiLine: false, caseSensitive: false);

  double? value;

  String? unit;

  ValueUnit(String? text)
  {
    if (text != null)
    {
      final match = valueUnitRegExp.firstMatch(text);

      if (match != null)
      {
        value = double.tryParse(match.group(1) ?? '');
        unit = match.group(3)?.toLowerCase();
      }
    }
  }

  bool get hasValue => value != null;

  bool get hasUnit => value != null && unit != null;

  double? toDip(double emSize, double screenSize)
  {
    if (value != null)
    {
      switch (unit)
      {
        case 'em':
        return emSize * value!;

        case '%':
        return 0.01 * screenSize * value!;

        default:
        return value;
      }
    }
    else
    {
      return null;
    }
  }

  @override
  String toString()
  {
    return (value?.toString() ?? '(null)') + (unit ?? '');
  }
}