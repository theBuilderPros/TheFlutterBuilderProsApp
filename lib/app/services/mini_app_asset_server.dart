import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class MiniAppAssetServer {
  HttpServer? _server;

  Future<Uri> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    unawaited(_serve());
    return Uri.parse('http://${_server!.address.address}:${_server!.port}/');
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }

  Future<void> _serve() async {
    final server = _server;
    if (server == null) return;

    await for (final request in server) {
      final path = request.uri.path == '/' ? '/index.html' : request.uri.path;
      final assetKey = 'assets/mini_app$path';

      try {
        final bytes = await rootBundle.load(assetKey);
        request.response.headers.contentType = _contentType(path);
        request.response.add(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
      } catch (_) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.text;
        request.response.write('Mini app asset not found');
      } finally {
        await request.response.close();
      }
    }
  }

  ContentType _contentType(String path) {
    if (path.endsWith('.html')) {
      return ContentType.html;
    }
    if (path.endsWith('.js')) {
      return ContentType('application', 'javascript', charset: 'utf-8');
    }
    if (path.endsWith('.css')) {
      return ContentType('text', 'css', charset: 'utf-8');
    }
    if (path.endsWith('.json')) {
      return ContentType.json;
    }
    if (path.endsWith('.svg')) {
      return ContentType('image', 'svg+xml');
    }
    if (path.endsWith('.png')) {
      return ContentType('image', 'png');
    }
    return ContentType.binary;
  }
}
