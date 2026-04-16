import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListenablesBuilder contract', () {
    testWidgets('rebuilds when any source changes', (tester) async {
      final first = ValueNotifier<int>(0);
      final second = ValueNotifier<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ListenablesBuilder(
            listenables: [first, second],
            builder: (context) {
              buildCount++;
              return Text('${first.value}:${second.value}');
            },
          ),
        ),
      );

      expect(find.text('0:0'), findsOneWidget);
      expect(buildCount, 1);

      first.value = 1;
      await tester.pump();
      expect(find.text('1:0'), findsOneWidget);

      second.value = 2;
      await tester.pump();
      expect(find.text('1:2'), findsOneWidget);
      expect(buildCount, 3);

      first.dispose();
      second.dispose();
    });

    testWidgets('buildWhen suppresses rebuilds when false', (tester) async {
      final notifier = ValueNotifier<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ListenablesBuilder(
            listenables: [notifier],
            buildWhen: () => false,
            builder: (context) {
              buildCount++;
              return Text('${notifier.value}');
            },
          ),
        ),
      );

      notifier.value = 1;
      await tester.pump();

      expect(buildCount, 1);
      expect(find.text('0'), findsOneWidget);

      notifier.dispose();
    });

    testWidgets('threshold delays but does not drop the latest update', (
      tester,
    ) async {
      final notifier = ValueNotifier<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ListenablesBuilder(
            listenables: [notifier],
            threshold: const Duration(milliseconds: 100),
            builder: (context) {
              buildCount++;
              return Text('${notifier.value}');
            },
          ),
        ),
      );

      notifier.value = 1;
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 2);

      notifier.value = 2;
      await tester.pump();
      expect(buildCount, 2);

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('2'), findsOneWidget);
      expect(buildCount, 3);

      notifier.dispose();
    });

    testWidgets('resubscribes when listenables change', (tester) async {
      final first = ValueNotifier<int>(0);
      final second = ValueNotifier<int>(10);
      var useSecond = false;

      Future<void> pumpHarness() {
        return tester.pumpWidget(
          MaterialApp(
            home: ListenablesBuilder(
              listenables: [useSecond ? second : first],
              builder: (context) {
                final active = useSecond ? second : first;
                return Text('${active.value}');
              },
            ),
          ),
        );
      }

      await pumpHarness();
      expect(find.text('0'), findsOneWidget);

      useSecond = true;
      await pumpHarness();
      expect(find.text('10'), findsOneWidget);

      second.value = 11;
      await tester.pump();
      expect(find.text('11'), findsOneWidget);

      first.value = 1;
      await tester.pump();
      expect(find.text('11'), findsOneWidget);

      first.dispose();
      second.dispose();
    });

    testWidgets('disposing the widget removes listeners safely', (
      tester,
    ) async {
      final notifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ListenablesBuilder(
            listenables: [notifier],
            builder: (context) => Text('${notifier.value}'),
          ),
        ),
      );

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      notifier.value = 1;
      await tester.pump();

      expect(find.text('1'), findsNothing);

      notifier.dispose();
    });
  });
}
