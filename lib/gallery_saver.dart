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
      throw ArgumentError(fileIsNotVideo);
    }
    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(path, downloadPath, progressCallback);
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
      throw ArgumentError(fileIsNotImage);
    }
    if (!isLocalFilePath(path)) {
      tempFile = await _downloadFile(path, downloadPath, progressCallback);
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
      String url, String dir, progressCallback) async {
    print(url);
    if (dir == null || dir.isEmpty) {
      dir = (await getTemporaryDirectory()).path;
    }
    String savePath = '$dir/${basename(url)}';
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

    // http.Client _client = new http.Client();
    // var resp = await _client.get(Uri.parse(url));
    // var bytes = resp.bodyBytes;

    // File file = new File('$dir/${basename(url)}');
    // await file.writeAsBytes(bytes);
    // print('File size:${await file.length()}');
    return File(savePath);
  }
}
