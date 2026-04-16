import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

/// A [ValueNotifier] kept in sync with a [Stream].
///
/// Dispose it when you are done so the stream subscription can be cancelled.
class StreamValueNotifier<T> extends ValueNotifier<T> {
  /// Creates a notifier that mirrors the latest event from [stream].
  ///
  /// The notifier starts with [initialValue], updates on every data event, and
  /// calls [onDone] with the last received value when the stream closes.
  StreamValueNotifier(
    Stream<T> stream,
    T initialValue, {
    this.onDone,
    void Function(Object, StackTrace)? onError,
  }) : super(initialValue) {
    _subscription = stream.listen(
      _handleData,
      onError: onError ?? _defaultOnError,
      onDone: _handleDone,
    );
  }

  late final StreamSubscription<T> _subscription;

  /// Called when the source stream closes, with the notifier's latest value.
  final void Function(T value)? onDone;
  bool _isDisposed = false;

  void _handleData(T nextValue) {
    if (_isDisposed) {
      return;
    }
    value = nextValue;
  }

  void _handleDone() {
    if (_isDisposed) {
      return;
    }
    onDone?.call(value);
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_subscription.cancel());
    super.dispose();
  }

  static void _defaultOnError(Object error, StackTrace stackTrace) => log(
    'Error while syncing stream to StreamValueNotifier',
    error: error,
    stackTrace: stackTrace,
  );
}

/// Extension on `Stream<T>` to convert any stream into a `ValueNotifier<T>`.
///
/// This extension provides a convenient way to bridge the reactive world of streams
/// with the `ValueNotifier` pattern used for state management in Flutter applications. By converting
/// a stream into a `ValueNotifier`, you can easily integrate asynchronous stream data into your
/// Flutter widgets with the reactive and efficient update mechanism that `ValueNotifier` provides.
extension FHUStreamToValueNotifier<T> on Stream<T> {
  /// Converts the current stream into a `ValueListenable<T>` which is effectively a `ValueNotifier<T>`.
  ///
  /// The conversion process involves listening to the stream and updating the `ValueNotifier`'s value
  /// each time the stream emits a new item. This allows Flutter widgets to reactively rebuild whenever
  /// the `ValueNotifier`'s value changes, based on the latest data emitted by the stream.
  ///
  /// Parameters:
  /// - `initialValue`: The initial value to be used for the `ValueNotifier` before any data is received from the stream.
  /// - `onDone`: An optional callback that gets called when the stream is done. The last value received
  ///   from the stream is passed to this callback.
  /// - `onError`: An optional error handler for stream errors. If not provided, a default error handler
  ///   that logs the error is used.
  ///
  /// Returns a [StreamValueNotifier] that updates its value from the stream.
  ///
  /// Dispose the returned notifier to cancel the underlying subscription.
  StreamValueNotifier<T> toValueNotifier(
    T initialValue, {
    void Function(T)? onDone,
    void Function(Object, StackTrace)? onError,
  }) => StreamValueNotifier<T>(
    this,
    initialValue,
    onDone: onDone,
    onError: onError,
  );
}
