import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class EncodingHandler {
  /// We don't implement CsvHandler `File` -> String directly because we need strict types, 
  /// but effectively this is the first step.
  
  String process(File file) {
    final bytes = file.readAsBytesSync();
    return decodeBytes(bytes);
  }

  String decodeBytes(Uint8List bytes) {
    try {
      // 1. Try UTF-8 first (Standard)
      return const Utf8Decoder().convert(bytes);
    } catch (_) {
      try {
        // 2. Fallback to Latin-1 (Common in Legacy Windows Excel)
        return const Latin1Decoder().convert(bytes);
      } catch (e) {
        // 3. Last resort: ASCII (or rethrow)
        try {
           return const AsciiDecoder().convert(bytes);
        } catch (_) {
           // If all fails, forcefully decode ignoring errors
           return String.fromCharCodes(bytes);
        }
      }
    }
  }
}
