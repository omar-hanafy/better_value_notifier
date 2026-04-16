import 'package:flutter/material.dart';

/// Stores the app's current [ThemeMode] in a listenable object.
class ThemeModeNotifier extends ValueNotifier<ThemeMode> {
  /// Creates a notifier with the initial theme [value].
  ThemeModeNotifier(super.value);

  @override
  void notifyListeners() {
    try {
      super.notifyListeners();
    } catch (_) {}
  }

  /// Re-emits the current [ThemeMode] without changing it.
  void refresh() => notifyListeners();

  /// similar to value setter but this one force trigger the notifyListeners()
  /// event if newValue == value.
  void update(ThemeMode newValue) {
    final shouldForceNotify = value == newValue;
    value = newValue;
    if (shouldForceNotify) {
      notifyListeners();
    }
  }
}

/// Convenience getters and setters for a [ValueNotifier] of [ThemeMode].
extension ThemeModeNotifierEx on ValueNotifier<ThemeMode> {
  /// Whether the current theme mode forces dark mode.
  bool get isDark => value == ThemeMode.dark;

  /// Whether the current theme mode forces light mode.
  bool get isLight => value == ThemeMode.light;

  /// Whether the current theme mode follows the platform brightness.
  bool get isSystem => value == ThemeMode.system;

  /// Switches the notifier to [ThemeMode.dark].
  void setDark() => value = ThemeMode.dark;

  /// Switches the notifier to [ThemeMode.light].
  void setLight() => value = ThemeMode.light;

  /// Switches the notifier to [ThemeMode.system].
  void setSystem() => value = ThemeMode.system;
}

/// Stores the current [Brightness] in a listenable object.
class BrightnessNotifier extends ValueNotifier<Brightness> {
  /// Creates a notifier with the initial brightness [value].
  BrightnessNotifier(super.value);

  @override
  void notifyListeners() {
    try {
      super.notifyListeners();
    } catch (_) {}
  }

  /// Re-emits the current [Brightness] without changing it.
  void refresh() => notifyListeners();

  /// similar to value setter but this one force trigger the notifyListeners()
  /// event if newValue == value.
  void update(Brightness newValue) {
    final shouldForceNotify = value == newValue;
    value = newValue;
    if (shouldForceNotify) {
      notifyListeners();
    }
  }
}

/// Convenience getters and setters for a [ValueNotifier] of [Brightness].
extension BrightnessNotifierEx on ValueNotifier<Brightness> {
  /// Whether the current brightness is dark.
  bool get isDark => value == Brightness.dark;

  /// Whether the current brightness is light.
  bool get isLight => value == Brightness.light;

  /// Switches the notifier to [Brightness.dark].
  void setDark() => value = Brightness.dark;

  /// Deprecated typo kept for backward compatibility.
  @Deprecated('Use setDark() instead.')
  void setDart() => setDark();

  /// Switches the notifier to [Brightness.light].
  void setLight() => value = Brightness.light;
}
