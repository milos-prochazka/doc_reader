
// ignore: non_constant_identifier_names
String enum_ToString(Object param)
{
    String str = param.toString();
    int i = str.indexOf('.');
    
    return (i>0) ? str.substring(i+1) : str;
}


String numberToCharacters(int param,String charList)
{
   String result = '';
   int n = charList.length;

   do
   {
      var x = param % n;
      param ~/= n;
      if (result.isNotEmpty && param==0)
      {
        x--;
      }
      result = charList.substring(x,x+1)+result;
   }
   while (param>0);

   return result;
}
