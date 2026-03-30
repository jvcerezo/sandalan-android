import 'package:flutter_test/flutter_test.dart';
import 'package:sandalan/core/utils/input_validator.dart';

void main() {
  group('name', () {
    test('null returns empty string', () {
      expect(InputValidator.name(null), '');
    });

    test('blank returns empty string', () {
      expect(InputValidator.name('   '), '');
    });

    test('trims whitespace', () {
      expect(InputValidator.name('  hello  '), 'hello');
    });

    test('truncates at 100 chars', () {
      final long = 'a' * 200;
      expect(InputValidator.name(long).length, lessThanOrEqualTo(100));
    });
  });

  group('requireName', () {
    test('throws on blank', () {
      expect(() => InputValidator.requireName(''), throwsArgumentError);
    });

    test('throws on null', () {
      expect(() => InputValidator.requireName(null), throwsArgumentError);
    });

    test('returns sanitized name on valid input', () {
      expect(InputValidator.requireName('Test'), 'Test');
    });
  });

  group('amount', () {
    test('NaN returns 0', () {
      expect(InputValidator.amount(double.nan), 0);
    });

    test('infinity returns 0', () {
      expect(InputValidator.amount(double.infinity), 0);
    });

    test('clamps to maxAmount', () {
      expect(InputValidator.amount(9999999999.0), InputValidator.maxAmount);
    });

    test('clamps negative to -maxAmount', () {
      expect(InputValidator.amount(-9999999999.0), -InputValidator.maxAmount);
    });

    test('normal value passes through', () {
      expect(InputValidator.amount(1234.56), 1234.56);
    });

    test('string with commas is parsed', () {
      expect(InputValidator.amount('1,234.56'), 1234.56);
    });

    test('null returns 0', () {
      expect(InputValidator.amount(null), 0);
    });

    test('int is converted', () {
      expect(InputValidator.amount(100), 100.0);
    });
  });

  group('positiveAmount', () {
    test('negative returns 0', () {
      expect(InputValidator.positiveAmount(-50), 0);
    });

    test('positive passes through', () {
      expect(InputValidator.positiveAmount(100), 100.0);
    });
  });

  group('uuid', () {
    test('valid UUID passes', () {
      expect(InputValidator.uuid('550e8400-e29b-41d4-a716-446655440000'), isNotNull);
    });

    test('invalid string returns null', () {
      expect(InputValidator.uuid('not-a-uuid'), isNull);
    });

    test('null returns null', () {
      expect(InputValidator.uuid(null), isNull);
    });
  });

  group('currency', () {
    test('null defaults to PHP', () {
      expect(InputValidator.currency(null), 'PHP');
    });

    test('empty defaults to PHP', () {
      expect(InputValidator.currency(''), 'PHP');
    });

    test('valid code uppercased', () {
      expect(InputValidator.currency('usd'), 'USD');
    });

    test('long string defaults to PHP', () {
      expect(InputValidator.currency('a' * 20), 'PHP');
    });
  });

  group('enumValue', () {
    test('valid value passes', () {
      expect(InputValidator.enumValue('a', ['a', 'b', 'c']), 'a');
    });

    test('invalid returns null', () {
      expect(InputValidator.enumValue('x', ['a', 'b']), isNull);
    });

    test('null returns null', () {
      expect(InputValidator.enumValue(null, ['a']), isNull);
    });
  });

  group('interestRate', () {
    test('clamps to 0-100', () {
      expect(InputValidator.interestRate(150), 100);
      expect(InputValidator.interestRate(-5), 0);
    });
  });

  group('dayOfMonth', () {
    test('valid day passes', () {
      expect(InputValidator.dayOfMonth(15), 15);
    });

    test('0 returns null', () {
      expect(InputValidator.dayOfMonth(0), isNull);
    });

    test('32 returns null', () {
      expect(InputValidator.dayOfMonth(32), isNull);
    });
  });

  group('tags', () {
    test('limits to 20 tags', () {
      final many = List.generate(30, (i) => 'tag$i').join(',');
      final result = InputValidator.tags(many);
      expect(result.split(',').length, lessThanOrEqualTo(20));
    });

    test('empty returns empty', () {
      expect(InputValidator.tags(''), '');
    });
  });

  group('description', () {
    test('null returns empty', () {
      expect(InputValidator.description(null), '');
    });

    test('truncates at 500', () {
      final long = 'a' * 600;
      expect(InputValidator.description(long).length, lessThanOrEqualTo(500));
    });
  });
}
