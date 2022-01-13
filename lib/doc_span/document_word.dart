// ignore_for_file: constant_identifier_names

import 'dart:ui';

class DocumentWordInfo
{
  static const TTS_SPEECH_END = 0;
  static const TTS_SPEECH = -1;
  static const TTS_IGNORE = -2;

  String? text;
  Rect rect = Rect.zero;
  int id = -1;
  int ttsBehavior = TTS_SPEECH;

  bool get isTssEnd => ttsBehavior >= TTS_SPEECH_END;
  bool get isPause => ttsBehavior > TTS_SPEECH_END;
  int get pause => ttsBehavior;

  translate(double xOffset, double yOffset)
  {
    rect = rect.translate(xOffset, yOffset);
  }
}