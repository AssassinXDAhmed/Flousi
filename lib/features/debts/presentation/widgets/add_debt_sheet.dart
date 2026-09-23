import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/debts/presentation/providers/debt_provider.dart';

class AddDebtSheet extends StatefulWidget {
  const AddDebtSheet({super.key});

  @override
  State<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends State<AddDebtSheet> {
  final _personController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isIOwe = true; // true = I Owe, false = Owed to me
  DateTime? _reminderDate;

  Future<void> _selectReminderDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              onPrimary: Colors.white,
              surface: AppTheme.cardDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderDate = picked);
    }
  }

  void _saveDebt() async {
    final person = _personController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final l10n = AppLocalizations.of(context)!;

    if (person.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterValidPersonAndAmount)),
      );
      return;
    }

    try {
      await context.read<DebtProvider>().addDebt(
            amount: amount,
            isIOwe: _isIOwe,
            personOrPlace: person,
            notes: _notesController.text.trim(),
            reminderDate: _reminderDate,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorOccurred(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: 32),
            _buildTypeToggle(l10n),
            const SizedBox(height: 24),
            _buildPersonField(l10n),
            const SizedBox(height: 24),
            _buildAmountInput(l10n),
            const SizedBox(height: 24),
            _buildNotesField(l10n),
            const SizedBox(height: 24),
            _buildReminderPicker(l10n),
            const SizedBox(height: 48),
            _buildSaveButton(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          Text(l10n.addNewDebt, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(width: 48),
        ],
      );

  Widget _buildTypeToggle(AppLocalizations l10n) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            _toggleButton(true, l10n.iOwe),
            _toggleButton(false, l10n.owedToMe),
          ],
        ),
      );

  Widget _toggleButton(bool type, String label) {
    final selected = _isIOwe == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isIOwe = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? (type ? Colors.red.withValues(alpha: 0.8) : Colors.green.withValues(alpha: 0.8)) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(color: selected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonField(AppLocalizations l10n) => TextField(
        controller: _personController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: _isIOwe ? l10n.whoDoYouOwe : l10n.whoOwesYou,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );

  Widget _buildAmountInput(AppLocalizations l10n) => TextField(
        controller: _amountController,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.amountLydLabel,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          border: InputBorder.none,
          hintText: '0.00',
        ),
      );

  Widget _buildNotesField(AppLocalizations l10n) => TextField(
        controller: _notesController,
        style: const TextStyle(color: Colors.white),
        maxLines: 3,
        decoration: InputDecoration(
          labelText: l10n.notes,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      );

  Widget _buildReminderPicker(AppLocalizations l10n) => GestureDetector(
        onTap: _selectReminderDate,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.blue),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.reminderDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    _reminderDate == null ? l10n.notSet : DateFormat('MMM dd, yyyy').format(_reminderDate!),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              if (_reminderDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  onPressed: () => setState(() => _reminderDate = null),
                ),
            ],
          ),
        ),
      );

  Widget _buildSaveButton(AppLocalizations l10n) => SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _saveDebt,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(l10n.saveDebt, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
}
