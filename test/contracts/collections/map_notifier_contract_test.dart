import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/mutable_models.dart';
import '../../helpers/notification_probe.dart';

void main() {
  group('MapNotifier contract', () {
    test('owns its initial map state', () {
      final source = <String, int>{'a': 1};
      final notifier = MapNotifier<String, int>(source);

      source['b'] = 2;

      expect(notifier.value, {'a': 1});
    });

    test('nested and deep mutation require refresh or replace', () {
      final notifier = MapNotifier<String, MutableUser>({
        'a': MutableUser('alpha'),
      });

      withProbe(notifier, (probe) {
        notifier['a']!.name = 'changed';
        expectNoNotification(probe);

        notifier.refresh();
        expectSingleNotification(probe);
      });

      final backing = notifier.value;
      backing['a']!.name = 'updated';

      withProbe(notifier, (probe) {
        notifier.replace(backing);
        expectSingleNotification(probe);
        expect(notifier['a']!.name, 'updated');
        expect(identical(notifier.value, backing), isFalse);
      });
    });

    test(
      'refresh creates a new map identity and replace with a new map notifies once',
      () {
        final notifier = MapNotifier<String, int>({'a': 1});
        final beforeRefresh = notifier.value;

        withProbe(notifier, (probe) {
          notifier.refresh();
          expectSingleNotification(probe);
          expect(identical(notifier.value, beforeRefresh), isFalse);
        });

        withProbe(notifier, (probe) {
          notifier.replace({'b': 2});
          expectSingleNotification(probe);
          expect(notifier.value, {'b': 2});
        });
      },
    );

    test('mutate notifies once and returns the callback result', () {
      final notifier = MapNotifier<String, int>({'a': 1, 'b': 2});

      withProbe(notifier, (probe) {
        final removed = notifier.mutate((map) {
          map['c'] = 3;
          return map.remove('a');
        });

        expect(removed, 1);
        expect(notifier.value, {'b': 2, 'c': 3});
        expectSingleNotification(probe);
        expect(probe.snapshots.single, {'b': 2, 'c': 3});
      }, snapshot: () => Map<String, int>.from(notifier.value));
    });

    test('mutate notifies even when nothing changes', () {
      final notifier = MapNotifier<String, int>({'a': 1});

      withProbe(notifier, (probe) {
        notifier.mutate((map) => map.containsKey('a'));
        expectSingleNotification(probe);
      });
    });

    group('explicit mutators notify exactly once', () {
      final cases =
          <
            String,
            ({
              Map<String, int> initial,
              void Function(MapNotifier<String, int>) act,
              Map<String, int> expected,
            })
          >{
            'operator []=': (
              initial: {'a': 1},
              act: (notifier) => notifier['b'] = 2,
              expected: {'a': 1, 'b': 2},
            ),
            'addAll': (
              initial: {'a': 1},
              act: (notifier) => notifier.addAll({'b': 2}),
              expected: {'a': 1, 'b': 2},
            ),
            'addEntries': (
              initial: {'a': 1},
              act: (notifier) => notifier.addEntries([const MapEntry('b', 2)]),
              expected: {'a': 1, 'b': 2},
            ),
            'putIfAbsent': (
              initial: {'a': 1},
              act: (notifier) => notifier.putIfAbsent('b', () => 2),
              expected: {'a': 1, 'b': 2},
            ),
            'update': (
              initial: {'a': 1},
              act: (notifier) => notifier.update('a', (value) => value + 1),
              expected: {'a': 2},
            ),
            'updateAll': (
              initial: {'a': 1, 'b': 2},
              act: (notifier) => notifier.updateAll((key, value) => value * 2),
              expected: {'a': 2, 'b': 4},
            ),
            'remove': (
              initial: {'a': 1, 'b': 2},
              act: (notifier) => notifier.remove('a'),
              expected: {'b': 2},
            ),
            'removeWhere': (
              initial: {'a': 1, 'b': 2},
              act: (notifier) =>
                  notifier.removeWhere((key, value) => value.isEven),
              expected: {'a': 1},
            ),
            'clear': (
              initial: {'a': 1},
              act: (notifier) => notifier.clear(),
              expected: <String, int>{},
            ),
          };

      for (final entry in cases.entries) {
        test(entry.key, () {
          final notifier = MapNotifier<String, int>(entry.value.initial);

          withProbe(notifier, (probe) {
            entry.value.act(notifier);
            expect(notifier.value, entry.value.expected);
            expectSingleNotification(probe);
          });
        });
      }
    });

    group('eager callback boundaries notify exactly once', () {
      test('forEach refreshes after callback-based inner mutation', () {
        final notifier = MapNotifier<String, MutableUser>({
          'a': MutableUser('alpha'),
          'b': MutableUser('beta'),
        });

        withProbe(
          notifier,
          (probe) {
            notifier.forEach((key, user) {
              if (key == 'a') {
                user.name = 'changed';
              }
            });

            expectSingleNotification(probe);
            expect(notifier['a']!.name, 'changed');
          },
          snapshot: () =>
              notifier.value.map((key, user) => MapEntry(key, user.name)),
        );
      });

      test('map refreshes after callback-based inner mutation', () {
        final notifier = MapNotifier<String, MutableUser>({
          'a': MutableUser('alpha'),
          'b': MutableUser('beta'),
        });

        withProbe(
          notifier,
          (probe) {
            final mapped = notifier.map<String, String>((key, user) {
              if (key == 'b') {
                user.name = 'mapped';
              }
              return MapEntry(key, user.name);
            });

            expect(mapped, {'a': 'alpha', 'b': 'mapped'});
            expectSingleNotification(probe);
            expect(notifier['b']!.name, 'mapped');
          },
          snapshot: () =>
              notifier.value.map((key, user) => MapEntry(key, user.name)),
        );
      });
    });

    group('pure reads stay pure', () {
      final cases = <String, Object? Function(MapNotifier<String, int>)>{
        'containsKey': (notifier) => notifier.containsKey('a'),
        'containsValue': (notifier) => notifier.containsValue(1),
        'operator []': (notifier) => notifier['a'],
        'entries': (notifier) => notifier.entries.toList(),
        'keys': (notifier) => notifier.keys.toList(),
        'values': (notifier) => notifier.values.toList(),
        'length': (notifier) => notifier.length,
        'isEmpty': (notifier) => notifier.isEmpty,
        'isNotEmpty': (notifier) => notifier.isNotEmpty,
        'cast': (notifier) => notifier.cast<String, int>(),
        'isEqual': (notifier) => notifier.isEqual({'a': 1, 'b': 2}),
      };

      for (final entry in cases.entries) {
        test(entry.key, () {
          final notifier = MapNotifier<String, int>({'a': 1, 'b': 2});

          withProbe(notifier, (probe) {
            entry.value(notifier);
            expectNoNotification(probe);
          });
        });
      }
    });

    test('nested collection mutation requires explicit refresh', () {
      final notifier = MapNotifier<String, List<int>>({
        'a': [1, 2],
      });

      withProbe(notifier, (probe) {
        notifier['a']!.add(3);
        expectNoNotification(probe);

        notifier.refresh();
        expectSingleNotification(probe);
      });
    });

    test('listeners observe the final state after mutate', () {
      final notifier = MapNotifier<String, int>({'a': 1, 'b': 2});

      withProbe(notifier, (probe) {
        notifier.mutate((map) {
          map['c'] = 3;
          map.remove('a');
        });

        expect(notifier.value, {'b': 2, 'c': 3});
        expectSingleNotification(probe);
        expect(probe.snapshots.single, {'b': 2, 'c': 3});
      }, snapshot: () => Map<String, int>.from(notifier.value));
    });

    test('concurrent modification through forEach surfaces Dart errors', () {
      final notifier = MapNotifier<String, int>({'a': 1, 'b': 2});

      expect(
        () => notifier.forEach((key, value) {
          notifier.remove(key);
        }),
        throwsA(isA<ConcurrentModificationError>()),
      );
    });
  });
}
