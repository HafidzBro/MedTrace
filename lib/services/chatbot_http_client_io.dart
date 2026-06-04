import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

http.Client createPlatformChatbotHttpClient({
  required Duration connectionTimeout,
  required Duration receiveTimeout,
}) {
  final client = HttpClient()
    ..connectionTimeout = connectionTimeout
    ..idleTimeout = receiveTimeout
    ..userAgent = 'MedTrace/1.0';
  return IOClient(client);
}
