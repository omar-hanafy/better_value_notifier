import 'dart:async';

import 'package:flutter/foundation.dart';

/// Equality function used by [DerivedValueListenable] to suppress unchanged
/// derived values.
typedef ValueEquality<T> = bool Function(T previous, T next);

/// A read-only [ValueListenable] derived from one or more source listenables.
///
/// The current value is recomputed whenever any dependency notifies. If the
/// new computed value compares equal to the previous one, listeners are not
/// notified.
///
/// Dispose the derived listenable when you are done with it so it can detach
/// from its dependencies.
class DerivedValueListenable<T> extends ChangeNotifier
    implements ValueListenable<T> {
  /// Creates a derived value from [dependencies] using [compute].
  ///
  /// When any dependency notifies, [compute] is called again. Listeners are
  /// notified only if the computed value changed according to [equals], which
  /// defaults to `==`.
  DerivedValueListenable.compute({
    required Iterable<Listenable> dependencies,
    required T Function() compute,
    ValueEquality<T>? equals,
  }) : _compute = compute,
       _equals = equals ?? _defaultEquals,
       _dependencies = List<Listenable>.unmodifiable({...dependencies}),
       _value = compute() {
    for (final dependency in _dependencies) {
      dependency.addListener(_recompute);
    }
  }

  final T Function() _compute;
  final ValueEquality<T> _equals;
  final List<Listenable> _dependencies;
  bool _isDisposed = false;
  T _value;

  static bool _defaultEquals<T>(T previous, T next) => previous == next;

  @override
  T get value => _value;

  void _recompute() {
    if (_isDisposed) {
      return;
    }

    final nextValue = _compute();
    if (_equals(_value, nextValue)) {
      return;
    }

    _value = nextValue;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    for (final dependency in _dependencies) {
      dependency.removeListener(_recompute);
    }
    super.dispose();
  }
}

/// Shorthand accessors for reading and writing [ValueNotifier.value].
extension FHUValueNotifierExtensions<T> on ValueNotifier<T> {
  /// Equivalent to the getter [value] but in shorter syntax.
  T get v => value;

  set v(T newValue) => value = newValue;
}

/// Reactive helpers for listening to any [ValueListenable].
extension FHUValueListenableExtensions<T> on ValueListenable<T> {
  /// Derives a new read-only [ValueListenable] by transforming the current
  /// value with [transform].
  ///
  /// The returned listenable updates whenever this listenable updates. It only
  /// notifies when the transformed value actually changes according to
  /// [equals], which defaults to `==`.
  DerivedValueListenable<R> map<R>(
    R Function(T value) transform, {
    ValueEquality<R>? equals,
  }) => DerivedValueListenable<R>.compute(
    dependencies: [this],
    compute: () => transform(value),
    equals: equals,
  );

  /// Like [map], but intended for selecting a stable sub-value from a larger
  /// state object.
  ///
  /// This is useful when the source object changes frequently but the selected
  /// field often stays the same.
  DerivedValueListenable<R> select<R>(
    R Function(T value) selector, {
    ValueEquality<R>? equals,
  }) => map(selector, equals: equals);

  /// Returns a derived listenable that only forwards distinct values from this
  /// listenable.
  ///
  /// Use [equals] for custom equality, for example collection equality.
  DerivedValueListenable<T> distinct({ValueEquality<T>? equals}) =>
      DerivedValueListenable<T>.compute(
        dependencies: [this],
        compute: () => value,
        equals: equals,
      );

  /// Combines this listenable with [other] into a new derived listenable.
  ///
  /// The returned listenable recomputes whenever either dependency changes and
  /// only notifies when the combined value changes according to [equals].
  DerivedValueListenable<R> combine<U, R>(
    ValueListenable<U> other,
    R Function(T first, U second) combine, {
    ValueEquality<R>? equals,
  }) => DerivedValueListenable<R>.compute(
    dependencies: [this, other],
    compute: () => combine(value, other.value),
    equals: equals,
  );

  /// Registers a callback to be invoked whenever the `ValueNotifier`'s value changes.
  VoidCallback onChange(void Function(T value) action) {
    void listener() => action(value);
    addListener(listener);
    return () => removeListener(listener);
  }

  /// Registers a debounced callback which is invoked only after the notifier's value
  /// is stable for the specified [duration].
  VoidCallback debounce(Duration duration, void Function(T value) action) {
    Timer? debounceTimer;

    void listener() {
      debounceTimer?.cancel();
      debounceTimer = Timer(duration, () => action(value));
    }

    addListener(listener);

    return () {
      debounceTimer?.cancel();
      removeListener(listener);
    };
  }

  /// Converts this [ValueListenable] into a broadcast [Stream].
  ///
  /// The current [value] is emitted immediately when the first listener
  /// subscribes, then emitted again whenever the listenable notifies.
  Stream<T> get stream {
    late final StreamController<T> controller;
    VoidCallback? listener;

    void emit() => controller.add(value);

    controller = StreamController<T>.broadcast(
      sync: true,
      onListen: () {
        listener ??= emit;
        addListener(listener!);
        emit();
      },
      onCancel: () {
        final activeListener = listener;
        if (activeListener == null) {
          return;
        }
        removeListener(activeListener);
      },
    );

    return controller.stream;
  }
}
