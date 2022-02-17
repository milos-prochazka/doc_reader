import 'package:flutter/material.dart';

import 'document.dart';
import 'objects/applog.dart';

class DocTableContents extends StatefulWidget
{
  const DocTableContents({Key? key}) : super(key: key);

  @override
  State<DocTableContents> createState() => _DocTableContentsState();
}

class _DocTableContentsState extends State<DocTableContents>
{
  final _styles = <String, TextStyle>{};
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context)
  {
    return Container(color: const Color.fromARGB(128, 255, 244, 214), child: _buildList(context));
  }

  Widget _buildList(BuildContext context)
  {
    final content = Document.of(context).documentContent;

    return ListView.builder
    (
      itemBuilder: _lineBuild,
      itemCount: content?.lines.length ?? 0,
      cacheExtent: 256,
    );
  }

  TextStyle _style(DocumentContentLine line)
  {
    final styleName = '${line.level}-${line.title}';

    if (_styles.containsKey(styleName))
    {
      return _styles[styleName]!;
    }
    else
    {
      final style = TextStyle(fontSize: (20 - 3 * line.level.toDouble()));
      _styles[styleName] = style;
      return style;
    }
  }

  Widget _lineBuild(BuildContext context, int index)
  {
    final content = Document.of(context).documentContent;
    if (content != null)
    {
      final line = content.lines[index];

      return Container
      (
        color: index == selectedIndex ? Colors.amber : Colors.transparent,
        child: GestureDetector
        (
          child: Row
          (
            children:
            [
              Placeholder(fallbackWidth: line.level * 20, color: Colors.transparent, fallbackHeight: 1),
              Text
              (
                'Item ${line.text}',
                style: _style(line),
              )
            ],
          ),
          onTapDown: (_) => setState
          (
            ()
            {
              selectedIndex = index;
            }
          ),
          onTapCancel: () => setState
          (
            ()
            {
              selectedIndex = -1;
            }
          ),
          onTapUp: (_) => setState
          (
            ()
            {
              selectedIndex = -1;
            }
          ),
          onTap: ()
          {
            onClicked(index);
          },
        )
      );
    }
    else
    {
      return const Text('');
    }
  }

  onClicked(int index)
  {
    appLog('clicked: $index');
    final document = Document.of(context);
    final content = document.documentContent;

    if (content != null)
    {
      document.gotoParagraphId(content.lines[index].id);
    }
  }
}