import 'package:flutter/material.dart';

class ColorParser {
  static Color fromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      // Handle #RRGGBB, RRGGBB, #AARRGGBB, or AARRGGBB formats
      String cleanHex = hexString.replaceFirst('#', '').trim();
      if (cleanHex.length == 6) {
        buffer.write('ff');
        buffer.write(cleanHex);
      } else if (cleanHex.length == 8) {
        buffer.write(cleanHex);
      } else if (cleanHex.length == 3) {
        buffer.write('ff');
        for (var char in cleanHex.split('')) {
          buffer.write(char * 2);
        }
      } else {
        return Colors.grey;
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
