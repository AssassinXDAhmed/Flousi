import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:file_picker/file_picker.dart';

import '../../domain/entities/transaction.dart';
import '../models/transaction_model.dart';

/// Imports a JSON file of transactions into the 'expenses' collection in
/// batches of 500. Ported verbatim from the legacy SeedService.
class SeedDataSource {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;

  Future<void> importTransactionsFromJson(String uid) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final content = file.bytes != null
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();
    final decoded = jsonDecode(content);
    final rawTransactions = _extractTransactionList(decoded);
    if (rawTransactions.isEmpty) {
      throw const FormatException('No transactions found in JSON file.');
    }

    final transactions = rawTransactions
        .map((raw) => _transactionFromSeed(raw, uid))
        .toList(growable: false);

    for (var i = 0; i < transactions.length; i += 500) {
      final batch = _firestore.batch();
      final chunk = transactions.skip(i).take(500);
      for (final transaction in chunk) {
        final docRef = _firestore.collection('expenses').doc();
        final transactionToSave = Transaction(
          id: docRef.id,
          uid: uid,
          amount: transaction.amount,
          catagory: transaction.catagory,
          paymentmethod: transaction.paymentmethod,
          createdAt: transaction.createdAt,
          description: transaction.description,
          isIncome: transaction.isIncome,
        );
        batch.set(docRef, TransactionModel(transactionToSave).toMap());
      }
      await batch.commit();
    }
  }

  List<Map<String, dynamic>> _extractTransactionList(dynamic decoded) {
    final dynamic source = decoded is Map<String, dynamic>
        ? decoded['transactions'] ?? decoded['expenses'] ?? decoded['data']
        : decoded;
    if (source is! List) return [];
    return source
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Transaction _transactionFromSeed(Map<String, dynamic> json, String uid) {
    return Transaction(
      id: '',
      uid: uid,
      amount: _parseAmount(json['amount']),
      catagory:
          (json['catagory'] ?? json['category'] ?? 'uncategorized').toString(),
      paymentmethod: _parsePaymentMethod(json['paymentmethod'] ?? json['method']),
      createdAt: _parseDate(json['createdAt'] ?? json['date']),
      description: (json['description'] ?? json['note'])?.toString(),
      isIncome: json['isIncome'] == true,
    );
  }

  double _parseAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  PaymentMethod _parsePaymentMethod(dynamic value) {
    final normalized = value?.toString().toLowerCase() ?? '';
    return PaymentMethod.values.firstWhere(
      (method) => method.name == normalized,
      orElse: () => PaymentMethod.cash,
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is int) {
      final isMilliseconds = value > 9999999999;
      return DateTime.fromMillisecondsSinceEpoch(
        isMilliseconds ? value : value * 1000,
      );
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
