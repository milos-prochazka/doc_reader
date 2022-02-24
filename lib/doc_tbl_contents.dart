import 'package:flutter/material.dart';

import 'document.dart';
import 'objects/applog.dart';
import 'objects/config.dart';
import 'objects/json_utils.dart';

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
  double opacity = 0.0;
  bool init = true;
  bool clicked = false;

  @override
  void initState()
  {
    super.initState();
    init = true;
    clicked = false;
  }

  @override
  Widget build(BuildContext context)
  {
    final document = Document.of(context);

    if (init)
    {
      init = false;
      Future.microtask
      (
        () => setState
        (
          ()
          {
            opacity = 1.0;
          }
        )
      );
    }
    final duration = (opacity > 0.5) ? 250 : 500;

    return AnimatedOpacity
    (
      opacity: opacity,
      duration: Duration(milliseconds: duration),
      onEnd: ()
      {
        if (clicked) document.mode = DocumentShowMode.normal;
      },
      child: Container(color: const Color.fromARGB(255, 255, 244, 214), child: _buildList(context))
    );
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
    final styleName = '${line.title ? 'title' : 'h'}${line.level}';

    if (_styles.containsKey(styleName))
    {
      return _styles[styleName]!;
    }
    else
    {
      final styleCfg = Config.instance.getOrCreateMap(['contents', styleName]);

      final size = JsonUtils.getValue(styleCfg, 'size', 10.0);
      final italic = JsonUtils.getValue(styleCfg, 'italic', false) ? FontStyle.italic : FontStyle.normal;
      final weight = JsonUtils.getValue(styleCfg, 'bold', false) ? FontWeight.bold : FontWeight.normal;
      final decor = JsonUtils.getValue(styleCfg, 'underline', false) ? TextDecoration.underline : TextDecoration.none;

      final style = TextStyle
      (
        fontSize: size,
        fontStyle: italic,
        fontWeight: weight,
        decoration: decor,
        height: 3.0,
        textBaseline: TextBaseline.alphabetic
      );
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
    if (!clicked)
    {
      clicked = true;

      appLog('clicked: $index');

      final document = Document.of(context);
      final content = document.documentContent;

      setState
      (
        ()
        {
          opacity = 0.0;
        }
      );

      if (content != null)
      {
        document.gotoParagraphId(content.lines[index].id);
      }
    }
  }
}