import 'dart:math';

class DataGenerator {
  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final _rnd = Random();

  static String generateId() {
    return _rnd.nextInt(1000000).toString().padLeft(6, '0');
  }

  static String generateToken([String? eventId]) {
    // Generate a short 8-char token
    return String.fromCharCodes(Iterable.generate(
        8, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  static String generatePassword() {
    // Generate a secure-ish password (8 chars)
    return String.fromCharCodes(Iterable.generate(
        8, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  static String generateQrData(String eventId, String participantId) {
    return 'IBCT-$eventId-$participantId';
  }
}
