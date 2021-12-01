import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const colorsNames = <String, int>
{
  'alice blue': 0xFFF0F8FF,
  'antique white': 0xFFFAEBD7,
  'aqua': 0xFF00FFFF,
  'aquamarine': 0xFF7FFFD4,
  'azure': 0xFFF0FFFF,
  'beige': 0xFFF5F5DC,
  'bisque': 0xFFFFE4C4,
  'black': 0xFF000000,
  'blanched almond': 0xFFFFEBCD,
  'blue': 0xFF0000FF,
  'blue violet': 0xFF8A2BE2,
  'brown': 0xFFA52A2A,
  'burlywood': 0xFFDEB887,
  'cadet blue': 0xFF5F9EA0,
  'chartreuse': 0xFF7FFF00,
  'chocolate': 0xFFD2691E,
  'coral': 0xFFFF7F50,
  'cornflower blue': 0xFF6495ED,
  'cornsilk': 0xFFFFF8DC,
  'crimson': 0xFFDC143C,
  'cyan': 0xFF00FFFF,
  'dark blue': 0xFF00008B,
  'dark cyan': 0xFF008B8B,
  'dark goldenrod': 0xFFB8860B,
  'dark gray': 0xFFA9A9A9,
  'dark green': 0xFF006400,
  'dark khaki': 0xFFBDB76B,
  'dark magenta': 0xFF8B008B,
  'dark olive green': 0xFF556B2F,
  'dark orange': 0xFFFF8C00,
  'dark orchid': 0xFF9932CC,
  'dark red': 0xFF8B0000,
  'dark salmon': 0xFFE9967A,
  'dark sea green': 0xFF8FBC8F,
  'dark slate blue': 0xFF483D8B,
  'dark slate gray': 0xFF2F4F4F,
  'dark turquoise': 0xFF00CED1,
  'dark violet': 0xFF9400D3,
  'deep pink': 0xFFFF1493,
  'deep sky blue': 0xFF00BFFF,
  'dim gray': 0xFF696969,
  'dodger blue': 0xFF1E90FF,
  'firebrick': 0xFFB22222,
  'floral white': 0xFFFFFAF0,
  'forest green': 0xFF228B22,
  'fuchsia': 0xFFFF00FF,
  'gainsboro': 0xFFDCDCDC,
  'ghost white': 0xFFF8F8FF,
  'gold': 0xFFFFD700,
  'goldenrod': 0xFFDAA520,
  'gray': 0xFFBEBEBE,
  'web gray': 0xFF808080,
  'green': 0xFF00FF00,
  'web green': 0xFF008000,
  'green yellow': 0xFFADFF2F,
  'honeydew': 0xFFF0FFF0,
  'hot pink': 0xFFFF69B4,
  'indian red': 0xFFCD5C5C,
  'indigo': 0xFF4B0082,
  'ivory': 0xFFFFFFF0,
  'khaki': 0xFFF0E68C,
  'lavender': 0xFFE6E6FA,
  'lavender blush': 0xFFFFF0F5,
  'lawn green': 0xFF7CFC00,
  'lemon chiffon': 0xFFFFFACD,
  'light blue': 0xFFADD8E6,
  'light coral': 0xFFF08080,
  'light cyan': 0xFFE0FFFF,
  'light goldenrod': 0xFFFAFAD2,
  'light gray': 0xFFD3D3D3,
  'light green': 0xFF90EE90,
  'light pink': 0xFFFFB6C1,
  'light salmon': 0xFFFFA07A,
  'light sea green': 0xFF20B2AA,
  'light sky blue': 0xFF87CEFA,
  'light slate gray': 0xFF778899,
  'light steel blue': 0xFFB0C4DE,
  'light yellow': 0xFFFFFFE0,
  'lime': 0xFF00FF00,
  'lime green': 0xFF32CD32,
  'linen': 0xFFFAF0E6,
  'magenta': 0xFFFF00FF,
  'maroon': 0xFFB03060,
  'web maroon': 0xFF800000,
  'medium aquamarine': 0xFF66CDAA,
  'medium blue': 0xFF0000CD,
  'medium orchid': 0xFFBA55D3,
  'medium purple': 0xFF9370DB,
  'medium sea green': 0xFF3CB371,
  'medium slate blue': 0xFF7B68EE,
  'medium spring green': 0xFF00FA9A,
  'medium turquoise': 0xFF48D1CC,
  'medium violet red': 0xFFC71585,
  'midnight blue': 0xFF191970,
  'mint cream': 0xFFF5FFFA,
  'misty rose': 0xFFFFE4E1,
  'moccasin': 0xFFFFE4B5,
  'navajo white': 0xFFFFDEAD,
  'navy blue': 0xFF000080,
  'old lace': 0xFFFDF5E6,
  'olive': 0xFF808000,
  'olive drab': 0xFF6B8E23,
  'orange': 0xFFFFA500,
  'orange red': 0xFFFF4500,
  'orchid': 0xFFDA70D6,
  'pale goldenrod': 0xFFEEE8AA,
  'pale green': 0xFF98FB98,
  'pale turquoise': 0xFFAFEEEE,
  'pale violet red': 0xFFDB7093,
  'papaya whip': 0xFFFFEFD5,
  'peach puff': 0xFFFFDAB9,
  'peru': 0xFFCD853F,
  'pink': 0xFFFFC0CB,
  'plum': 0xFFDDA0DD,
  'powder blue': 0xFFB0E0E6,
  'purple': 0xFFA020F0,
  'web purple': 0xFF800080,
  'rebecca purple': 0xFF663399,
  'red': 0xFFFF0000,
  'rosy brown': 0xFFBC8F8F,
  'royal blue': 0xFF4169E1,
  'saddle brown': 0xFF8B4513,
  'salmon': 0xFFFA8072,
  'sandy brown': 0xFFF4A460,
  'sea green': 0xFF2E8B57,
  'seashell': 0xFFFFF5EE,
  'sienna': 0xFFA0522D,
  'silver': 0xFFC0C0C0,
  'sky blue': 0xFF87CEEB,
  'slate blue': 0xFF6A5ACD,
  'slate gray': 0xFF708090,
  'snow': 0xFFFFFAFA,
  'spring green': 0xFF00FF7F,
  'steel blue': 0xFF4682B4,
  'tan': 0xFFD2B48C,
  'teal': 0xFF008080,
  'thistle': 0xFFD8BFD8,
  'tomato': 0xFFFF6347,
  'turquoise': 0xFF40E0D0,
  'violet': 0xFFEE82EE,
  'wheat': 0xFFF5DEB3,
  'white': 0xFFFFFFFF,
  'white smoke': 0xFFF5F5F5,
  'yellow': 0xFFFFFF00,
  'yellow green': 0xFF9ACD32,
};

Map<String, int>? _colorRegister;

final RegExp _numColor = RegExp(r'\#[0-9A-Fa-f]{3,8}');

void registerColorName(String name, int value) 
{
  (_colorRegister ??= <String, int>{})[name.trim().toLowerCase()] = value;
}

int intColorFromText(String text, [int defColor = 0xff000000]) 
{
  text = text.trim().toLowerCase();

  final found = _colorRegister?[text] ?? colorsNames[text];
  if (found != null) 
  {
    return found;
  } 
  else if (_numColor.hasMatch(text)) 
  {
    switch (text.length) 
    {
      case 4:
      return int.parse("ff" + text[1] + text[1] + text[2] + text[2] + text[3] + text[3], radix: 16);
      case 5:
      return int.parse(text[1] + text[1] + text[2] + text[2] + text[3] + text[3] + text[4] + text[4], radix: 16);
      case 7:
      return int.parse("ff" + text.substring(1), radix: 16);
      case 9:
      return int.parse(text.substring(1), radix: 16);
      default:
      return defColor;
    }
  } 
  else 
  {
    return defColor;
  }
}

Color colorFormText(String text, [Color defColor = Colors.black]) 
{
  return Color(intColorFromText(text, defColor.value));
}