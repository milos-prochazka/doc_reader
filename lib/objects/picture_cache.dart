import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doc_reader/objects/applog.dart';
import 'package:flutter/services.dart';

class PictureCache
{
  static PictureCache? _instance;

  final cache = <String, PictureCacheInfo>{};
  final providers = <IPictureProvider>[];
  late Timer timer;

  PictureCache._()
  {
    providers.add(DefaultPictureProvider());
    timer = Timer.periodic(const Duration(seconds: 10), _timerCallback);
  }

  factory PictureCache()
  {
    _instance ??= PictureCache._();

    return _instance!;
  }

  IPictureProvider _provider(String imageSource)
  {
    return providers.lastWhere((provider) => provider.usableSource(imageSource));
  }

  PictureCacheInfo getOrCreateInfo(String imageSource)
  {
    final imgInfo = cache[imageSource];

    if (imgInfo != null)
    {
      imgInfo.use = true;
      return imgInfo;
    }
    else
    {
      final imgInfo = PictureCacheInfo();
      cache[imageSource] = imgInfo;
      return imgInfo;
    }
  }

  bool _asyncImageSource(String imageSource) => _provider(imageSource).asyncSource(imageSource);

  bool hasImageInfo(String imageSource) => cache[imageSource]?.hasInfo ?? false;

  PictureCacheInfo imageInfo(String imageSource)
  {
    final imgInfo = getOrCreateInfo(imageSource);

    if (!imgInfo.hasInfo)
    {
      imgInfo.setImage(_provider(imageSource).loadSource(imageSource));
    }

    return imgInfo;
  }

  Future<PictureCacheInfo> imageInfoAsync(String imageSource) async
  {
    final imgInfo = getOrCreateInfo(imageSource);

    if (!imgInfo.hasInfo)
    {
      imgInfo.setImage(await _provider(imageSource).loadSourceAsync(imageSource));
    }

    return imgInfo;
  }

  bool hasImage(String imageSource) => cache[imageSource]?.image != null;

  ui.Image? image(String imageSource)
  {
    return imageInfo(imageSource).image;
  }

  Future<ui.Image?> imageAsync(String imageSource) async
  {
    final imgInfo = getOrCreateInfo(imageSource);

    if (imgInfo.image == null)
    {
      imgInfo.setImage(await _provider(imageSource).loadSourceAsync(imageSource));
    }

    return imgInfo.image;
  }

  void _timerCallback(Timer timer)
  {
    for (var info in cache.values)
    {
      if (info.image != null)
      {
        if (info.use)
        {
          info.use = false;
        }
        else
        {
          info.image = null;
        }
      }
    }
  }
}

class PictureCacheInfo
{
  ui.Image? image;
  double width = double.nan;
  double height = double.nan;
  bool use = true;

  bool get hasInfo => !width.isNaN && !height.isNaN;

  void setImage(ui.Image? image)
  {
    this.image = image;
    if (image == null)
    {
      width = double.nan;
      height = double.nan;
    }
    else
    {
      width = image.width.toDouble();
      height = image.height.toDouble();
    }
  }
}

abstract class IPictureProvider
{
  bool usableSource(String imageSource);
  bool asyncSource(String imageSource);
  ui.Image? loadSource(String imageSource);
  Future<ui.Image?> loadSourceAsync(String imageSource);
}

class DefaultPictureProvider extends IPictureProvider
{
  @override
  bool asyncSource(String imageSource)
  {
    return true;
  }

  @override
  ui.Image? loadSource(String imageSource)
  {
    throw UnimplementedError();
  }

  @override
  Future<ui.Image?> loadSourceAsync(String imageSource) async
  {
    try
    {
      final ByteData data = await rootBundle.load(imageSource);

      final Completer<ui.Image> completer = Completer();
      ui.decodeImageFromList
      (
        Uint8List.view(data.buffer), (ui.Image img)
        {
          return completer.complete(img);
        }
      );
      return completer.future;
    }
    catch (e)
    {
      appLogEx(e);
      return null;
    }
  }

  @override
  bool usableSource(String imageSource)
  {
    return true;
  }
}