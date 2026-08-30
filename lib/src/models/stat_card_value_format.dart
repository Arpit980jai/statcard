/// How `StatCard.number` renders its value before it starts shrinking the
/// font.
///
/// ```dart
/// StatCard.number(
///   1250000,
///   label: 'Deliveries',
///   format: StatCardValueFormat.compact, // 1.25M, never 1,250,000
/// );
/// ```
enum StatCardValueFormat {
  /// Try the full grouped number first, then the compact renderings.
  ///
  /// The ladder is `1,250,000` → `1.25M` → `1.2M`, and only then does the font
  /// start to shrink. This is the default, and it is what keeps a big number
  /// legible in a narrow card: a shorter rendering of the same quantity beats
  /// the same digits at 70% of the size.
  auto,

  /// Always render the full grouped number, for example `1,250,000`.
  ///
  /// Nothing is ever abbreviated, so the card falls straight through to the
  /// [StatCardOverflow] strategy when the number does not fit.
  grouped,

  /// Always render a compact number, for example `1.25M` and then `1.2M`.
  ///
  /// Useful when a dashboard should read consistently whether or not a given
  /// card happens to have room for the full number.
  compact,
}

/// A dependency-free number formatter for stat card values.
///
/// The output is **en-style**: `,` groups thousands, `.` is the decimal
/// separator, and the compact suffixes are `K`, `M`, `B` and `T`. It is
/// deliberately not localised, because localising it properly would mean
/// depending on `intl`, and this package has no runtime dependencies.
///
/// Pass `valueFormatter:` to `StatCard.number` to use something else — that
/// hook is where `intl`'s `NumberFormat` belongs:
///
/// ```dart
/// StatCard.number(
///   1250000,
///   label: 'Deliveries',
///   valueFormatter: (num value, double availableWidth) => availableWidth < 120
///       ? NumberFormat.compact(locale: 'de').format(value)
///       : NumberFormat.decimalPattern('de').format(value),
/// );
/// ```
abstract final class StatCardNumberFormat {
  /// Thousands separators, largest unit first.
  static const List<(double, String)> _units = <(double, String)>[
    (1e12, 'T'),
    (1e9, 'B'),
    (1e6, 'M'),
    (1e3, 'K'),
  ];

