## 1.0.0-dev.1

### Added

- Initial prerelease of `better_value_notifier`.
- Typed notifier wrappers for primitive values, collections, and common Flutter types.
- Contract-driven tests covering deep mutation, eager callback mutation boundaries, reactive extensions, and widget rebuild behavior.

### Changed

- Collection notifiers now own their internal collection state instead of aliasing the source collection.
- `ListNotifier`, `MapNotifier`, and `SetNotifier` expose `mutate(...)` as an explicit notification boundary for nested and in-place mutation.
- Eager callback-based collection methods now refresh after execution so inner mutations done inside those callbacks are observable.
