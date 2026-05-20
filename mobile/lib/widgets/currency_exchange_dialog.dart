import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/currency_converter.dart';
import 'package:intl/intl.dart';

class CurrencyExchangeDialog extends StatefulWidget {
  const CurrencyExchangeDialog({super.key});

  @override
  State<CurrencyExchangeDialog> createState() => _CurrencyExchangeDialogState();
}

class _CurrencyExchangeDialogState extends State<CurrencyExchangeDialog> {
  final _amountController = TextEditingController(text: '1');
  String _selectedFrom = 'USD';
  String _selectedTo = 'TZS';
  double _result = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateConversion();
    _amountController.addListener(_calculateConversion);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _calculateConversion() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final rateFrom = CurrencyConverter.ratesToUsd[_selectedFrom] ?? 1.0;
    final rateTo = CurrencyConverter.ratesToUsd[_selectedTo] ?? 1.0;

    setState(() {
      _result = amount * (rateTo / rateFrom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatFrom = NumberFormat.currency(symbol: '', decimalDigits: _selectedFrom == 'USD' ? 2 : 0);
    final formatTo = NumberFormat.currency(symbol: '', decimalDigits: _selectedTo == 'USD' ? 2 : 0);
    final amountText = double.tryParse(_amountController.text) != null 
      ? formatFrom.format(double.parse(_amountController.text)) 
      : '0';

    return AlertDialog(
      title: const Text('Currency Exchange', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter amount to convert using live rates:', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Convert Amount',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFrom,
                  decoration: const InputDecoration(
                    labelText: 'From',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: Constants.currencies.map((curr) => DropdownMenuItem(
                    value: curr,
                    child: Text(curr),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedFrom = val!;
                      _calculateConversion();
                    });
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.arrow_forward, color: Colors.grey),
              ),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTo,
                  decoration: const InputDecoration(
                    labelText: 'To',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: Constants.currencies.map((curr) => DropdownMenuItem(
                    value: curr,
                    child: Text(curr),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedTo = val!;
                      _calculateConversion();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Text(
                  '$amountText $_selectedFrom =',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatTo.format(_result)} $_selectedTo',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }
}
