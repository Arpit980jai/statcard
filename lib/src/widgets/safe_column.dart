import 'package:flutter/widgets.dart';

/// A [Column] that cannot report a layout overflow.
///
/// When the incoming height is unbounded, which is the common case for a card
/// in a wrap or a scroll view, this behaves exactly like a plain [Column] with
/// `MainAxisSize.min`, so every child gets its natural height.
///
/// When the height *is* bounded, for example inside a grid cell with a fixed
/// aspect ratio, every child is wrapped in a loose [Flexible]. Children then
/// receive a bounded height instead of an unbounded one, which lets the text
/// engine drop a line or shrink a font rather than letting the column paint
/// past its edge and log `A RenderFlex overflowed`.
///
/// Wrapping in [Flexible] unconditionally is not an option: a flexible child
/// inside an unbounded column is a framework assertion.
///
/// This class is internal to the package and is not exported.
class SafeColumn extends StatelessWidget {
  /// Creates a column that adapts to whether its height is bounded.
  const SafeColumn({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisAlignment = MainAxisAlignment.start,
    super.key,
  });

  /// The children, in order.
  final List<Widget> children;

  /// How the children are aligned horizontally.
  final CrossAxisAlignment crossAxisAlignment;

  /// How the children are distributed vertically.
  final MainAxisAlignment mainAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bounded = constraints.maxHeight.isFinite;
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: <Widget>[
            for (final Widget child in children)
              if (bounded) Flexible(child: child) else child,
          ],
        );
      },
    );
  }
}
