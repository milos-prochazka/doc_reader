import 'package:doc_reader/document.dart';
import 'package:doc_reader/property_binder.dart';
import 'package:doc_reader/top_button/top_buttons.dart';
import 'package:doc_reader/top_button/topbutton.dart';
import 'package:flutter/material.dart';

class DocMenu
{
  TopButtons? topButtons;

  Widget build(BuildContext context)
  {
    final binder = PropertyBinder.of(context);
    final document = binder.getProperty<Document?>(Document.documentProperty, null);

    if (document != null)
    {
      final result = TopButtons
      (
        [
          TopButton.createItem(id: 'b', type: TopButtonType.top, relativeWidth: 1, text: 'Tmavý'),
          TopButton.createItem(id: 'a', type: TopButtonType.top, relativeWidth: 1, text: 'Založky'),
          TopButton.createItem(id: 'b', type: TopButtonType.top, relativeWidth: 1, text: 'Obsah'),
          TopButton.createItem(id: 'b', type: TopButtonType.top, relativeWidth: 1, text: 'Hledat'),
          TopButton.createItem(id: 'a', type: TopButtonType.top, relativeWidth: 1, text: 'Nastavení'),
          TopButton.createItem(id: 'c', type: TopButtonType.bottom, relativeWidth: 1, text: 'Tlac B2'),
          TopButton.createItem(id: 'd', type: TopButtonType.bottom, relativeWidth: 1, text: 'Tlac B3'),
        ],
        backgroundColor: Color.fromARGB(0xcc, 0x20, 0x40, 0x40),
        foregroundColor: Colors.white70,
        event: (param)
        {
          PropertyBinder.doOnProperty
          (
            context, 'cnt', (binder, property)
            {
              var cnt = property.valueT(0.0);
              property.setValue(binder, cnt + 1);
            }
          );
          topButtons?.control.visible = false;

          /*var i = param.cmdType;
                  PropertyBinder.doOn
                  (
                    context, (binder)
                    {
                      var c = binder.getProperty('cnt', 0.0);
                      binder.setProperty('cnt', c + 1.0);
                    }
                  );*/
        },
      );

      topButtons = result;
      return result;
    }
    else
    {
      return Stack();
    }
  }
}