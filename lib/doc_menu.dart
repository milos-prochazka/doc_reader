import 'document.dart';
import 'objects/applog.dart';
import 'property_binder.dart';
import 'top_button/top_buttons.dart';
import 'top_button/topbutton.dart';
import 'package:flutter/material.dart';

class DocMenu
{
  TopButtons? topButtons;

  playStart()
  {
    appLog('playStart');
  }

  Widget build(BuildContext context)
  {
    final document = Document.of(context);

    if (document != null)
    {
      final result = TopButtons
      (
        [
          TopButton.createItem(id: 'a', type: TopButtonType.top, relativeWidth: 1, text: 'Tmavý'),
          TopButton.createItem(id: 'a', type: TopButtonType.top, relativeWidth: 1, text: 'Založky'),
          TopButton.createItem(id: 'content', type: TopButtonType.top, relativeWidth: 1, text: 'Obsah'),
          TopButton.createItem(id: 'c', type: TopButtonType.top, relativeWidth: 1, text: 'Hledat'),
          TopButton.createItem(id: 'd', type: TopButtonType.top, relativeWidth: 1, text: 'Nastavení'),
          TopButton.createItem(id: 'play', type: TopButtonType.bottom, relativeWidth: 1, text: ' Číst '),
          TopButton.createItem(id: 'e', type: TopButtonType.bottom, relativeWidth: 1, text: 'Tlac B3'),
        ],
        key: UniqueKey(),
        backgroundColor: Color.fromARGB(0xcc, 0x20, 0x40, 0x40),
        foregroundColor: Colors.white70,
        event: (param)
        {
          /*PropertyBinder.doOnProperty
          (
            context, 'cnt', (binder, property)
            {
              var cnt = property.valueT(0.0);
              property.setValue(binder, cnt + 1);
            }
          );*/
          //topButtons?.control.visible = false;

          switch (param.id)
          {
            default:
            {
              topButtons?.control.hideAction
              (
                param, (param)
                {
                  var newMode = DocumentShowMode.normal;

                  switch (param.id)
                  {
                    case 'play':
                    playStart();
                    break;

                    case 'content':
                    newMode = DocumentShowMode.content;
                    break;
                  }

                  document.mode = newMode;
                }
              );
            }
            break;
          }
        },
      );

      result.control.hideEvent = (cmd) => document.mode = DocumentShowMode.normal;

      topButtons = result;

      return result;
    }
    else
    {
      return Stack();
    }
  }
}