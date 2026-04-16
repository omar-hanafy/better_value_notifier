import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

/// A [ValueNotifier] wrapper around a mutable [Set].
///
/// Mutating operations refresh the wrapped set so listeners are notified even
/// when the mutation happened in place.
class SetNotifier<E> extends ValueNotifier<Set<E>> implements Set<E> {
  /// Creates a notifier backed by an initial set.
  SetNotifier(Set<E> initial) : super(Set<E>.from(initial));

  SetNotifier._raw(super.initial);

  /// Creates a set notifier containing all [elements].
  factory SetNotifier.from(Iterable<E> elements) =>
      SetNotifier._raw(Set<E>.from(elements));

  /// Creates a set notifier containing all [elements].
  factory SetNotifier.of(Iterable<E> elements) =>
      SetNotifier._raw(Set<E>.of(elements));

  /// Creates an unmodifiable set notifier containing all [elements].
  factory SetNotifier.unmodifiable(Iterable<E> elements) =>
      SetNotifier._raw(Set<E>.unmodifiable(elements));

  /// Casts [source] to a [SetNotifier] with element type [T].
  static SetNotifier<T> castFrom<S, T>(
    Set<S> source, {
    Set<R> Function<R>()? newSet,
  }) => SetNotifier<T>._raw(Set.castFrom<S, T>(source, newSet: newSet));

  @override
  void notifyListeners() {
    try {
      super.notifyListeners();
    } catch (_) {}
  }

  /// Replaces the current set value.
  void update(Set<E> newValue) {
    final previous = value;
    if (identical(previous, newValue)) {
      refresh();
      return;
    }
    value = Set<E>.from(newValue);
  }

  /// Clones the current set so listeners are notified after in-place changes.
  void refresh() {
    final current = value;
    final refreshed = {...current};
    value = refreshed;
    if (identical(current, refreshed)) {
      notifyListeners();
    }
  }

  R _mutate<R>(R Function(Set<E> current) action) {
    final result = action(value);
    refresh();
    return result;
  }

  /// Executes [action] against the current set and refreshes afterward.
  ///
  /// This acts as an explicit notification boundary for in-place or nested
  /// mutations that do not replace the set instance.
  R mutate<R>(R Function(Set<E> set) action) {
    final result = action(value);
    refresh();
    return result;
  }

  /// Compares two sets for element-by-element equality.
  bool isEqual(Set<E> other) => setEquals(value, other);

  @override
  Set<R> cast<R>() => value.cast<R>();

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  bool add(E value) => _mutate((current) => current.add(value));

  @override
  void addAll(Iterable<E> elements) =>
      _mutate((current) => current.addAll(elements));

  @override
  bool contains(Object? element) => value.contains(element);

  @override
  bool containsAll(Iterable<Object?> other) => value.containsAll(other);

  @override
  Set<E> difference(Set<Object?> other) => value.difference(other);

  @override
  Set<E> intersection(Set<Object?> other) => value.intersection(other);

  @override
  E? lookup(Object? object) => value.lookup(object);

  @override
  bool remove(Object? value) => _mutate((current) => current.remove(value));

  @override
  void removeAll(Iterable<Object?> elements) =>
      _mutate((current) => current.removeAll(elements));

  @override
  void removeWhere(bool Function(E element) test) =>
      _mutate((current) => current.removeWhere(test));

  @override
  void retainAll(Iterable<Object?> elements) =>
      _mutate((current) => current.retainAll(elements));

  @override
  void retainWhere(bool Function(E element) test) =>
      _mutate((current) => current.retainWhere(test));

  @override
  Set<E> union(Set<E> other) => value.union(other);

  @override
  void clear() => _mutate((current) => current.clear());

  @override
  Set<E> toSet() => value.toSet();

  @override
  Iterable<E> followedBy(Iterable<E> other) => value.followedBy(other);

  @override
  Iterable<T> map<T>(T Function(E e) toElement) => value.map(toElement);

  @override
  Iterable<E> where(bool Function(E element) test) => value.where(test);

  @override
  Iterable<T> whereType<T>() => value.whereType<T>();

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) =>
      value.expand(toElements);

  @override
  void forEach(void Function(E element) action) =>
      mutate((set) => set.forEach(action));

  @override
  E reduce(E Function(E value, E element) combine) =>
      mutate((set) => set.reduce(combine));

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) =>
      mutate((set) => set.fold<T>(initialValue, combine));

  @override
  bool every(bool Function(E element) test) => mutate((set) => set.every(test));

  @override
  String join([String separator = '']) => value.join(separator);

  @override
  bool any(bool Function(E element) test) => mutate((set) => set.any(test));

  @override
  List<E> toList({bool growable = true}) => value.toList(growable: growable);

  @override
  int get length => value.length;

  @override
  bool get isEmpty => value.isEmpty;

  @override
  bool get isNotEmpty => value.isNotEmpty;

  @override
  Iterable<E> take(int count) => value.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E element) test) => value.takeWhile(test);

  @override
  Iterable<E> skip(int count) => value.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E element) test) => value.skipWhile(test);

  @override
  E get first => value.first;

  @override
  E get last => value.last;

  @override
  E get single => value.single;

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) =>
      mutate((set) => set.firstWhere(test, orElse: orElse));

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) =>
      mutate((set) => set.lastWhere(test, orElse: orElse));

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) =>
      mutate((set) => set.singleWhere(test, orElse: orElse));

  @override
  E elementAt(int index) => value.elementAt(index);
}
