import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/categories/domain/entities/category.dart';
import 'package:firstrproject/features/categories/presentation/providers/category_provider.dart';
import 'package:firstrproject/features/receipt_ai/data/datasources/receipt_remote_data_source.dart';
import 'package:firstrproject/features/transactions/domain/entities/transaction.dart';
import 'package:firstrproject/features/transactions/presentation/providers/transaction_provider.dart';

enum TransactionType { expense, income }

class AddTransactionSheet extends StatefulWidget {
  final TransactionType initialType;
  final Transaction? existingTransaction;

  const AddTransactionSheet({super.key, this.initialType = TransactionType.expense, this.existingTransaction});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TextEditingController _amountController;
  final _noteController = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  String _selectedCategory = 'groceries';
  bool _isScanning = false;
  late TransactionType _type;
  late DateTime _selectedDate;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      final t = widget.existingTransaction!;
      _type = t.isIncome ? TransactionType.income : TransactionType.expense;
      _amountController = TextEditingController(text: t.amount.toString());
      _noteController.text = t.description ?? '';
      _method = t.paymentmethod;
      _selectedCategory = t.catagory == 'income' ? 'groceries' : t.catagory;
      _selectedDate = t.createdAt;
    } else {
      _type = widget.initialType;
      _amountController = TextEditingController(text: '0.00');
      _selectedDate = DateTime.now();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: AppTheme.bgDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        // Keep the current time for the newly selected date
        final now = DateTime.now();
        _selectedDate = DateTime(picked.year, picked.month, picked.day, now.hour, now.minute, now.second);
      });
    }
  }

  Future<String> _getTessDataPath() async {
    final tessdataPath = await FlutterTesseractOcr.getTessdataPath();
    final file = File('$tessdataPath/ara.traineddata');

    if (!await file.exists()) {
      await Directory(tessdataPath).create(recursive: true);
      final data = await rootBundle.load('assets/tessdata/ara.traineddata');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await file.writeAsBytes(bytes);
    }
    return tessdataPath;
  }

  void _appendScannedTextToNotes(String text) {
    final scannedText = text.trim();
    if (scannedText.isEmpty) return;

    final currentNote = _noteController.text.trim();
    _noteController.text = currentNote.isEmpty ? scannedText : '$currentNote\n$scannedText';
    _noteController.selection = TextSelection.collapsed(offset: _noteController.text.length);
  }

  Future<void> _scanReceipt() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    // Downscaled: the photo is uploaded to the AI worker, and 2048px keeps
    // receipt text legible at a fraction of a full-resolution photo's size.
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      final result = await extractTransactionFromImage(File(image.path));
      if (result != null) {
        _amountController.text = result.amount.toString();
        _noteController.text = result.note;
        _noteController.selection =
            TextSelection.collapsed(offset: _noteController.text.length);
        _selectedCategory = result.category.toLowerCase();
        _method = result.method == 'CASH' ? PaymentMethod.cash : PaymentMethod.card;
        _type = TransactionType.expense;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noTextFound)));
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _performHardwareOCR() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        final text = recognizedText.text;
        if (text.trim().isNotEmpty) {
          _appendScannedTextToNotes(text);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noTextFound)));
        }
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      debugPrint('OCR Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ocrError(e.toString()))));
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _performArabicOCR() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (image == null) return;

    setState(() => _isScanning = true);

    try {
      await _getTessDataPath();
      String text = await FlutterTesseractOcr.extractText(
        image.path,
        language: 'ara',
        args: {"psm": "3", "preserve_interword_spaces": "1"},
      );

      if (text.trim().isNotEmpty) {
        _appendScannedTextToNotes(text);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noArabicTextFound)));
      }
    } catch (e) {
      debugPrint('Arabic OCR Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.ocrError(e.toString()))));
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final categories = context.read<CategoryProvider>().categories;
    final fallbackCat = categories.isNotEmpty ? categories.first : const Category(id: '', name: '', icon: Icons.error, color: Colors.grey);

    final transaction = Transaction(
      id: widget.existingTransaction?.id ?? '', // Keeps ID if updating
      uid: user.uid,
      amount: amount,
      catagory: _type == TransactionType.income ? 'income' : _selectedCategory,
      paymentmethod: _method,
      createdAt: _selectedDate,
      description: _noteController.text.isNotEmpty
          ? _noteController.text
          : categories.firstWhere((c) => c.id == (_type == TransactionType.income ? 'income' : _selectedCategory), orElse: () => fallbackCat).name,
      isIncome: _type == TransactionType.income,
    );

    try {
      if (widget.existingTransaction != null) {
        await context.read<TransactionProvider>().updateTransaction(transaction);
      } else {
        await context.read<TransactionProvider>().addTransaction(transaction);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingTransaction != null ? l10n.transactionUpdated : l10n.transactionSaved)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSaving(e.toString()))),
        );
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    if (widget.existingTransaction == null) return;
    try {
      await context.read<TransactionProvider>().deleteTransaction(widget.existingTransaction!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.transactionDeleted)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorDeleting(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = context.watch<CategoryProvider>().categories;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 32),
            _buildTypeToggle(l10n),
            const SizedBox(height: 32),
            _buildAmountInput(),
            const SizedBox(height: 16),
            _buildCurrencyBadge(l10n),
            const SizedBox(height: 32),
            _buildDateSelector(l10n),
            const SizedBox(height: 32),
            _buildMethodToggle(l10n),
            const SizedBox(height: 32),
            if (_type == TransactionType.expense) ...[
              _buildCategoryPicker(categories, l10n),
              const SizedBox(height: 32),
            ],
            _buildNoteField(l10n),
            const SizedBox(height: 32),
            _buildSaveButton(l10n),
            if (widget.existingTransaction != null) ...[
              const SizedBox(height: 16),
              _buildDeleteButton(l10n),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeToggle(AppLocalizations l10n) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            _typeButton(l10n.expense, TransactionType.expense, Colors.red),
            _typeButton(l10n.income, TransactionType.income, AppTheme.brandGreen),
          ],
        ),
      );

  Widget _typeButton(String label, TransactionType type, Color activeColor) {
    final selected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = type;
          if (_type == TransactionType.income && _method == PaymentMethod.card) {
            _method = PaymentMethod.cash;
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          Text(
            widget.existingTransaction != null
                ? l10n.editTransaction
                : (_type == TransactionType.income ? l10n.addIncome : l10n.addExpense),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Row(
            children: [
              IconButton(
                tooltip: l10n.arabicScan,
                icon: _isScanning
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                    : const Icon(Icons.translate, color: Colors.orange),
                onPressed: _isScanning ? null : _performArabicOCR,
              ),
              IconButton(
                tooltip: l10n.latinScan,
                icon: _isScanning
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                    : const Icon(Icons.document_scanner, color: Colors.green),
                onPressed: _isScanning ? null : _performHardwareOCR,
              ),
              IconButton(
                tooltip: l10n.aiExtract,
                icon: _isScanning
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue))
                    : const Icon(Icons.camera_alt, color: Colors.blue),
                onPressed: _isScanning ? null : _scanReceipt,
              ),
            ],
          ),
        ],
      );

  Widget _buildAmountInput() => TextField(
        controller: _amountController,
        style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
        decoration: const InputDecoration(border: InputBorder.none),
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        autofocus: widget.existingTransaction == null,
      );

  Widget _buildCurrencyBadge(AppLocalizations l10n) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Text('${l10n.lyd}  د.ل', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _buildDateSelector(AppLocalizations l10n) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final isToday = _isSameDay(_selectedDate, now);
    final isYesterday = _isSameDay(_selectedDate, yesterday);
    final isCustom = !isToday && !isYesterday;
    final locale = l10n.localeName;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = DateTime(now.year, now.month, now.day, _selectedDate.hour, _selectedDate.minute)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(l10n.today, style: TextStyle(color: isToday ? Colors.white : Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedDate = DateTime(yesterday.year, yesterday.month, yesterday.day, _selectedDate.hour, _selectedDate.minute)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isYesterday ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(l10n.yesterday, style: TextStyle(color: isYesterday ? Colors.white : Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _pickDate,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCustom ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month, size: 14, color: isCustom ? Colors.white : Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      isCustom ? DateFormat.MMMd(locale).format(_selectedDate) : l10n.date,
                      style: TextStyle(color: isCustom ? Colors.white : Colors.grey, fontWeight: FontWeight.w500, fontSize: 13)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodToggle(AppLocalizations l10n) {
    final methods = _type == TransactionType.income
        ? [PaymentMethod.cash, PaymentMethod.transfer]
        : [PaymentMethod.cash, PaymentMethod.card, PaymentMethod.transfer];

    return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: methods.map((m) {
            final selected = _method == m;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _method = m),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        m == PaymentMethod.cash ? Icons.money : (m == PaymentMethod.card ? Icons.credit_card : Icons.account_balance),
                        size: 16,
                        color: selected ? Colors.white : Colors.grey
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getMethodName(m, l10n),
                        style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.w500, fontSize: 11)
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
  }

  String _getMethodName(PaymentMethod method, AppLocalizations l10n) {
    switch (method) {
      case PaymentMethod.cash: return l10n.cash;
      case PaymentMethod.card: return l10n.card;
      case PaymentMethod.transfer: return l10n.transfer;
    }
  }

  Widget _buildCategoryPicker(List<Category> categories, AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.category, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: categories.map((cat) {
                  if (cat.id == 'income') return const SizedBox.shrink(); // Don't show income category for expenses
                  final selected = _selectedCategory == cat.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat.id),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: selected ? Colors.blue : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(cat.icon, color: selected ? Colors.white : Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(cat.name, style: TextStyle(fontSize: 12, color: selected ? Colors.blue : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      );

  Widget _buildNoteField(AppLocalizations l10n) => TextField(
        controller: _noteController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: l10n.descriptionHint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
        ),
        minLines: 2,
        maxLines: null,
      );

  Widget _buildSaveButton(AppLocalizations l10n) => SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check),
              const SizedBox(width: 8),
              Text(widget.existingTransaction != null ? l10n.updateTransaction : l10n.saveTransaction, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
            ],
          ),
        ),
      );

  Widget _buildDeleteButton(AppLocalizations l10n) => SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                backgroundColor: AppTheme.bgDark,
                title: Text(l10n.deleteTransaction, style: const TextStyle(color: Colors.white)),
                content: Text(l10n.deleteConfirmation, style: const TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey))),
                  TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete, style: const TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true) {
              _delete();
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              Text(l10n.deleteTransaction, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red))
            ],
          ),
        ),
      );
}
