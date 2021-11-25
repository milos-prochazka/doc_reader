import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:doc_reader/objects/applog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_svg/flutter_svg.dart';

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

  Future<PictureCacheInfo?> imageAsync(String imageSource) async
  {
    final imgInfo = getOrCreateInfo(imageSource);

    if (!imgInfo.hasPicture)
    {
      imgInfo.setImage(await _provider(imageSource).loadSourceAsync(imageSource));

      if (!imgInfo.hasPicture)
      {
        throw ImageCacheException('Picture $imageSource is not loaded');
      }
    }

    return imgInfo;
  }

  void _timerCallback(Timer timer)
  {
    for (var info in cache.values)
    {
      if (info.hasPicture)
      {
        if (info.use)
        {
          info.use = false;
        }
        else
        {
          info.image = null;
          print("CACHE CLEAR");
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

  bool get hasPicture => image != null;
  bool get hasImage => image != null;
  bool get hasDrawable => false;

  void setImage(Object? image)
  {
    if (image is ui.Image)
    {
      this.image = image;
      width = image.width.toDouble();
      height = image.height.toDouble();
    }
    else if (image is DrawableRoot)
    {
      final drw = image as DrawableRoot;

      width = image.viewport.viewBox.width;
      height = image.viewport.viewBox.height;
    }
    else
    {
      width = double.nan;
      height = double.nan;
    }
  }
}

abstract class IPictureProvider
{
  bool usableSource(String imageSource);
  bool asyncSource(String imageSource);
  Object? loadSource(String imageSource);
  Future<Object?> loadSourceAsync(String imageSource);
}

class DefaultPictureProvider extends IPictureProvider
{
  @override
  bool asyncSource(String imageSource)
  {
    return true;
  }

  @override
  Object? loadSource(String imageSource)
  {
    throw UnimplementedError();
  }

  @override
  Future<Object?> loadSourceAsync(String imageSource) async
  {
    try
    {
      switch (path.extension(imageSource))
      {
        case '.svg':
        case '.xml':
        {
          final svgText = await rootBundle.loadString(imageSource);
          return svg.fromSvgString(svgText, imageSource);
        }

        default:
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
      }
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

class ImageCacheException implements Exception
{
  final dynamic message;

  ImageCacheException([this.message]);

  @override
  String toString()
  {
    Object? message = this.message;
    if (message == null) return "ImageCacheException";
    return "ImageCacheException: $message";
  }
}