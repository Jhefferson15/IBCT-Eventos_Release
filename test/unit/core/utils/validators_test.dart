import 'package:flutter_test/flutter_test.dart';
import 'package:ibct_eventos/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('validateRequired', () {
      test('should return error for null', () {
        expect(Validators.validateRequired(null), 'Campo é obrigatório');
      });
      test('should return error for empty string', () {
        expect(Validators.validateRequired(''), 'Campo é obrigatório');
      });
      test('should return error for whitespace', () {
        expect(Validators.validateRequired('   '), 'Campo é obrigatório');
      });
      test('should return custom field name in error', () {
        expect(Validators.validateRequired('', fieldName: 'Nome'), 'Nome é obrigatório');
      });
      test('should return null for valid value', () {
        expect(Validators.validateRequired('valid'), null);
      });
    });

    group('validateName', () {
      test('should return error for null/empty', () {
        expect(Validators.validateName(null), 'Nome é obrigatório');
        expect(Validators.validateName(''), 'Nome é obrigatório');
      });
      test('should return error for short name', () {
        expect(Validators.validateName('Ab'), 'Nome muito curto');
      });
      test('should return null for valid name', () {
        expect(Validators.validateName('Bob'), null);
      });
    });

    group('validateEmail', () {
      test('should return null for null/empty (optional field behavior)', () {
        expect(Validators.validateEmail(null), null);
        expect(Validators.validateEmail(''), null);
      });
      test('should return error for invalid email format', () {
        expect(Validators.validateEmail('invalid'), 'Email inválido');
        expect(Validators.validateEmail('test@'), 'Email inválido');
        expect(Validators.validateEmail('test@domain'), 'Email inválido');
        expect(Validators.validateEmail('@domain.com'), 'Email inválido');
      });
      test('should return null for valid email', () {
        expect(Validators.validateEmail('test@test.com'), null);
        expect(Validators.validateEmail('user.name@domain.co.uk'), null);
      });
    });

    group('validatePhone', () {
      test('should return error for null/empty', () {
        expect(Validators.validatePhone(null), 'Obrigatório');
        expect(Validators.validatePhone(''), 'Obrigatório');
      });
      test('should return error for incomplete number', () {
        expect(Validators.validatePhone('1199999'), 'Telefone incompleto');
      });
      test('should return error for number too long', () {
        expect(Validators.validatePhone('119999999999'), 'Telefone inválido');
      });
      test('should return error for invalid DDD', () {
        // 00 is not in validDDDs
        expect(Validators.validatePhone('0099999999'), 'DDD (00) inválido');
      });
      test('should return null for valid phone with valid DDD', () {
        // 11 is valid (SP)
        expect(Validators.validatePhone('11999999999'), null);
      });
      test('should strip formatting before validating', () {
        expect(Validators.validatePhone('(11) 99999-9999'), null);
      });
    });
  });
}
