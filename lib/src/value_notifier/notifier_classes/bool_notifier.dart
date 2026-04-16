import 'package:flutter/cupertino.dart';

/// allows to quickly create a ValueNotifier of type bool.
class BoolNotifier extends ValueNotifier<bool> {
  /// Creates a notifier that stores a boolean value.
  BoolNotifier(super.initial);

  @override
  void notifyListeners() {
    try {
      super.notifyListeners();
    } catch (_) {}
  }

  /// Re-emits the current value without changing it.
  void refresh() => notifyListeners();

  /// similar to value setter but this one force trigger the notifyListeners()
  /// event if newValue == value.
  void update(bool newValue) {
    final shouldForceNotify = value == newValue;
    value = newValue;
    if (shouldForceNotify) {
      notifyListeners();
    }
  }
}

/// BoolValueNotifierExtension
///
/// Extension on `ValueNotifier<bool>` providing additional boolean-specific functionalities.
/// This extension simplifies toggling and other boolean operations directly on
/// the [ValueNotifier] without the need to perform actions in the value itself.
///
/// Example:
/// ```dart
/// final boolValueNotifier = true.notifier;
/// boolValueNotifier.toggle(); // Toggles the boolean value.
/// ```
extension FHUBoolValueNotifierExtension on ValueNotifier<bool> {
  /// toggle the value of the [ValueNotifier]
  void toggle() => value = !value;

  /// toggle the value of the [ValueNotifier] and run the provided function.
  void toggleWithCallback(VoidCallback callback) {
    toggle();
    callback();
  }

  /// toggle after a specific time.
  Future<void> delayedToggle(Duration delay) async {
    await Future<void>.delayed(delay);
    toggle();
  }

  /// toggle the value of the ValueNotifier based on a condition.
  void conditionalToggle({required bool condition}) {
    if (condition) toggle();
  }

  /// make the value of the [ValueNotifier] true
  void setTrue() => value = true;

  /// make the value of the [ValueNotifier] false
  void setFalse() => value = false;

  /// The logical conjunction ("and") of this and [other].
  ///
  /// Returns `true` if both this and [other] are `true`, and `false` otherwise.
  bool operator &(bool other) => value & other;

  /// The logical disjunction ("inclusive or") of this and [other].
  ///
  /// Returns `true` if either this or [other] is `true`, and `false` otherwise.)
  bool operator |(bool other) => value | other;

  /// The logical exclusive disjunction ("exclusive or") of this and [other].
  ///
  /// Returns whether this and [other] are neither both `true` nor both `false`.
  bool operator ^(bool other) => value ^ other;
}
