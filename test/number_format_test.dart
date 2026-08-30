import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StatCardNumberFormat.grouped', () {
    test('groups thousands', () {
      expect(StatCardNumberFormat.grouped(0), '0');
      expect(StatCardNumberFormat.grouped(42), '42');
      expect(StatCardNumberFormat.grouped(999), '999');
      expect(StatCardNumberFormat.grouped(1000), '1,000');
      expect(StatCardNumberFormat.grouped(1248), '1,248');
      expect(StatCardNumberFormat.grouped(1250000), '1,250,000');
      expect(StatCardNumberFormat.grouped(1248930551), '1,248,930,551');
    });

    test('keeps the sign outside the grouping', () {
      expect(StatCardNumberFormat.grouped(-1248), '-1,248');
      expect(StatCardNumberFormat.grouped(-999), '-999');
      expect(StatCardNumberFormat.grouped(-1250000), '-1,250,000');
    });

    test('renders a whole double without a decimal point', () {
      expect(StatCardNumberFormat.grouped(1248.0), '1,248');
      expect(StatCardNumberFormat.grouped(-4.0), '-4');
    });

    test('keeps a real fraction', () {
      expect(StatCardNumberFormat.grouped(4.8), '4.8');
      expect(StatCardNumberFormat.grouped(-4823.5), '-4,823.5');
      expect(StatCardNumberFormat.grouped(99.97), '99.97');
    });

    test('honours an explicit fractionDigits', () {
      expect(StatCardNumberFormat.grouped(4.8, fractionDigits: 2), '4.80');
      expect(StatCardNumberFormat.grouped(1248, fractionDigits: 1), '1,248.0');
      expect(StatCardNumberFormat.grouped(4.849, fractionDigits: 2), '4.85');
    });

    test('passes non-finite values straight through', () {
      expect(StatCardNumberFormat.grouped(double.nan), 'NaN');
      expect(StatCardNumberFormat.grouped(double.infinity), 'Infinity');
    });

    test('does not mangle a number too large to write positionally', () {
      final String huge = StatCardNumberFormat.grouped(1e21);
      expect(huge, contains('e'));
      expect(huge, isNot(contains(',')));
    });
  });

  group('StatCardNumberFormat.compact', () {
    test('abbreviates with the right unit', () {
      expect(StatCardNumberFormat.compact(1000), '1K');
      expect(StatCardNumberFormat.compact(1250), '1.25K');
      expect(StatCardNumberFormat.compact(1250000), '1.25M');
      expect(StatCardNumberFormat.compact(1250000000), '1.25B');
      expect(StatCardNumberFormat.compact(1250000000000), '1.25T');
    });

    test('honours fractionDigits and trims trailing zeros', () {
      expect(StatCardNumberFormat.compact(1250000, fractionDigits: 1), '1.2M');
      expect(StatCardNumberFormat.compact(1250000, fractionDigits: 0), '1M');
      expect(StatCardNumberFormat.compact(1200000), '1.2M');
      expect(StatCardNumberFormat.compact(2000000), '2M');
    });

    test('leaves anything below a thousand alone', () {
      expect(StatCardNumberFormat.compact(999), '999');
      expect(StatCardNumberFormat.compact(42), '42');
      expect(StatCardNumberFormat.compact(4.8), '4.8');
    });

    test('truncates instead of rounding up into the next unit', () {
      expect(StatCardNumberFormat.compact(999999), '999.99K');
      expect(StatCardNumberFormat.compact(999999999), '999.99M');
      expect(StatCardNumberFormat.compact(1259999), '1.25M');
    });

    test('never leaves a four digit mantissa', () {
      for (final num value in <num>[
        999999.9999999,
        999999999.9999,
        1e12 - 0.0001,
      ]) {
        for (var digits = 0; digits <= 3; digits++) {
          final String text = StatCardNumberFormat.compact(
            value,
            fractionDigits: digits,
          );
          final String mantissa = text.substring(0, text.length - 1);
          expect(
            double.parse(mantissa).abs(),
            lessThan(1000),
            reason: 'compact(, ) produced ',
          );
        }
      }
    });

    test('keeps the sign', () {
      expect(StatCardNumberFormat.compact(-1250000), '-1.25M');
      expect(
        StatCardNumberFormat.compact(-1250000, fractionDigits: 1),
        '-1.2M',
      );
    });

    test('passes non-finite values straight through', () {
      expect(StatCardNumberFormat.compact(double.nan), 'NaN');
      expect(
        StatCardNumberFormat.compact(double.negativeInfinity),
        '-Infinity',
      );
    });
  });

  group('StatCardNumberFormat.ladder', () {
    test('auto goes full, then two digits, then one', () {
      expect(
        StatCardNumberFormat.ladder(1250000, StatCardValueFormat.auto),
        <String>['1,250,000', '1.25M', '1.2M'],
      );
    });

    test('grouped never abbreviates', () {
      expect(
        StatCardNumberFormat.ladder(1250000, StatCardValueFormat.grouped),
        <String>['1,250,000'],
      );
    });

    test('compact never spells the number out', () {
      expect(
        StatCardNumberFormat.ladder(1250000, StatCardValueFormat.compact),
        <String>['1.25M', '1.2M'],
      );
    });

    test('the length depends on the format, never on the value', () {
      // Position-for-position substitution during an animation depends on this.
      for (final StatCardValueFormat format in StatCardValueFormat.values) {
        final int expected = StatCardNumberFormat.ladder(0, format).length;
        for (final num value in <num>[0, 42, -7, 999, 1250000, 1e12, 4.85]) {
          expect(
            StatCardNumberFormat.ladder(value, format).length,
            expected,
            reason: 'ladder length changed for $value in $format',
          );
        }
      }
    });

    test('a small number degrades to itself at every rung', () {
      expect(
        StatCardNumberFormat.ladder(42, StatCardValueFormat.auto),
        <String>['42', '42', '42'],
      );
    });
  });
}
