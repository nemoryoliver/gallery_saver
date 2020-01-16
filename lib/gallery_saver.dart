import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/files.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class GallerySaver {
  static const String channelName = 'gallery_saver';
  static const String methodSaveImage = 'saveImage';
  static const String methodSaveVideo = 'saveVideo';

  static const String pleaseProvidePath = 'Please provide valid file path.';
  static const String fileIsNotVideo = 'File on path is not a video.';
  static const String fileIsNotImage = 'File on path is not an image.';
  static const MethodChannel _channel = const MethodChannel(channelName);

  ///saves video from provided temp path and optional album name in gallery
  static Future<bool> saveVideo(String path,
      {String albumName,
      String downloadPath,
      ProgressCallback progressCallback}) async {
    File tempFile;
    if (path == null || path.isEmpty) {
      throw ArgumentError(pleaseProvidePath);
    }
    if (!isVideo(path)) {
      var ok = await satisfyContentType(path, "video");
      if (!ok) {
        throw ArgumentError(fileIsNotVideo);
      }
    }
    if (!isLocalFilePath(path)) {
      tempFile =
          await _downloadFile(path, "video", downloadPath, progressCallback);
      path = tempFile.path;
    }
    bool result = await _channel.invokeMethod(
      methodSaveVideo,
      <String, dynamic>{'path': path, 'albumName': albumName},
    );
    if (tempFile != null) {
      tempFile.delete();
    }
    return result;
  }

  ///saves image from provided temp path and optional album name in gallery
  static Future<bool> saveImage(String path,
      {String albumName,
      String downloadPath,
      ProgressCallback progressCallback}) async {
    File tempFile;
    if (path == null || path.isEmpty) {
      throw ArgumentError(pleaseProvidePath);
    }
    if (!isImage(path)) {
      var ok = await satisfyContentType(path, "image");
      if (!ok) {
        throw ArgumentError(fileIsNotImage);
      }
    }
    if (!isLocalFilePath(path)) {
      tempFile =
          await _downloadFile(path, "image", downloadPath, progressCallback);
      path = tempFile.path;
    }

    bool result = await _channel.invokeMethod(
      methodSaveImage,
      <String, dynamic>{'path': path, 'albumName': albumName},
    );
    if (tempFile != null) {
      tempFile.delete();
    }

    return result;
  }

  static Future<File> _downloadFile(
      String url, String type, String dir, progressCallback) async {
    print(url);
    if (dir == null || dir.isEmpty) {
      dir = (await getTemporaryDirectory()).path;
    }

    var fileName = url;
    var uri = Uri.parse(fileName);
    fileName = fileName.replaceAll(uri.query, "");
    if (fileName.endsWith("?")) {
      fileName = fileName.substring(0, fileName.length - 1);
    }

    if (fileName.isEmpty) {
      fileName = DateTime.now().millisecondsSinceEpoch.toString();
    }

    if (type == "video") {
      if (!fileName.endsWith(".mp4")) {
        fileName += ".mp4";
      }
    }

    String savePath = '$dir/${basename(fileName)}';
    print(savePath);

    var dio = Dio();
    await dio.download(
      url, savePath,
      options: Options(
          headers: {HttpHeaders.acceptEncodingHeader: "*"}), // disable gzip
      onReceiveProgress: progressCallback == null
          ? (received, total) {
              if (total != -1) {
                print((received / total * 100).toStringAsFixed(0) + "%");
              }
            }
          : progressCallback,
    );

    return File(savePath);
  }

  static Future<bool> satisfyContentType(String url, String type) async {
    var dio = Dio();
    var resp = await dio.get(url);
    var contentType = resp.headers.value("Content-Type");

    if (type == "video") {
      if (contentType.contains("video") || contentType.contains("audio")) {
        return true;
      }
    } else if (type == "image") {
      if (contentType.contains("image")) {
        return true;
      }
    }
  }
}
