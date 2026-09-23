import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/network/ai_http_client.dart';
import '../models/extracted_transaction_model.dart';

/// Sends a receipt image to the Flousi AI Cloudflare Worker, which runs the
/// vision model (and holds its API key), and returns a structured
/// [ExtractedTransaction].
Future<ExtractedTransaction?> extractTransactionFromImage(File image) async {
  try {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken == null) return null;

    final dataUri = await imageDataUri(image);

    final response = await postToAiWorker('extractReceipt', idToken, {
      'imageDataUri': dataUri,
    });
    if (response is! Map<String, dynamic>) {
      debugPrint('AI worker: no transaction extracted from receipt: $response');
      return null;
    }

    return ExtractedTransaction.fromJson(response);
  } catch (e) {
    debugPrint('AI worker receipt extraction error: $e');
    return null;
  }
}
