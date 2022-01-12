import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum SpeechState { playing, stopped, paused, continued }

typedef SpeechEvent = Function(SpeechState oldState, SpeechState newState, String word, int start, int end);

class Speech
{
  FlutterTts? flutterTts;
  var speechState = SpeechState.stopped;
  double volume = 0.5;
  double pitch = 1.0;
  //double rate = 0.5;
  double rate = 0.7;
  bool _updateParameters = true;

  SpeechEvent? speechEvent;

  get isPlaying => speechState == SpeechState.playing;
  get isStopped => speechState == SpeechState.stopped;
  get isPaused => speechState == SpeechState.paused;
  get isContinued => speechState == SpeechState.continued;

  final isIOS = !kIsWeb && Platform.isIOS;
  final isAndroid = !kIsWeb && Platform.isAndroid;
  final isWeb = kIsWeb;

  init()
  {
    if (flutterTts == null)
    {
      final tts = FlutterTts();
      flutterTts = tts;

      _setAwaitOptions();

      tts.setStartHandler
      (
        ()
        {
          print("Playing");
          final old = speechState;
          speechState = SpeechState.playing;
          speechEvent?.call(old, speechState, '', 0, 0);
        }
      );

      tts.setCompletionHandler
      (
        ()
        {
          print("Complete");
          final old = speechState;
          speechState = SpeechState.stopped;
          speechEvent?.call(old, speechState, '', 0, 0);
        }
      );

      tts.setCancelHandler
      (
        ()
        {
          print("Cancel");
          final old = speechState;
          speechState = SpeechState.stopped;
          speechEvent?.call(old, speechState, '', 0, 0);
        }
      );

      if (isWeb || isIOS)
      {
        tts.setPauseHandler
        (
          ()
          {
            print("Paused");
            final old = speechState;
            speechState = SpeechState.paused;
            speechEvent?.call(old, speechState, '', 0, 0);
          }
        );

        tts.setContinueHandler
        (
          ()
          {
            print("Continued");
            final old = speechState;
            speechState = SpeechState.continued;
            speechEvent?.call(old, speechState, '', 0, 0);
          }
        );
      }

      tts.setErrorHandler
      (
        (msg)
        {
          print("error: $msg");
          final old = speechState;
          speechState = SpeechState.stopped;
          speechEvent?.call(old, speechState, '', 0, 0);
        }
      );

      tts.setProgressHandler
      (
        (text, start, end, word)
        {
          print("progress: $start $end $word");
          speechEvent?.call(speechState, speechState, word, start, end);
        }
      );
    }
  }

  Future _setAwaitOptions() async
  {
    await flutterTts?.awaitSpeakCompletion(true);
  }

  Future speak(String? text) async
  {
    init();
    if (flutterTts != null)
    {
      final tts = flutterTts!;

      if (_updateParameters)
      {
        await tts.setVolume(volume);
        await tts.setSpeechRate(rate);
        await tts.setPitch(pitch);
        await tts.setQueueMode(1);
      }

      if (text?.isNotEmpty ?? false)
      {
        await tts.speak(text!);
      }
    }
  }

  Future<bool> stop() async
  {
    return await flutterTts?.stop();
  }

  Future pause() async
  {
    return await flutterTts?.pause();
  }
}