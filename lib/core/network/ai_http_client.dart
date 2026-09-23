import 'dart:convert';
import 'dart:io';

import 'worker_config.dart';

/// Shared HTTP client for the Flousi AI Cloudflare Worker. The worker holds
/// the AI provider API keys server-side — the app never sees them.
///
/// [idToken] is the signed-in user's Firebase ID token; the worker verifies it
/// before forwarding anything to an AI provider.
///
/// Returns the decoded JSON body (the worker returns `null` when the model
/// produced no usable output), or throws on a non-2xx response or timeout.
Future<Object?> postToAiWorker(
  String endpoint,
  String idToken,
  Map<String, dynamic> body, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final client = HttpClient();
  try {
    return await _send(client, endpoint, idToken, body).timeout(timeout);
  } finally {
    client.close(force: true);
  }
}

Future<Object?> _send(
  HttpClient client,
  String endpoint,
  String idToken,
  Map<String, dynamic> body,
) async {
  final uri = aiWorkerUri(endpoint);
  final request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $idToken');
  request.write(jsonEncode(body));

  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'AI worker request failed (${response.statusCode}): $responseBody',
      uri: uri,
    );
  }

  return jsonDecode(responseBody);
}

Uri aiWorkerUri(String endpoint) {
  final normalizedBaseUrl = cloudflareWorkerUrl.endsWith('/')
      ? cloudflareWorkerUrl.substring(0, cloudflareWorkerUrl.length - 1)
      : cloudflareWorkerUrl;
  return Uri.parse('$normalizedBaseUrl/$endpoint');
}

/// Converts an image file into a base64 data URI for vision model payloads.
Future<String> imageDataUri(File image) async {
  final bytes = await image.readAsBytes();
  final mimeType = mimeTypeForImage(image.path);
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

String mimeTypeForImage(String path) {
  final lowerPath = path.toLowerCase();
  if (lowerPath.endsWith('.png')) return 'image/png';
  if (lowerPath.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
