import 'package:http/http.dart' as http;

http.Client createPlatformChatbotHttpClient({
  required Duration connectionTimeout,
  required Duration receiveTimeout,
}) {
  return http.Client();
}
