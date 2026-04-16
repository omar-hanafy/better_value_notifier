import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ExampleApp());
}

/// Minimal Flutter app demonstrating the package's typed notifiers.
class ExampleApp extends StatelessWidget {
  /// Creates the example app.
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const CounterScreen(),
    );
  }
}

/// Example screen showing a counter powered by `IntNotifier`.
class CounterScreen extends StatefulWidget {
  /// Creates the counter screen.
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final IntNotifier counter = 0.notifier;
  late final DerivedValueListenable<bool> isEven = counter.map(
    (value) => value.isEven,
  );

  @override
  void dispose() {
    isEven.dispose();
    counter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('better_value_notifier example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            counter.builder(
              (value) => Text(
                'Count: $value',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: isEven,
              builder: (context, even, child) {
                return Text(even ? 'The value is even' : 'The value is odd');
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => counter.value++,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
