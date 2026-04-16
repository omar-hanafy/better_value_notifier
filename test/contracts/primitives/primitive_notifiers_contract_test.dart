import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/notification_probe.dart';

void main() {
  group('primitive notifier core semantics', () {
    test('multiple listeners receive the same notifications', () {
      final notifier = BoolNotifier(false);
      var firstCount = 0;
      var secondCount = 0;

      void first() => firstCount++;
      void second() => secondCount++;

      notifier.addListener(first);
      notifier.addListener(second);

      notifier.setTrue();

      expect(firstCount, 1);
      expect(secondCount, 1);

      notifier.removeListener(first);
      notifier.setFalse();

      expect(firstCount, 1);
      expect(secondCount, 2);
    });

    test(
      'disposed primitive and collection notifiers do not throw on refresh paths',
      () {
        final boolNotifier = BoolNotifier(true);
        final listNotifier = ListNotifier<int>([1, 2, 3]);

        boolNotifier.dispose();
        listNotifier.dispose();

        expect(() => boolNotifier.refresh(), returnsNormally);
        expect(() => boolNotifier.update(true), returnsNormally);
        expect(() => listNotifier.refresh(), returnsNormally);
        expect(() => listNotifier.update([1, 2, 3]), returnsNormally);
        expect(
          () => listNotifier.mutate((list) => list.add(4)),
          returnsNormally,
        );
      },
    );
  });

  group('primitive mutators', () {
    test('BoolNotifier helpers mutate correctly', () async {
      final notifier = BoolNotifier(false);

      notifier.toggle();
      expect(notifier.value, isTrue);

      notifier.setFalse();
      expect(notifier.value, isFalse);

      await notifier.delayedToggle(const Duration(milliseconds: 1));
      expect(notifier.value, isTrue);
    });

    test('NumNotifier mutation helpers mutate correctly', () {
      final notifier = NumNotifier(10);

      notifier.increment(5);
      notifier.decrement(3);
      notifier.multiply(2);
      notifier.divide(4);
      notifier.modulo(4);
      notifier.max(3);
      notifier.min(1);
      notifier.negate();

      expect(notifier.value, -1);

      notifier.reset();
      expect(notifier.value, 0);
    });

    test('ThemeModeNotifier and BrightnessNotifier setters stay in sync', () {
      final themeMode = ThemeMode.system.notifier;
      final brightness = Brightness.light.notifier;

      themeMode.setDark();
      expect(themeMode.isDark, isTrue);
      themeMode.setLight();
      expect(themeMode.isLight, isTrue);
      themeMode.setSystem();
      expect(themeMode.isSystem, isTrue);

      brightness.setDark();
      expect(brightness.isDark, isTrue);
      brightness.setLight();
      expect(brightness.isLight, isTrue);
      brightness.setDart();
      expect(brightness.isDark, isTrue);
    });
  });

  group('read-only delegate surfaces stay pure', () {
    test('ColorNotifier delegates do not notify', () {
      final notifier = const Color(0xFF336699).notifier;

      withProbe(notifier, (probe) {
        expect(notifier.alpha, closeTo(1.0, 0.001));
        expect(notifier.opacity, closeTo(1.0, 0.001));
        expect(notifier.red, closeTo(const Color(0xFF336699).r, 0.001));
        expect(notifier.green, closeTo(const Color(0xFF336699).g, 0.001));
        expect(notifier.blue, closeTo(const Color(0xFF336699).b, 0.001));
        expect(notifier.withAlpha(128).a, closeTo(128 / 255, 0.001));
        expect(notifier.withOpacity(0.5).a, closeTo(0.5, 0.01));
        expect(notifier.withRed(10).r, closeTo(10 / 255, 0.001));
        expect(notifier.withGreen(20).g, closeTo(20 / 255, 0.001));
        expect(notifier.withBlue(30).b, closeTo(30 / 255, 0.001));
        expect(notifier.computeLuminance(), greaterThan(0));
        expectNoNotification(probe);
      });
    });

    test('StringNotifier delegates do not notify', () {
      final notifier = StringNotifier('  Dart-lang  ');

      withProbe(notifier, (probe) {
        expect(notifier[0], ' ');
        expect(notifier.codeUnitAt(2), 'D'.codeUnitAt(0));
        expect(notifier.length, 13);
        expect(notifier.compareTo('zzz'), lessThan(0));
        expect(notifier.endsWith('  '), isTrue);
        expect(notifier.startsWith('  D'), isTrue);
        expect(notifier.indexOf('Dart'), 2);
        expect(notifier.lastIndexOf('a'), greaterThan(0));
        expect(notifier.isEmpty, isFalse);
        expect(notifier.isNotEmpty, isTrue);
        expect(notifier + '!', '  Dart-lang  !');
        expect(notifier.substring(2, 6), 'Dart');
        expect(notifier.trim(), 'Dart-lang');
        expect(notifier.trimLeft(), 'Dart-lang  ');
        expect(notifier.trimRight(), '  Dart-lang');
        expect(notifier * 2, '  Dart-lang    Dart-lang  ');
        expect(notifier.padLeft(15), '    Dart-lang  ');
        expect(notifier.padRight(15), '  Dart-lang    ');
        expect(notifier.contains('lang'), isTrue);
        expect(notifier.replaceFirst('Dart', 'Flutter'), '  Flutter-lang  ');
        expect(
          notifier.replaceFirstMapped(
            'Dart',
            (match) => match[0]!.toLowerCase(),
          ),
          '  dart-lang  ',
        );
        expect(notifier.replaceAll('-', '_'), '  Dart_lang  ');
        expect(
          notifier.replaceAllMapped(
            RegExp(r'[aeiou]'),
            (match) => match[0]!.toUpperCase(),
          ),
          '  DArt-lAng  ',
        );
        expect(notifier.replaceRange(2, 6, 'Code'), '  Code-lang  ');
        expect(notifier.split('-'), ['  Dart', 'lang  ']);
        expect(
          notifier.splitMapJoin(
            '-',
            onMatch: (_) => ':',
            onNonMatch: (part) => part.trim(),
          ),
          'Dart:lang',
        );
        expect(notifier.codeUnits, isNotEmpty);
        expect(notifier.runes, isNotEmpty);
        expect(notifier.toLowerCase(), '  dart-lang  ');
        expect(notifier.toUpperCase(), '  DART-LANG  ');
        expectNoNotification(probe);
      });
    });

    test('UriNotifier delegates do not notify', () {
      final notifier = UriNotifier(
        Uri.parse('https://user@example.com:8443/a/b?x=1&x=2&y=3#frag'),
      );

      withProbe(notifier, (probe) {
        expect(notifier.scheme, 'https');
        expect(notifier.authority, 'user@example.com:8443');
        expect(notifier.userInfo, 'user');
        expect(notifier.host, 'example.com');
        expect(notifier.port, 8443);
        expect(notifier.path, '/a/b');
        expect(notifier.query, 'x=1&x=2&y=3');
        expect(notifier.fragment, 'frag');
        expect(notifier.pathSegments, ['a', 'b']);
        expect(notifier.queryParameters['y'], '3');
        expect(notifier.queryParametersAll['x'], ['1', '2']);
        expect(notifier.isAbsolute, isFalse);
        expect(notifier.hasScheme, isTrue);
        expect(notifier.hasAuthority, isTrue);
        expect(notifier.hasPort, isTrue);
        expect(notifier.hasQuery, isTrue);
        expect(notifier.hasFragment, isTrue);
        expect(notifier.hasEmptyPath, isFalse);
        expect(notifier.hasAbsolutePath, isTrue);
        expect(notifier.origin, 'https://example.com:8443');
        expect(notifier.isScheme('HTTPS'), isTrue);
        expect(notifier.data, isNull);
        expect(
          notifier.replace(path: '/new').toString(),
          'https://user@example.com:8443/new?x=1&x=2&y=3#frag',
        );
        expect(
          notifier.removeFragment().toString(),
          'https://user@example.com:8443/a/b?x=1&x=2&y=3',
        );
        expect(
          notifier.resolve('../c').toString(),
          'https://user@example.com:8443/c',
        );
        expect(
          notifier.resolveUri(Uri.parse('/root')).toString(),
          'https://user@example.com:8443/root',
        );
        expect(notifier.normalizePath().toString(), notifier.value.toString());
        expectNoNotification(probe);
      });
    });

    test('DateTimeNotifier delegates do not notify', () {
      final value = DateTime.utc(2024, 1, 2, 3, 4, 5, 6, 7);
      final notifier = DateTimeNotifier(value);

      withProbe(notifier, (probe) {
        expect(notifier.isEqual(value), isTrue);
        expect(
          notifier.isBefore(value.add(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          notifier.isAfter(value.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(notifier.isAtSameMomentAs(value.toLocal()), isTrue);
        expect(notifier.compareTo(value), 0);
        expect(notifier.toLocal(), isA<DateTime>());
        expect(notifier.toUtc(), value);
        expect(notifier.toIso8601String(), value.toIso8601String());
        expect(
          notifier.add(const Duration(days: 1)),
          value.add(const Duration(days: 1)),
        );
        expect(
          notifier.subtract(const Duration(days: 1)),
          value.subtract(const Duration(days: 1)),
        );
        expect(notifier.difference(value), Duration.zero);
        expect(notifier.millisecondsSinceEpoch, value.millisecondsSinceEpoch);
        expect(notifier.microsecondsSinceEpoch, value.microsecondsSinceEpoch);
        expect(notifier.timeZoneName, value.timeZoneName);
        expect(notifier.timeZoneOffset, value.timeZoneOffset);
        expect(notifier.year, 2024);
        expect(notifier.month, 1);
        expect(notifier.day, 2);
        expect(notifier.hour, 3);
        expect(notifier.minute, 4);
        expect(notifier.second, 5);
        expect(notifier.millisecond, 6);
        expect(notifier.microsecond, 7);
        expect(notifier.weekday, value.weekday);
        expect(notifier.isUtc, isTrue);
        expect(notifier.toString(), value.toString());
        expectNoNotification(probe);
      });
    });

    test('DurationNotifier delegates do not notify', () {
      final notifier = DurationNotifier(const Duration(hours: 2, minutes: 30));

      withProbe(notifier, (probe) {
        expect(notifier * 2, const Duration(hours: 5));
        expect(
          notifier + const Duration(minutes: 30),
          const Duration(hours: 3),
        );
        expect(-notifier, const Duration(hours: -2, minutes: -30));
        expect(
          notifier - const Duration(minutes: 30),
          const Duration(hours: 2),
        );
        expect(notifier < const Duration(hours: 3), isTrue);
        expect(notifier <= const Duration(hours: 2, minutes: 30), isTrue);
        expect(notifier > const Duration(hours: 2), isTrue);
        expect(notifier >= const Duration(hours: 2, minutes: 30), isTrue);
        expect(notifier ~/ 2, const Duration(hours: 1, minutes: 15));
        expect(notifier.abs(), const Duration(hours: 2, minutes: 30));
        expect(notifier.compareTo(const Duration(hours: 2, minutes: 30)), 0);
        expect(notifier.inDays, 0);
        expect(notifier.inHours, 2);
        expect(notifier.inMicroseconds, greaterThan(0));
        expect(notifier.inMilliseconds, greaterThan(0));
        expect(notifier.inMinutes, 150);
        expect(notifier.inSeconds, 9000);
        expect(notifier.isNegative, isFalse);
        expectNoNotification(probe);
      });
    });

    test('numeric value-listenable extensions do not notify', () {
      final numNotifier = NumNotifier(10);
      final doubleNotifier = DoubleNotifier(10.5);
      final intNotifier = IntNotifier(10);
      final ValueListenable<double> asDouble = doubleNotifier;
      final ValueListenable<int> asInt = intNotifier;

      withProbe(numNotifier, (probe) {
        expect(numNotifier.compareTo(2), greaterThan(0));
        expect(numNotifier + 5, 15);
        expect(numNotifier * 2, 20);
        expect(numNotifier % 3, 1);
        expect(numNotifier / 2, 5);
        expect(numNotifier ~/ 3, 3);
        expect(numNotifier.remainder(4), 2);
        expect(numNotifier < 11, isTrue);
        expect(numNotifier <= 10, isTrue);
        expect(numNotifier > 9, isTrue);
        expect(numNotifier >= 10, isTrue);
        expect(numNotifier.isNaN, isFalse);
        expect(numNotifier.isNegative, isFalse);
        expect(numNotifier.isInfinite, isFalse);
        expect(numNotifier.isFinite, isTrue);
        expect(numNotifier.abs(), 10);
        expect(numNotifier.sign, 1);
        expect(numNotifier.round(), 10);
        expect(numNotifier.floor(), 10);
        expect(numNotifier.ceil(), 10);
        expect(numNotifier.truncate(), 10);
        expect(numNotifier.roundToDouble(), 10);
        expect(numNotifier.floorToDouble(), 10);
        expect(numNotifier.ceilToDouble(), 10);
        expect(numNotifier.truncateToDouble(), 10);
        expect(numNotifier.clamp(0, 5), 5);
        expect(numNotifier.toInt(), 10);
        expect(numNotifier.toDouble(), 10);
        expect(numNotifier.toStringAsFixed(2), '10.00');
        expect(numNotifier.toStringAsExponential(), '1e+1');
        expect(numNotifier.toStringAsPrecision(2), '10');
        expectNoNotification(probe);
      });

      withProbe(doubleNotifier, (probe) {
        expect(asDouble.remainder(2), 0.5);
        expect(asDouble + 1, 11.5);
        expect(asDouble - 1, 9.5);
        expect(asDouble * 2, 21);
        expect(asDouble % 2, 0.5);
        expect(asDouble / 2, 5.25);
        expect(asDouble ~/ 2, 5);
        expect(-asDouble, -10.5);
        expect(asDouble.abs(), 10.5);
        expect(asDouble.sign, 1);
        expect(asDouble.round(), 11);
        expect(asDouble.floor(), 10);
        expect(asDouble.ceil(), 11);
        expect(asDouble.truncate(), 10);
        expect(asDouble.roundToDouble(), 11);
        expect(asDouble.floorToDouble(), 10);
        expect(asDouble.ceilToDouble(), 11);
        expect(asDouble.truncateToDouble(), 10);
        expectNoNotification(probe);
      });

      withProbe(intNotifier, (probe) {
        expect(asInt & 3, 2);
        expect(asInt | 3, 11);
        expect(asInt ^ 3, 9);
        expect(~asInt, -11);
        expect(asInt << 1, 20);
        expect(asInt >> 1, 5);
        expect(asInt >>> 1, 5);
        expect(asInt.modPow(3, 7), 6);
        expect(asInt.modInverse(3), 1);
        expect(asInt.gcd(4), 2);
        expect(asInt.isEven, isTrue);
        expect(asInt.isOdd, isFalse);
        expect(asInt.bitLength, greaterThan(0));
        expect(asInt.toUnsigned(4), 10);
        expect(asInt.toSigned(5), 10);
        expect(-asInt, -10);
        expect(asInt.abs(), 10);
        expect(asInt.sign, 1);
        expect(asInt.roundToDouble(), 10);
        expect(asInt.floorToDouble(), 10);
        expect(asInt.ceilToDouble(), 10);
        expect(asInt.truncateToDouble(), 10);
        expect(asInt.toRadixString(16), 'a');
        expectNoNotification(probe);
      });
    });
  });
}
