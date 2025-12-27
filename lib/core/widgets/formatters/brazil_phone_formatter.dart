import 'package:flutter/services.dart';

class BrazilPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final cleanText = text.replaceAll(RegExp(r'\D'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formatted = '';
    if (cleanText.length <= 2) {
      formatted = '($cleanText';
    } else if (cleanText.length <= 6) {
      formatted = '(${cleanText.substring(0, 2)}) ${cleanText.substring(2)}';
    } else if (cleanText.length <= 10) {
      formatted = '(${cleanText.substring(0, 2)}) ${cleanText.substring(2, 6)}-${cleanText.substring(6)}';
    } else {
      formatted = '(${cleanText.substring(0, 2)}) ${cleanText.substring(2, 7)}-${cleanText.substring(7, 11)}';
    }
    
    // Limit to 11 digits (DDD + 9 digits)
    if (cleanText.length > 11) {
       // Keep the old valid one if exceeded or truncate
       return oldValue; 
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
