import 'dart:convert';

import 'package:http/http.dart' as http;

/// The backend answered, but refused the request (wrong PIN, not enough stock, and so on).
class BackendException implements Exception {
  BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sends one JSON request to the Apps Script web app and returns the reply's data.
/// The body goes out as text/plain so the browser build does not need a CORS preflight.
/// Apps Script answers a POST with a redirect; the http package follows it with a GET,
/// which is how Apps Script returns the result.
class BackendClient {
  BackendClient({required this.base_url, http.Client? http_client})
      : _http = http_client ?? http.Client();

  final String base_url;
  final http.Client _http;

  /// Kept in memory only, for the signed-in session. Cleared on sign-out.
  String? user_id;
  String? pin;

  Future<Object?> call(String action, [Map<String, Object?> params = const {}]) async {
    final body = <String, Object?>{
      'action': action,
      'params': params,
      if (user_id != null) 'user_id': user_id,
      if (pin != null) 'pin': pin,
    };
    final response = await _http
        .post(
          Uri.parse(base_url),
          headers: {'Content-Type': 'text/plain; charset=utf-8'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw BackendException('The shop server answered ${response.statusCode}');
    }
    final reply = jsonDecode(response.body) as Map<String, dynamic>;
    if (reply['ok'] != true) {
      throw BackendException(reply['error']?.toString() ?? 'Unknown error');
    }
    return reply['data'];
  }
}
