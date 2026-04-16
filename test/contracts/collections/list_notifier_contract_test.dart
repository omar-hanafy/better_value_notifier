import 'dart:math';

import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/mutable_models.dart';
import '../../helpers/notification_probe.dart';

void main() {
  group('ListNotifier contract', () {
    test('owns its initial collection state', () {
      final source = <int>[1, 2];
      final notifier = ListNotifier<int>(source);

      source.add(3);

      expect(notifier.value, [1, 2]);
    });

    test('direct deep mutation does not notify until refresh or update', () {
      final notifier = ListNotifier<MutableUser>([
        MutableUser('a'),
        MutableUser('b'),
      ]);

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
      'refresh creates a new list identity and update with a new list notifies once',
      () {
        final notifier = ListNotifier<int>([1, 2, 3]);
        final beforeRefresh = notifier.value;

        withProbe(notifier, (probe) {
          notifier.refresh();
          expectSingleNotification(probe);
          expect(identical(notifier.value, beforeRefresh), isFalse);
        });

        withProbe(notifier, (probe) {
          notifier.update([4, 5, 6]);
          expectSingleNotification(probe);
          expect(notifier.value, [4, 5, 6]);
        });
      },
    );

    test('mutate notifies exactly once and returns the action result', () {
      final notifier = ListNotifier<int>([1, 2, 3]);

      withProbe(notifier, (probe) {
        final removed = notifier.mutate((list) {
          list.add(4);
          list.removeAt(0);
          return list.removeLast();
        });

        expect(removed, 4);
        expect(notifier.value, [2, 3]);
        expectSingleNotification(probe);
        expect(probe.snapshots.single, [2, 3]);
      }, snapshot: () => List<int>.from(notifier.value));
    });

    test('mutate notifies even when nothing changes', () {
      final notifier = ListNotifier<int>([1, 2, 3]);

      withProbe(notifier, (probe) {
        notifier.mutate((list) => list.contains(1));
        expectSingleNotification(probe);
      });
    });

    group('explicit mutators notify exactly once', () {
      final cases =
          <
            String,
            ({
              List<int> initial,
              void Function(ListNotifier<int>) act,
              List<int> expected,
            })
          >{
            'operator []=': (
              initial: [1, 2, 3],
              act: (notifier) => notifier[1] = 9,
              expected: [1, 9, 3],
            ),
            'add': (
              initial: [1],
              act: (notifier) => notifier.add(2),
              expected: [1, 2],
            ),
            'addAll': (
              initial: [1],
              act: (notifier) => notifier.addAll([2, 3]),
              expected: [1, 2, 3],
            ),
            'insert': (
              initial: [1, 3],
              act: (notifier) => notifier.insert(1, 2),
              expected: [1, 2, 3],
            ),
            'insertAll': (
              initial: [1, 4],
              act: (notifier) => notifier.insertAll(1, [2, 3]),
              expected: [1, 2, 3, 4],
            ),
            'remove': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.remove(2),
              expected: [1, 3],
            ),
            'removeAt': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.removeAt(1),
              expected: [1, 3],
            ),
            'removeLast': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.removeLast(),
              expected: [1, 2],
            ),
            'removeRange': (
              initial: [1, 2, 3, 4],
              act: (notifier) => notifier.removeRange(1, 3),
              expected: [1, 4],
            ),
            'removeWhere': (
              initial: [1, 2, 3, 4],
              act: (notifier) => notifier.removeWhere((value) => value.isEven),
              expected: [1, 3],
            ),
            'retainWhere': (
              initial: [1, 2, 3, 4],
              act: (notifier) => notifier.retainWhere((value) => value.isEven),
              expected: [2, 4],
            ),
            'clear': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.clear(),
              expected: <int>[],
            ),
            'sort': (
              initial: [3, 1, 2],
              act: (notifier) => notifier.sort(),
              expected: [1, 2, 3],
            ),
            'shuffle': (
              initial: [1, 2, 3, 4, 5],
              act: (notifier) => notifier.shuffle(Random(1)),
              expected: [1, 2, 3, 4, 5],
            ),
            'fillRange': (
              initial: [0, 0, 0, 0],
              act: (notifier) => notifier.fillRange(1, 3, 9),
              expected: [0, 9, 9, 0],
            ),
            'replaceRange': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.replaceRange(1, 2, [8, 9]),
              expected: [1, 8, 9, 3],
            ),
            'setRange': (
              initial: [1, 2, 3, 4],
              act: (notifier) => notifier.setRange(1, 3, [9, 8]),
              expected: [1, 9, 8, 4],
            ),
            'setAll': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.setAll(1, [9, 8]),
              expected: [1, 9, 8],
            ),
            'length=': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.length = 2,
              expected: [1, 2],
            ),
            'first=': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.first = 9,
              expected: [9, 2, 3],
            ),
            'last=': (
              initial: [1, 2, 3],
              act: (notifier) => notifier.last = 9,
              expected: [1, 2, 9],
            ),
          };

      for (final entry in cases.entries) {
        test(entry.key, () {
          final notifier = ListNotifier<int>(entry.value.initial);

          withProbe(notifier, (probe) {
            entry.value.act(notifier);
            expectSingleNotification(probe);
            if (entry.key == 'shuffle') {
              expect(notifier.value, unorderedEquals(entry.value.expected));
              expect(notifier.value.length, entry.value.expected.length);
            } else {
              expect(notifier.value, entry.value.expected);
            }
          });
        });
      }
    });

    group('eager callback boundaries notify exactly once', () {
      final cases = <String, Object? Function(ListNotifier<MutableUser>)>{
        'indexWhere': (notifier) => notifier.indexWhere((user) {
          user.name = 'index-where';
          return true;
        }),
        'lastIndexWhere': (notifier) => notifier.lastIndexWhere((user) {
          user.name = 'last-index-where';
          return true;
        }),
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
              ? ListNotifier<MutableUser>([MutableUser('a')])
              : ListNotifier<MutableUser>([MutableUser('a'), MutableUser('b')]);

          withProbe(
            notifier,
            (probe) {
              entry.value(notifier);
              expectSingleNotification(probe);
              expect(
                notifier.value.any(
                  (user) =>
                      user.name.contains('-') ||
                      user.name == entry.key.replaceAll('Where', '-where'),
                ),
                isTrue,
              );
            },
            snapshot: () => notifier.value.map((user) => user.name).toList(),
          );
        });
      }
    });

    group('pure reads stay pure', () {
      final cases = <String, Object? Function(ListNotifier<int>)>{
        'contains': (notifier) => notifier.contains(2),
        'indexOf': (notifier) => notifier.indexOf(2),
        'lastIndexOf': (notifier) => notifier.lastIndexOf(2),
        'sublist': (notifier) => notifier.sublist(1),
        'getRange': (notifier) => notifier.getRange(0, 2).toList(),
        'toList': (notifier) => notifier.toList(),
        'toSet': (notifier) => notifier.toSet(),
        'asMap': (notifier) => notifier.asMap(),
        'elementAt': (notifier) => notifier.elementAt(1),
        'first': (notifier) => notifier.first,
        'last': (notifier) => notifier.last,
        'reversed': (notifier) => notifier.reversed.toList(),
        'followedBy': (notifier) => notifier.followedBy([4]).toList(),
        'map': (notifier) => notifier.map((value) => value * 2).toList(),
        'where': (notifier) => notifier.where((value) => value.isEven).toList(),
        'expand': (notifier) =>
            notifier.expand((value) => [value, value]).toList(),
        'whereType': (notifier) => notifier.whereType<int>().toList(),
        'take': (notifier) => notifier.take(2).toList(),
        'skip': (notifier) => notifier.skip(1).toList(),
        'takeWhile': (notifier) =>
            notifier.takeWhile((value) => value < 3).toList(),
        'skipWhile': (notifier) =>
            notifier.skipWhile((value) => value < 3).toList(),
        'cast': (notifier) => notifier.cast<int>(),
        'iterator': (notifier) {
          final iterator = notifier.iterator;
          iterator.moveNext();
          return iterator.current;
        },
        'length': (notifier) => notifier.length,
        'isEmpty': (notifier) => notifier.isEmpty,
        'isNotEmpty': (notifier) => notifier.isNotEmpty,
        'join': (notifier) => notifier.join(','),
      };

      for (final entry in cases.entries) {
        test(entry.key, () {
          final notifier = ListNotifier<int>([1, 2, 3]);

          withProbe(notifier, (probe) {
            entry.value(notifier);
            expectNoNotification(probe);
          });
        });
      }

      test('single on single-item list stays pure', () {
        final notifier = ListNotifier<int>([1]);

        withProbe(notifier, (probe) {
          expect(notifier.single, 1);
          expectNoNotification(probe);
        });
      });
    });

    test('lazy iterables see later mutations when re-iterated', () {
      final notifier = ListNotifier<int>([1, 2, 3]);
      final even = notifier.where((value) => value.isEven);
      final duplicated = notifier.map((value) => value * 2);

      expect(even.toList(), [2]);
      expect(duplicated.toList(), [2, 4, 6]);

      notifier.add(4);

      expect(even.toList(), [2, 4]);
      expect(duplicated.toList(), [2, 4, 6, 8]);
    });

    test('concurrent modification through forEach surfaces Dart errors', () {
      final notifier = ListNotifier<int>([1, 2, 3]);
      void addMarker(int _) => notifier.add(99);

      expect(
        () => notifier.forEach(addMarker),
        throwsA(isA<ConcurrentModificationError>()),
      );
    });

    test('listeners observe final state after a single mutate boundary', () {
      final notifier = ListNotifier<int>([1, 2, 3]);

      withProbe(notifier, (probe) {
        notifier.mutate((list) {
          list.add(4);
          list.removeAt(0);
          list.sort();
        });

        expect(notifier.value, [2, 3, 4]);
        expectSingleNotification(probe);
        expect(probe.snapshots.single, [2, 3, 4]);
      }, snapshot: () => List<int>.from(notifier.value));
    });
  });
}
