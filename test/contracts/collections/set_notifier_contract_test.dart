import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/mutable_models.dart';
import '../../helpers/notification_probe.dart';

void main() {
  group('SetNotifier contract', () {
    test('owns its initial set state', () {
      final source = <int>{1, 2};
      final notifier = SetNotifier<int>(source);

      source.add(3);

      expect(notifier.value, {1, 2});
    });

    test('deep mutation requires refresh or update', () {
      final notifier = SetNotifier<MutableUser>({MutableUser('alpha')});

      withProbe(notifier, (probe) {
        notifier.value.first.name = 'changed';
        expectNoNotification(probe);

        notifier.refresh();
        expectSingleNotification(probe);
      });

      final backing = notifier.value;
      backing.first.name = 'updated';

      withProbe(notifier, (probe) {
        notifier.update(backing);
        expectSingleNotification(probe);
        expect(notifier.value.first.name, 'updated');
        expect(identical(notifier.value, backing), isFalse);
      });
    });

    test(
      'refresh creates a new set identity and update with a new set notifies once',
      () {
        final notifier = SetNotifier<int>({1, 2, 3});
        final beforeRefresh = notifier.value;

        withProbe(notifier, (probe) {
          notifier.refresh();
          expectSingleNotification(probe);
          expect(identical(notifier.value, beforeRefresh), isFalse);
        });

        withProbe(notifier, (probe) {
          notifier.update({4, 5});
          expectSingleNotification(probe);
          expect(notifier.value, {4, 5});
        });
      },
    );

    test('mutate notifies once and returns the callback result', () {
      final notifier = SetNotifier<int>({1, 2, 3});

      withProbe(notifier, (probe) {
        final result = notifier.mutate((set) {
          set.add(4);
          set.remove(1);
          return set.contains(4);
        });

        expect(result, isTrue);
        expect(notifier.value, {2, 3, 4});
        expectSingleNotification(probe);
        expect(probe.snapshots.single, {2, 3, 4});
      }, snapshot: () => Set<int>.from(notifier.value));
    });

    test('mutate notifies even when nothing changes', () {
      final notifier = SetNotifier<int>({1, 2});

      withProbe(notifier, (probe) {
        notifier.mutate((set) => set.contains(1));
        expectSingleNotification(probe);
      });
    });

    group('explicit mutators notify exactly once', () {
      final cases =
          <
            String,
            ({
              Set<int> initial,
              void Function(SetNotifier<int>) act,
              Set<int> expected,
            })
          >{
            'add': (
              initial: {1, 2},
              act: (notifier) => notifier.add(3),
              expected: {1, 2, 3},
            ),
            'addAll': (
              initial: {1, 2},
              act: (notifier) => notifier.addAll({3, 4}),
              expected: {1, 2, 3, 4},
            ),
            'remove': (
              initial: {1, 2},
              act: (notifier) => notifier.remove(1),
              expected: {2},
            ),
            'removeAll': (
              initial: {1, 2, 3},
              act: (notifier) => notifier.removeAll({1, 3}),
              expected: {2},
            ),
            'removeWhere': (
              initial: {1, 2, 3},
              act: (notifier) => notifier.removeWhere((value) => value.isEven),
              expected: {1, 3},
            ),
            'retainAll': (
              initial: {1, 2, 3},
              act: (notifier) => notifier.retainAll({2, 3, 4}),
              expected: {2, 3},
            ),
            'retainWhere': (
              initial: {1, 2, 3},
              act: (notifier) => notifier.retainWhere((value) => value.isOdd),
              expected: {1, 3},
            ),
            'clear': (
              initial: {1, 2},
              act: (notifier) => notifier.clear(),
              expected: <int>{},
            ),
          };

      for (final entry in cases.entries) {
        test(entry.key, () {
          final notifier = SetNotifier<int>(entry.value.initial);

          withProbe(notifier, (probe) {
            entry.value.act(notifier);
            expect(notifier.value, entry.value.expected);
            expectSingleNotification(probe);
          });
        });
      }
    });

    group('eager callback boundaries notify exactly once', () {
      final cases = <String, Object? Function(SetNotifier<MutableUser>)>{
        'forEach': (notifier) {
          void rename(MutableUser user) {
            user.name = 'for-each';
          }

          return notifier.forEach(rename);
        },
        'reduce': (notifier) => notifier.reduce((previous, element) {
          previous.name = 'reduce';
          return previous;
        }),
        'fold': (notifier) => notifier.fold<int>(0, (total, user) {
          user.name = 'fold';
          return total + 1;
        }),
        'every': (notifier) => notifier.every((user) {
          user.name = 'every';
          return true;
        }),
        'any': (notifier) => notifier.any((user) {
          user.name = 'any';
          return true;
        }),
        'firstWhere': (notifier) => notifier.firstWhere((user) {
          user.name = 'first-where';
          return true;
        }),
        'lastWhere': (notifier) => notifier.lastWhere((user) {
          user.name = 'last-where';
          return true;
        }),
        'singleWhere': (notifier) => notifier.singleWhere((user) {
          user.name = 'single-where';
          return true;
        }),
      };

      for (final entry in cases.entries) {
        test(entry.key, () {
          final notifier = entry.key == 'singleWhere'
              ? SetNotifier<MutableUser>({MutableUser('alpha')})
              : SetNotifier<MutableUser>({
                  MutableUser('alpha'),
                  MutableUser('beta'),
                });

          withProbe(
            notifier,
            (probe) {
              entry.value(notifier);
              expectSingleNotification(probe);
              expect(
                notifier.value.any(
                  (user) => user.name.contains('-') || user.name == entry.key,
                ),
                isTrue,
              );
            },
            snapshot: () => notifier.value.map((user) => user.name).toSet(),
          );
        });
      }
    });

    group('pure reads stay pure', () {
      final cases = <String, Object? Function(SetNotifier<int>)>{
        'contains': (notifier) => notifier.contains(1),
        'containsAll': (notifier) => notifier.containsAll({1, 2}),
        'difference': (notifier) => notifier.difference({1}),
        'intersection': (notifier) => notifier.intersection({1, 9}),
        'union': (notifier) => notifier.union({4}),
        'lookup': (notifier) => notifier.lookup(1),
        'toList': (notifier) => notifier.toList(),
        'toSet': (notifier) => notifier.toSet(),
        'length': (notifier) => notifier.length,
        'isEmpty': (notifier) => notifier.isEmpty,
        'isNotEmpty': (notifier) => notifier.isNotEmpty,
        'where': (notifier) => notifier.where((value) => value.isEven).toList(),
        'map': (notifier) => notifier.map((value) => value * 2).toList(),
        'expand': (notifier) =>
            notifier.expand((value) => [value, value]).toList(),
        'whereType': (notifier) => notifier.whereType<int>().toList(),
        'takeWhile': (notifier) =>
            notifier.takeWhile((value) => value < 3).toList(),
        'skipWhile': (notifier) =>
            notifier.skipWhile((value) => value < 2).toList(),
        'join': (notifier) => notifier.join(','),
        'take': (notifier) => notifier.take(2).toList(),
        'skip': (notifier) => notifier.skip(1).toList(),
        'cast': (notifier) => notifier.cast<int>(),
        'iterator': (notifier) {
          final iterator = notifier.iterator;
          iterator.moveNext();
          return iterator.current;
        },
        'first': (notifier) => notifier.first,
        'last': (notifier) => notifier.last,
        'single': (notifier) => SetNotifier<int>({1}).single,
        'elementAt': (notifier) => notifier.elementAt(1),
      };

      for (final entry in cases.entries) {
        test(entry.key, () {
          final notifier = SetNotifier<int>({1, 2, 3});

          withProbe(notifier, (probe) {
            entry.value(notifier);
            expectNoNotification(probe);
          });
        });
      }
    });

    test('hash-based element mutation is unsafe even after refresh', () {
      final user = HashMutableUser('alpha');
      final notifier = SetNotifier<HashMutableUser>({user});

      expect(notifier.contains(user), isTrue);

      user.name = 'beta';

      expect(notifier.contains(user), isFalse);

      notifier.refresh();

      expect(notifier.contains(user), isFalse);
    });

    test('concurrent modification through forEach surfaces Dart errors', () {
      final notifier = SetNotifier<int>({1, 2, 3});
      void addMarker(int _) => notifier.add(99);

      expect(
        () => notifier.forEach(addMarker),
        throwsA(isA<ConcurrentModificationError>()),
      );
    });

    test('listeners observe final state after mutate', () {
      final notifier = SetNotifier<int>({1, 2, 3});

      withProbe(notifier, (probe) {
        notifier.mutate((set) {
          set.remove(1);
          set.add(4);
        });

        expect(notifier.value, {2, 3, 4});
        expectSingleNotification(probe);
        expect(probe.snapshots.single, {2, 3, 4});
      }, snapshot: () => Set<int>.from(notifier.value));
    });
  });
}