  /// Renders [value] in full, with `,` between groups of three digits.
  ///
  /// When [fractionDigits] is null an integer is rendered without a decimal
  /// point, and a double keeps the shortest representation that round-trips.
  /// Values too large for a positional rendering (`1e21` and beyond) are
  /// returned in Dart's exponent form rather than being grouped.
  ///
  /// ```dart
  /// StatCardNumberFormat.grouped(1250000); // '1,250,000'
  /// StatCardNumberFormat.grouped(-4823.5); // '-4,823.5'
  /// StatCardNumberFormat.grouped(4.8, fractionDigits: 2); // '4.80'
  /// ```
  static String grouped(num value, {int? fractionDigits}) {
    if (!value.isFinite) {
      return value.toString();
    }
    final String sign = value.isNegative ? '-' : '';
    final num magnitude = value.abs();

    final String raw;
    if (fractionDigits != null) {
      raw = magnitude.toStringAsFixed(fractionDigits);
    } else if (magnitude is int || magnitude == magnitude.roundToDouble()) {
      // 1248.0 should read as '1,248', not as '1,248.0'.
      raw = magnitude.abs() < 1e21
          ? magnitude.toStringAsFixed(0)
          : magnitude.toString();
    } else {
      raw = magnitude.toString();
    }

    if (raw.contains('e') || raw.contains('E')) {
      return '$sign$raw';
    }

    final int dot = raw.indexOf('.');
    final String whole = dot == -1 ? raw : raw.substring(0, dot);
    final String fraction = dot == -1 ? '' : raw.substring(dot);

    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      if (i > 0 && (whole.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(whole[i]);
    }
    return '$sign$buffer$fraction';
  }

  /// Renders [value] abbreviated with a `K`, `M`, `B` or `T` suffix.
  ///
  /// [fractionDigits] is the number of decimal places kept before trailing
  /// zeros are trimmed, so `1250000` is `1.25M` at two digits and `1.2M` at
  /// one. Anything below a thousand is returned by [grouped] unchanged.
  ///
  /// Digits are **truncated, not rounded**, which is what keeps a degrading
  /// card honest: `1.25M` shortens to `1.2M` rather than jumping to `1.3M`, so
  /// a number that loses precision as its card narrows never appears to have
  /// changed. It also means the value shown is never larger than the real one.
  ///
  /// ```dart
  /// StatCardNumberFormat.compact(1250000); // '1.25M'
  /// StatCardNumberFormat.compact(1250000, fractionDigits: 1); // '1.2M'
  /// StatCardNumberFormat.compact(999999); // '999.99K'
  /// ```
  static String compact(num value, {int fractionDigits = 2}) {
    assert(
      fractionDigits >= 0 && fractionDigits <= 6,
      'fractionDigits must be between 0 and 6',
    );
    if (!value.isFinite) {
      return value.toString();
    }
    final double magnitude = value.abs().toDouble();
    if (magnitude < 1000) {
      return grouped(value);
    }
    final String sign = value.isNegative ? '-' : '';

    for (var i = 0; i < _units.length; i++) {
      final (double factor, String suffix) = _units[i];
      if (magnitude < factor) {
        continue;
      }
      final String text = _truncate(magnitude / factor, fractionDigits);
      // Truncation cannot reach 1000 on its own, but a value a hair under the
      // next unit can round up inside the wider rendering it truncates from.
      if (i > 0 && (double.tryParse(text) ?? 0) >= 1000) {
        final (double bigger, String biggerSuffix) = _units[i - 1];
        final String promoted = _truncate(magnitude / bigger, fractionDigits);
        return '$sign${_trim(promoted)}$biggerSuffix';
      }
      return '$sign${_trim(text)}$suffix';
    }
    return grouped(value);
  }

  /// Cuts [value] to [fractionDigits] decimals without rounding them up.
  ///
  /// The wider rendering is produced first and then cut, rather than scaling
  /// by a power of ten and flooring, because `1.15 * 100` is `114.999…` in
  /// binary and would floor to the wrong digit.
  static String _truncate(double value, int fractionDigits) {
    final String wide = value.toStringAsFixed(fractionDigits + 4);
    final int dot = wide.indexOf('.');
    if (dot == -1) {
      return wide;
    }
    return fractionDigits == 0
        ? wide.substring(0, dot)
        : wide.substring(0, dot + 1 + fractionDigits);
  }

  /// The degradation ladder `StatCard.number` measures, most informative first.
  ///
  /// The length depends only on [format], never on [value], which is what lets
  /// an animating number swap its own strings in position by position without
  /// re-measuring anything.
  ///
  /// ```dart
  /// StatCardNumberFormat.ladder(1250000, StatCardValueFormat.auto);
  /// // <String>['1,250,000', '1.25M', '1.2M']
  /// ```
  static List<String> ladder(num value, StatCardValueFormat format) {
    return switch (format) {
      StatCardValueFormat.auto => <String>[
        grouped(value),
        compact(value),
        compact(value, fractionDigits: 1),
      ],
      StatCardValueFormat.grouped => <String>[grouped(value)],
      StatCardValueFormat.compact => <String>[
        compact(value),
        compact(value, fractionDigits: 1),
      ],
    };
  }

  /// Drops the trailing zeros `toStringAsFixed` leaves behind.
  static String _trim(String text) {
    if (!text.contains('.')) {
      return text;
    }
    var end = text.length;
    while (end > 0 && text[end - 1] == '0') {
      end--;
    }
    if (end > 0 && text[end - 1] == '.') {
      end--;
    }
    return text.substring(0, end);
  }
}
