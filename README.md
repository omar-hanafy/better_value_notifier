# better_value_notifier

Typed `ValueNotifier` wrappers, reactive extensions, and small builder widgets for Flutter.

`better_value_notifier` is designed for apps that want the simplicity of `ValueNotifier`, but with:

- typed notifier classes for common value kinds
- collection-aware mutation boundaries
- derived listenables and stream bridging
- lightweight widget helpers for rebuilding from listenables

## Features

- Primitive notifiers like `BoolNotifier`, `IntNotifier`, `DoubleNotifier`, `NumNotifier`, `StringNotifier`, `DateTimeNotifier`, `DurationNotifier`, `UriNotifier`, `ThemeModeNotifier`, and `BrightnessNotifier`
- Collection notifiers like `ListNotifier`, `MapNotifier`, and `SetNotifier`
- Reactive helpers like `map`, `select`, `distinct`, and `combine`
- Stream bridging through `StreamValueNotifier` and `toValueNotifier(...)`
- Widget helpers like `ListenablesBuilder` plus `builder(...)` extensions on `Listenable` and `ValueListenable`

## Install

```yaml
dependencies:
  better_value_notifier: ^1.0.0
```

## Quick start

```dart
import 'package:better_value_notifier/better_value_notifier.dart';
import 'package:flutter/material.dart';

final enabled = false.notifier;
final counter = 0.notifier;
final tags = <String>['flutter', 'dart'].notifier;

final isEven = counter.map((value) => value.isEven);
```

## Basic usage

### Primitive values

```dart
final enabled = true.notifier;
enabled.toggle();
enabled.setFalse();

final themeMode = ThemeMode.system.notifier;
themeMode.setDark();
```

### Collection values

```dart
final items = <String>['a', 'b'].notifier;

items.add('c');

items.mutate((list) {
  list.add('d');
  list.remove('a');
});
```

### Derived values

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

## Notification model

The package follows a clear contract for when listeners are notified.

### 1. Explicit mutators notify

Collection writes like `add`, `remove`, `[]=`, `clear`, `updateAll`, `sort`, and `retainWhere` notify automatically.

### 2. `mutate(...)` is the explicit in-place mutation boundary

Use `mutate(...)` when you want to perform multiple collection changes or nested changes and notify exactly once at the end.

```dart
users.mutate((list) {
  list.add(user);
  list.sort((a, b) => a.name.compareTo(b.name));
});
```

### 3. Direct deep mutation through `.value` is not auto-detected

If you mutate an inner object directly, call `refresh()`, `update(...)`, `replace(...)`, or `mutate(...)` afterward.

```dart
users.value.first.name = 'Updated';
users.refresh();
```

### 4. Eager callback-based collection methods refresh after execution

Methods like `forEach`, `fold`, `reduce`, `every`, `any`, `firstWhere`, `lastWhere`, `singleWhere`, and list index-search helpers act as notification boundaries for collection notifiers.

### 5. Lazy adapters stay pure

Methods like `where`, `map`, `expand`, `takeWhile`, and `skipWhile` do not notify when created.

### 6. Immutable-style wrappers keep read methods pure

Wrappers like `StringNotifier`, `UriNotifier`, `DateTimeNotifier`, `DurationNotifier`, and `ColorNotifier` do not notify for read or transform helpers that return new values.

## Public API

- `better_value_notifier.dart`
  Full package export
- `extensions.dart`
  Reactive and convenience extensions
- `notifier_classes.dart`
  Typed notifier classes
- `widgets.dart`
  Widget helpers

## Notes

- Collection notifiers own their internal collection state instead of aliasing the source collection passed into the constructor.
- `refresh()` always notifies, even if the outer value is unchanged.
- `update(...)` force-notifies when the incoming value is effectively unchanged.
- `StreamValueNotifier` should be disposed when no longer needed so the stream subscription is cancelled.
