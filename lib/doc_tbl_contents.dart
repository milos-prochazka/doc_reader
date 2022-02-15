import 'package:flutter/cupertino.dart';

import 'document.dart';

class DocTableContents extends StatelessWidget
{
  const DocTableContents({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    final content = Document.of(context).documentContent;

    if (content != null)
    {
      return ListView.builder
      (
        itemBuilder: (context, index)
        {
          return Text('Item ${content.lines[index].text}');
        },
        itemCount: content.lines.length,
        cacheExtent: 256,
      );
    }
    else
    {
      return ListView.builder
      (
        itemBuilder: (context, index)
        {
          return Text('Item $index');
        },
        itemCount: 0
      );
    }
  }
}