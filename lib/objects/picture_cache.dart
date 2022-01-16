// ignore_for_file: unnecessary_this

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';

import 'applog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/avd.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as path;

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

  bool asyncImageSource(String imageSource) => _provider(imageSource).asyncSource(imageSource);

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
      try
      {
        while (imgInfo.asyncLock)
        {
          await Future.delayed(const Duration(milliseconds: 20));
        }

        if (!imgInfo.hasInfo)
        {
          imgInfo.asyncLock = true;
          imgInfo.setImage(await _provider(imageSource).loadSourceAsync(imageSource));
        }
      }
      finally
      {
        imgInfo.asyncLock = false;
      }
    }

    return imgInfo;
  }

  bool hasImage(String imageSource) => cache[imageSource]?.image != null;

  ui.Image? image(String imageSource)
  {
    return imageInfo(imageSource).image;
  }

  Future<PictureCacheInfo> imageAsync(String imageSource) async
  {
    final imgInfo = getOrCreateInfo(imageSource);

    if (!imgInfo.hasPicture)
    {
      try
      {
        while (imgInfo.asyncLock)
        {
          await Future.delayed(const Duration(milliseconds: 20));
        }

        if (!imgInfo.hasPicture)
        {
          imgInfo.asyncLock = true;
          imgInfo.setImage(await _provider(imageSource).loadSourceAsync(imageSource));
        }
      }
      finally
      {
        imgInfo.asyncLock = false;
      }

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
          info.clear();
          print('CACHE CLEAR');
        }
      }
    }
  }
}

class PictureCacheInfo
{
  bool asyncLock = false;
  ui.Image? image;
  DrawableRoot? drawableRoot;
  double width = double.nan;
  double height = double.nan;
  bool use = true;
  Map<int, ui.Image>? sizedImages;

  bool get hasInfo => !width.isNaN && !height.isNaN;

  bool get hasPicture => hasImage | hasDrawable;
  bool get hasImage => image != null;
  bool get hasDrawable => drawableRoot != null;

  PictureCacheInfo();

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
      this.drawableRoot = image;
      width = image.viewport.viewBox.width;
      height = image.viewport.viewBox.height;
    }
    else
    {
      width = double.nan;
      height = double.nan;
    }
  }

  ui.Image? getSizedImage(int width, int height)
  {
    final int sizeDescriptor = width + (height << 16);

    return sizedImages?[sizeDescriptor];
  }

  Future<ui.Image?> makeSizedImage(int width, int height) async
  {
    final int sizeDescriptor = width + (height << 16);

    ui.Image? result = sizedImages?[sizeDescriptor];

    if (result == null && hasDrawable)
    {
      final picture = drawableRoot?.toPicture(size: Size(width.toDouble(), height.toDouble()));
      result = await picture!.toImage(width, height);
      sizedImages ??= <int, ui.Image>{};
      sizedImages?[sizeDescriptor] = result;
    }

    return result;
  }

  void clear()
  {
    image = null;
    drawableRoot = null;
    sizedImages = null;
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
    final imgPath = imageSource.replaceAll('\\', '/');

    try
    {
      switch (path.extension(imgPath))
      {
        case '.svg':
        {
          final svgText = await rootBundle.loadString(imgPath);
          return svg.fromSvgString(svgText, imgPath);
        }

        case '.xml':
        {
          final avdText = await rootBundle.loadString(imgPath);
          return avd.fromAvdString(avdText, imgPath);
        }

        default:
        {
          final ByteData data = await rootBundle.load(imgPath);

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
    catch (ex, stackTrace)
    {
      appLogEx(ex, stackTrace: stackTrace);
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
    if (message == null) return 'ImageCacheException';
    return 'ImageCacheException: $message';
  }
}