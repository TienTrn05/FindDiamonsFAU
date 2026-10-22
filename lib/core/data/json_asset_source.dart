import 'dart:convert';

import 'package:flutter/services.dart';

class JsonAssetSource {
  const JsonAssetSource({this.bundle});

  final AssetBundle? bundle;

  Future<Map<String, dynamic>> read(String path) async {
    final decoded = jsonDecode(await (bundle ?? rootBundle).loadString(path));
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected a JSON object in $path');
    }
    return decoded;
  }
}
