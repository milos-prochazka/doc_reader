
// ignore: non_constant_identifier_names
String enum_ToString(Object param)
{
    String str = param.toString();
    int i = str.indexOf('.');
    
    return (i>0) ? str.substring(i+1) : str;

}