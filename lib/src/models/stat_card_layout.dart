/// Describes where the icon of a [StatCard] is placed relative to its value
/// and label.
///
/// ```dart
/// const StatCard(
///   value: '98%',
///   label: 'Satisfaction',
///   icon: Icon(Icons.thumb_up),
///   layout: StatCardLayout.iconAbove,
/// );
/// ```
enum StatCardLayout {
  /// The icon sits before the value/label column, following the ambient
  /// [Directionality].
  iconLeading,

  /// The icon sits after the value/label column, following the ambient
  /// [Directionality].
  iconTrailing,

  /// The icon sits above the value, which sits above the label.
  ///
  /// This is usually the best choice for narrow grid cells.
  iconAbove,

  /// The icon is not rendered at all, even when one is supplied.
  noIcon,
}
