import 'top_buttons.dart';
import 'package:flutter/material.dart';

class TopButton extends StatefulWidget
{
  final GestureTapCallback? onTap;
  final double relativeWidth;
  final String text;
  final String image;
  final Color foregroundColor;
  final Color backgroundColor;

  TopButton
  (
    {this.onTap,
      this.relativeWidth = 1.0,
      this.text = 'Text',
      this.image = 'resources/biglock_btn_close.png',
      this.foregroundColor = Colors.white,
      this.backgroundColor = Colors.black}
  );

  static TopButtonItem createItem
  (
    {String? id, required TopButtonType type, String text = 'Text', double relativeWidth = 1.0}
  )
  {
    return TopButtonItem
    (
      id: id,
      type: type,
      relativeWidth: relativeWidth,
      builder: (context, item)
      {
        return TopButton
        (
          relativeWidth: relativeWidth,
          text: text,
          backgroundColor: item.backgroundColor,
          foregroundColor: item.foregroundColor,
          onTap: ()
          {
            final param = TopButtonCmd();

            param.id = item.id ?? '?';
            param.cmdType = TopButtonCmdType.click;

            item.event!(param);
          },
        );
      }
    );
  }

  @override
  State<StatefulWidget> createState()
  {
    return _TopButtonState(this);
  }
}

class _TopButtonState extends State<TopButton>
{
  TopButton widget;
  bool _down = false;

  _TopButtonState(this.widget);

  @override
  Widget build(BuildContext context)
  {
    return GestureDetector
    (
      // ------------------------------------------------ //
      onTapDown: (tap)
      {
        setState
        (
          ()
          {
            _down = true;
          }
        );
      },
      // ------------------------------------------------ //
      onTapCancel: ()
      {
        setState
        (
          ()
          {
            _down = false;
          }
        );
      },
      // ------------------------------------------------ //
      onTapUp: (tap)
      {
        setState
        (
          ()
          {
            _down = false;
          }
        );
      },
      // ------------------------------------------------ //
      onTap: ()
      {
        widget.onTap?.call();
      },
      // ------------------------------------------------ //
      child: OrientationBuilder
      (
        builder: (context, orientation)
        {
          final buttonWidth = widget.relativeWidth * (orientation == Orientation.landscape ? 400.0 : 200.0);
          final buttonHeight = 200.0;
          return Container
          (
            height: buttonHeight,
            width: buttonWidth,
            decoration: BoxDecoration
            (
              //borderRadius: BorderRadius.circular(10),
              color: widget.backgroundColor,
              border: Border.all
              (
                color: Colors.transparent,
                width: 8,
              ),
            ),
            // /---------------------------------------

            // ----------------------------------------
            child: Container
            (
              decoration: BoxDecoration
              (
                borderRadius: BorderRadius.circular(10),
                color: Colors.transparent,
                border: Border.all(color: widget.foregroundColor, width: 4)
              ),
              foregroundDecoration: BoxDecoration(color: Color(_down ? 0x6000CCFF : 0x00000000)),
              child: FittedBox
              (
                fit: BoxFit.contain,
                child: Center
                (
                  child: Column
                  (
                    children: <Widget>
                    [
                      Text
                      (
                        widget.text,
                        style: TextStyle(color: widget.foregroundColor, fontSize: 40),
                      ),
                      Padding
                      (
                        padding: EdgeInsets.all(5),
                        child: Image
                        (
                          image: AssetImage(widget.image),
                          color: widget.foregroundColor,
                          filterQuality: FilterQuality.high,
                          height: 60,
                          width: 60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ----------------------------------------
          );
        }
      )
    );
  }
}