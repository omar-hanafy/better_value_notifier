# better_value_notifier

Typed `ValueNotifier` wrappers, reactive extensions, and small builder widgets for Flutter.

This package extracts the notifier-related APIs out of `flutter_helper_utils` into a focused standalone package with:

- typed notifiers like `BoolNotifier`, `ListNotifier`, `MapNotifier`, `SetNotifier`, `ThemeModeNotifier`, and more
- listenable composition helpers like `map`, `select`, `combine`, and `distinct`
- stream-to-notifier bridging with `StreamValueNotifier`
- widget helpers like `ListenablesBuilder`

## Install

```yaml
dependencies:
  better_value_notifier: ^1.0.0
```

## Quick start

```dart
import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter/material.dart';

final isDarkMode = false.notifier;
final counter = 0.notifier;
final tags = <String>{'flutter', 'dart'}.notifier;

final isEven = counter.map((value) => value.isEven);
```

## Examples

### Typed notifiers

```dart
final enabled = true.notifier;
enabled.toggle();
enabled.setFalse();

final items = <String>['a', 'b'].notifier;
items.add('c');
items.refresh();
items.mutate((list) {
  list.add('d');
  list.remove('a');
});

final themeMode = ThemeMode.system.notifier;
themeMode.setDark();
```

### Derived listenables

```dart
final firstName = ValueNotifier('Omar');
final lastName = ValueNotifier('Hanafy');

final fullName = firstName.combine(
  lastName,
  (first, last) => '$first $last',
);
```

### Stream bridge

```dart
final notifier = stream.toValueNotifier(
  initialValue,
  onDone: (latestValue) {
    debugPrint('done with $latestValue');
  },
);
```

### Widget helpers

```dart
ListenablesBuilder(
  listenables: [firstName, lastName],
  builder: (context) {
    return Text('${firstName.value} ${lastName.value}');
  },
);
```

## API overview

- `better_value_notifier.dart`: full public API
- `extensions.dart`: listenable and notifier extensions
- `notifier_classes.dart`: typed notifier classes
- `widgets.dart`: builder widgets

## Notes

- Collection notifiers clone on `refresh()` so in-place mutations still notify listeners.
- `ListNotifier`, `MapNotifier`, and `SetNotifier` own their collection state instead of aliasing the source collection you pass in.
- `mutate(...)` is the explicit safe boundary for nested and in-place collection mutations.
- Eager callback-based collection methods like `forEach`, `fold`, `reduce`, `every`, `any`, `firstWhere`, `lastWhere`, `singleWhere`, and list index search helpers refresh after execution.
- Lazy iterable adapters like `where`, `map`, `expand`, `takeWhile`, and `skipWhile` stay pure and do not notify when created.
- `update(...)` force-notifies only when the incoming value is effectively unchanged.
- Immutable wrapper helpers like `StringNotifier` and `UriNotifier` keep read methods pure.
