import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The independently synchronised text roles inside a sync scope.
///
/// Values are only ever compared with other values and labels with other
/// labels: a card's value and its label start from different base font sizes,
/// so collapsing both onto one number would make every label enormous or every
/// value tiny.
///
/// This enum is internal to the package and is not exported.
enum SyncRole {
  /// The headline number of a card.
  value,

  /// The descriptive text under the value.
  label,
}

/// Sizes below this are treated as identical, so that floating point noise
/// coming out of the binary search can never keep a scope rebuilding.
const double _kEpsilon = 0.05;

/// Collects the naturally fitted font size of every participating text and
/// broadcasts the smallest one per [SyncRole].
///
/// The contract that keeps this from looping is that participants always
/// report the size they would have chosen *on their own*, never the size they
/// were told to paint. Reports are therefore independent of the broadcast, so
/// the minimum reaches a fixed point after a single extra frame.
///
/// This class is internal to the package and is not exported.
class StatCardSyncRegistry extends ChangeNotifier {
  final Map<SyncRole, Map<Object, double>> _reports =
      <SyncRole, Map<Object, double>>{
        for (final SyncRole role in SyncRole.values) role: <Object, double>{},
      };

  final Map<SyncRole, double?> _published = <SyncRole, double?>{};

  bool _flushScheduled = false;
  bool _disposed = false;

  /// How many times the registry has broadcast a new minimum.
  ///
  /// Tests assert that this settles instead of climbing frame after frame.
  @visibleForTesting
  int debugBroadcastCount = 0;

  /// The agreed font size for [role], or null while nothing has been reported.
  double? sizeFor(SyncRole role) => _published[role];

  /// Records the size [token] would pick if it were on its own.
  void report(SyncRole role, Object token, double naturalSize) {
    if (_disposed) {
      return;
    }
    final Map<Object, double> reports = _reports[role]!;
    final double? previous = reports[token];
    if (previous != null && (previous - naturalSize).abs() < _kEpsilon) {
      return;
    }
    reports[token] = naturalSize;
    _scheduleFlush();
  }

  /// Forgets [token], which happens when a card leaves the tree.
  void remove(Object token) {
    if (_disposed) {
      return;
    }
    var removed = false;
    for (final SyncRole role in SyncRole.values) {
      removed |= _reports[role]!.remove(token) != null;
    }
    if (removed) {
      _scheduleFlush();
    }
  }

  /// Reports arrive during layout, so the minimum is recomputed after the
  /// frame rather than in the middle of it.
  void _scheduleFlush() {
    if (_flushScheduled) {
      return;
    }
    _flushScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _flushScheduled = false;
      _flush();
    });
  }

  void _flush() {
    if (_disposed) {
      return;
    }
    var changed = false;
    for (final SyncRole role in SyncRole.values) {
      final Iterable<double> sizes = _reports[role]!.values;
      final double? minimum = sizes.isEmpty
          ? null
          : sizes.reduce((double a, double b) => math.min(a, b));
      final double? previous = _published[role];
      final bool differs = previous == null || minimum == null
          ? previous != minimum
          : (previous - minimum).abs() >= _kEpsilon;
      if (differs) {
        _published[role] = minimum;
        changed = true;
      }
    }
    if (changed) {
      debugBroadcastCount++;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Hands the nearest [StatCardSyncRegistry] to descendant texts and rebuilds
/// them when it broadcasts a new minimum.
///
/// This class is internal to the package and is not exported.
class StatCardSyncMarker extends InheritedNotifier<StatCardSyncRegistry> {
  /// Publishes [registry] to the subtree.
  const StatCardSyncMarker({
    required StatCardSyncRegistry super.notifier,
    required super.child,
    super.key,
  });

  /// The registry of the nearest enclosing scope, or null when there is none.
  static StatCardSyncRegistry? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<StatCardSyncMarker>()
        ?.notifier;
  }
}
