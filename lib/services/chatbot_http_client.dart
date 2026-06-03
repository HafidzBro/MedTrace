import 'package:http/http.dart' as http;

import 'chatbot_http_client_stub.dart'
    if (dart.library.io) 'chatbot_http_client_io.dart';

http.Client createChatbotHttpClient({
  required Duration connectionTimeout,
  required Duration receiveTimeout,
}) {
  return createPlatformChatbotHttpClient(
    connectionTimeout: connectionTimeout,
    receiveTimeout: receiveTimeout,
  );
}
