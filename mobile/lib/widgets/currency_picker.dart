import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CurrencyPicker extends StatelessWidget {
  final String selectedCurrency;
  final ValueChanged<String?> onChanged;

  const CurrencyPicker({
    super.key,
    required this.selectedCurrency,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedCurrency,
      decoration: const InputDecoration(
        labelText: 'Currency',
      ),
      items: Constants.currencies.map((String currency) {
        return DropdownMenuItem<String>(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
