import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';


class FileStorage {
  static Future<String> getExternalDocumentPath() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    Directory directory = Directory("dir");
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/Download/Project Orphans");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final exPath = directory.path;
    await Directory(exPath).create(recursive: true);
    return exPath;
  }

  static Future<String> get _localPath async {
    final String directory = await getExternalDocumentPath();
    return directory;
  }

  static Future<File> downloadAndSaveImage(String url) async {
    var response = await http.get(Uri.parse(url));
    Uint8List bytes = response.bodyBytes;

    // Generate a timestamp for the filename
    String timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

    String fileName = '${timestamp}_${basename(url)}';
    String filePath = join(await _localPath, fileName);
    File file = File(filePath);

    try {
      if (await file.exists()) {
        // If the file exists, delete it before writing the new data
        await file.delete();
      }

      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      rethrow;
    }
  }

}