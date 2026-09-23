import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:firstrproject/core/theme/app_theme.dart';
import 'package:firstrproject/l10n/app_localizations.dart';
import 'package:firstrproject/features/subscriptions/presentation/providers/subscription_provider.dart';

class AddSubscriptionSheet extends StatefulWidget {
  const AddSubscriptionSheet({super.key});

  @override
  State<AddSubscriptionSheet> createState() => _AddSubscriptionSheetState();
}

class _AddSubscriptionSheetState extends State<AddSubscriptionSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController(text: '9.99');
  bool _isRecurring = true;
  String _period = 'Monthly';
  String _currency = 'USD';
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));

  final List<String> _periods = ['Weekly', 'Monthly'];
  final List<String> _currencies = ['LYD', 'USD', 'EUR', 'GBP'];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
    if (picked != null && picked != _nextBillingDate) {
      setState(() => _nextBillingDate = picked);
    }
  }

  void _saveSubscription() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (name.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterServiceName)),
      );
      return;
    }

    try {
      await context.read<SubscriptionProvider>().addSubscription(
            name: name,
            amount: amount,
            isRecurring: _isRecurring,
            period: _period,
            currency: _currency,
            nextBillingDate: _nextBillingDate,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
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
            _buildNameField(l10n),
            const SizedBox(height: 24),
            _buildAmountInput(l10n),
            const SizedBox(height: 24),
            _buildRecurringSwitch(l10n),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildPeriodDropdown(l10n)),
                const SizedBox(width: 16),
                Expanded(child: _buildCurrencyDropdown(l10n)),
              ],
            ),
            const SizedBox(height: 24),
            _buildDatePicker(l10n),
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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            l10n.newSubscription,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(width: 48),
        ],
      );

  Widget _buildNameField(AppLocalizations l10n) => TextField(
        controller: _nameController,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          labelText: l10n.serviceName,
          labelStyle: const TextStyle(color: Colors.grey),
          hintText: l10n.serviceNameHint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white10),
          ),
        ),
      );

  Widget _buildAmountInput(AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.billingAmount, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            decoration: const InputDecoration(border: InputBorder.none, hintText: '0.00'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      );

  Widget _buildRecurringSwitch(AppLocalizations l10n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.recurring, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                Text(l10n.autoRenewalEnabled, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Switch(
              value: _isRecurring,
              onChanged: (val) => setState(() => _isRecurring = val),
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      );

  Widget _buildPeriodDropdown(AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.frequency, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _period,
                isExpanded: true,
                dropdownColor: AppTheme.bgDark,
                items: _periods.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Text(p == 'Weekly' ? l10n.weekly : l10n.monthly, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _period = val!),
              ),
            ),
          ),
        ],
      );

  Widget _buildCurrencyDropdown(AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.currency, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currency,
                isExpanded: true,
                dropdownColor: AppTheme.bgDark,
                items: _currencies.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _currency = val!),
              ),
            ),
          ),
        ],
      );

  Widget _buildDatePicker(AppLocalizations l10n) => GestureDetector(
        onTap: _selectDate,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.nextBillingDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_nextBillingDate),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      );

  Widget _buildSaveButton(AppLocalizations l10n) => SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _saveSubscription,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: Text(
            l10n.addSubscription,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
}
