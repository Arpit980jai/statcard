import 'package:flutter/widgets.dart';

import 'widgets/sync_registry.dart';

/// Makes every [StatCard] below it agree on one font size.
///
/// Each card normally fits its own text independently, which is right for a
/// card standing on its own and wrong for a row of cards: `1,248,930` shrinks
/// to fit while `42` stays huge, and the row looks broken. Inside a sync scope
/// the cards converge on the smallest size any of them needed, so the row reads
/// as one object.
///
/// Values are synchronised with values and labels with labels; the two never
/// influence each other, because they start from different base sizes.
///
/// ```dart
/// StatCardSyncScope(
///   child: Row(
///     children: const <Widget>[
///       Expanded(child: StatCard(value: '1,248,930', label: 'Deliveries')),
///       Expanded(child: StatCard(value: '42', label: 'Open tickets')),
///       Expanded(child: StatCard(value: '4.8', label: 'Satisfaction')),
///     ],
///   ),
/// );
/// ```
///
/// ## How it settles
///
/// The scope runs two passes. On the first frame every card fits its text on
/// its own and reports the size it chose. After that frame the scope takes the
/// minimum per role and, if it changed, rebuilds its descendants once with that
/// size. Cards always report the size they *would* have picked unsynchronised,
/// never the size they were told to paint, so the reported set does not depend
/// on the broadcast and the minimum reaches a fixed point immediately: there is
/// no feedback loop to oscillate.
///
/// Cards may be added and removed freely. A card registers when it is mounted
/// and unregisters when it is disposed, and the minimum is recomputed both
/// times — so removing the card that was forcing everyone down lets the rest
/// grow back on the next frame.
///
/// Because the agreed size lands one frame after the first layout, a scope
/// costs one extra frame when its contents change. Nothing flickers in
/// between: the first frame shows correctly fitted, individually sized cards.
///
/// See also:
///
///  * [StatCardGrid], which is the usual thing to put inside a scope.
class StatCardSyncScope extends StatefulWidget {
  /// Creates a scope that synchronises the text size of its descendant cards.
  const StatCardSyncScope({
    required this.child,
    this.enabled = true,
    super.key,
  });

  /// The subtree whose stat cards should converge on one size.
  final Widget child;

  /// Whether synchronisation is active.
  ///
  /// Setting this to false is exactly equivalent to removing the scope: every
  /// card falls back to fitting its own text. It is here so that a caller can
  /// switch the behaviour off — for one breakpoint, say — without restructuring
  /// the widget tree.
  ///
  /// ```dart
  /// StatCardSyncScope(
  ///   enabled: MediaQuery.sizeOf(context).width > 600,
  ///   child: StatCardGrid(children: cards),
  /// );
  /// ```
  final bool enabled;

  @override
  State<StatCardSyncScope> createState() => _StatCardSyncScopeState();
}

class _StatCardSyncScopeState extends State<StatCardSyncScope> {
  final StatCardSyncRegistry _registry = StatCardSyncRegistry();

  @override
  void dispose() {
    _registry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    return StatCardSyncMarker(notifier: _registry, child: widget.child);
  }
}
