import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class NotificationProbe {
  NotificationProbe(this._listenable, {this.snapshot}) {
    _listener = () {
      count++;
      if (snapshot != null) {
        snapshots.add(snapshot!());
      }
    };
    _listenable.addListener(_listener);
  }

  final Listenable _listenable;
  final Object? Function()? snapshot;
  late final VoidCallback _listener;

  int count = 0;
  final List<Object?> snapshots = <Object?>[];

  void dispose() => _listenable.removeListener(_listener);
}

T withProbe<T>(
  Listenable listenable,
  T Function(NotificationProbe probe) body, {
  Object? Function()? snapshot,
}) {
  final probe = NotificationProbe(listenable, snapshot: snapshot);
  try {
    return body(probe);
  } finally {
    probe.dispose();
  }
}

void expectNoNotification(NotificationProbe probe) {
  expect(probe.count, 0);
}

void expectSingleNotification(NotificationProbe probe) {
  expect(probe.count, 1);
}
