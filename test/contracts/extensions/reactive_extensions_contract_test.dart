import 'dart:async';

import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reactive extensions contract', () {
    test(
      'map, select, distinct, and combine only notify on meaningful change',
      () {
        final source = ValueNotifier<int>(1);
        final mapped = source.map((value) => value.isEven);
        final selected = source.select((value) => value % 2);
        final distinct = source.distinct();
        final second = ValueNotifier<int>(10);
        final combined = source.combine(
          second,
          (first, other) => first + other,
        );

        var mappedCount = 0;
        var selectedCount = 0;
        var distinctCount = 0;
        var combinedCount = 0;

        mapped.addListener(() => mappedCount++);
        selected.addListener(() => selectedCount++);
        distinct.addListener(() => distinctCount++);
        combined.addListener(() => combinedCount++);

        source.value = 3;
        expect(mappedCount, 0);
        expect(selectedCount, 0);
        expect(distinctCount, 1);
        expect(combinedCount, 1);

        source.value = 4;
        expect(mapped.value, isTrue);
        expect(selected.value, 0);
        expect(mappedCount, 1);
        expect(selectedCount, 1);
        expect(distinctCount, 2);
        expect(combinedCount, 2);

        second.value = 20;
        expect(combined.value, 24);
        expect(combinedCount, 3);

        mapped.dispose();
        selected.dispose();
        distinct.dispose();
        combined.dispose();
        source.dispose();
        second.dispose();
      },
    );

    test('onChange remover stops callbacks', () {
      final notifier = ValueNotifier<int>(0);
      final values = <int>[];

      final remove = notifier.onChange(values.add);
      notifier.value = 1;
      notifier.value = 2;
      remove();
      notifier.value = 3;

      expect(values, [1, 2]);
      notifier.dispose();
    });

    test('debounce emits only the settled value', () async {
      final notifier = ValueNotifier<int>(0);
      final completer = Completer<int>();

      final remove = notifier.debounce(const Duration(milliseconds: 10), (
        value,
      ) {
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      });

      notifier.value = 1;
      notifier.value = 2;
      notifier.value = 3;

      expect(await completer.future, 3);

      remove();
      notifier.dispose();
    });

    test('stream emits the initial value and later updates in order', () async {
      final notifier = ValueNotifier<int>(1);
      final values = <int>[];
      final subscription = notifier.stream.listen(values.add);

      await Future<void>.delayed(Duration.zero);
      notifier.value = 2;
      notifier.value = 3;
      await Future<void>.delayed(Duration.zero);

      await subscription.cancel();
      notifier.dispose();

      expect(values, [1, 2, 3]);
    });

    test('toValueNotifier mirrors stream events and reports onDone', () async {
      final controller = StreamController<int>();
      int? doneValue;
      final notifier = controller.stream.toValueNotifier(
        0,
        onDone: (value) => doneValue = value,
      );

      controller.add(1);
      await Future<void>.delayed(Duration.zero);
      controller.add(2);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.value, 2);

      await controller.close();
      await Future<void>.delayed(Duration.zero);

      expect(doneValue, 2);
      notifier.dispose();
    });

    test('disposing StreamValueNotifier prevents later updates', () async {
      final controller = StreamController<int>();
      final notifier = controller.stream.toValueNotifier(0);

      await controller.addStream(Stream<int>.fromIterable([1, 2]));
      await Future<void>.delayed(Duration.zero);
      expect(notifier.value, 2);

      notifier.dispose();

      controller.add(3);
      await Future<void>.delayed(Duration.zero);

      expect(notifier.value, 2);
      await controller.close();
    });
  });
}
