import 'package:adaptive_stat_card/adaptive_stat_card.dart';
import 'package:flutter/material.dart';

void main() => runApp(const GalleryApp());

/// The interactive gallery that doubles as the package screenshot source.
class GalleryApp extends StatefulWidget {
  /// Creates the gallery app.
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'adaptive_stat_card gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF3B6EF3),
        brightness: _darkMode ? Brightness.dark : Brightness.light,
      ),
      home: GalleryPage(
        darkMode: _darkMode,
        onDarkModeChanged: (bool value) => setState(() => _darkMode = value),
      ),
    );
  }
}

/// The single screen of the gallery.
class GalleryPage extends StatefulWidget {
  /// Creates the gallery screen.
  const GalleryPage({
    required this.darkMode,
    required this.onDarkModeChanged,
    super.key,
  });

  /// Whether the app is currently in dark mode.
  final bool darkMode;

  /// Called when the dark mode switch is toggled.
  final ValueChanged<bool> onDarkModeChanged;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final TextEditingController _valueController = TextEditingController(
    text: '1,248',
  );
  final TextEditingController _labelController = TextEditingController(
    text: 'Total Deliveries Completed This Month',
  );

  double _cardWidth = 220;
  double _textScale = 1;
  StatCardOverflow _overflow = StatCardOverflow.shrinkThenWrap;
  StatCardLayout _layout = StatCardLayout.iconLeading;
  bool _rtl = false;
  bool _isLoading = false;
  bool _showTrend = true;
  bool _showIcon = true;

  @override
  void initState() {
    super.initState();
    _valueController.addListener(_refresh);
    _labelController.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _valueController
      ..removeListener(_refresh)
      ..dispose();
    _labelController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('adaptive_stat_card'),
        actions: <Widget>[
          Switch(value: widget.darkMode, onChanged: widget.onDarkModeChanged),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _sectionTitle(context, 'Live preview'),
            _preview(),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Controls'),
            _controls(),
            const SizedBox(height: 32),
            _sectionTitle(context, 'StatCardGrid'),
            const SizedBox(height: 8),
            const _DashboardGrid(),
            const SizedBox(height: 32),
            _sectionTitle(context, 'Numeric values'),
            const _NumberSection(),
            const SizedBox(height: 32),
            _sectionTitle(context, 'StatCardSyncScope'),
            const _SyncSection(),
            const SizedBox(height: 32),
            _sectionTitle(context, 'Sparklines and card states'),
            const _StatesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _preview() {
    final Widget card = StatCard(
      value: _valueController.text,
      label: _labelController.text,
      unit: 'pkg',
      icon: _showIcon ? const Icon(Icons.local_shipping_outlined) : null,
      trend: _showTrend ? const StatTrend.up('+12.4%') : null,
      overflow: _overflow,
      layout: _layout,
      isLoading: _isLoading,
      onTap: () {},
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Center(
        child: Directionality(
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          child: MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(_textScale)),
            child: SizedBox(width: _cardWidth, child: card),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _slider(
          label: 'Card width: ${_cardWidth.round()} px',
          value: _cardWidth,
          min: 80,
          max: 400,
          onChanged: (double v) => setState(() => _cardWidth = v),
        ),
        _slider(
          label: 'Text scale: ${_textScale.toStringAsFixed(2)}x',
          value: _textScale,
          min: 0.8,
          max: 2,
          onChanged: (double v) => setState(() => _textScale = v),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: <Widget>[
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<StatCardOverflow>(
                initialValue: _overflow,
                decoration: const InputDecoration(
                  labelText: 'Overflow strategy',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<StatCardOverflow>>[
                  for (final StatCardOverflow value in StatCardOverflow.values)
                    DropdownMenuItem<StatCardOverflow>(
                      value: value,
                      child: Text(value.name),
                    ),
                ],
                onChanged: (StatCardOverflow? v) =>
                    setState(() => _overflow = v ?? _overflow),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<StatCardLayout>(
                initialValue: _layout,
                decoration: const InputDecoration(
                  labelText: 'Layout',
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<StatCardLayout>>[
                  for (final StatCardLayout value in StatCardLayout.values)
                    DropdownMenuItem<StatCardLayout>(
                      value: value,
                      child: Text(value.name),
                    ),
                ],
                onChanged: (StatCardLayout? v) =>
                    setState(() => _layout = v ?? _layout),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _toggle('RTL', _rtl, (bool v) => setState(() => _rtl = v)),
            _toggle(
              'Loading',
              _isLoading,
              (bool v) => setState(() => _isLoading = v),
            ),
            _toggle(
              'Trend',
              _showTrend,
              (bool v) => setState(() => _showTrend = v),
            ),
            _toggle(
              'Icon',
              _showIcon,
              (bool v) => setState(() => _showIcon = v),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _valueController,
          decoration: const InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _labelController,
          decoration: const InputDecoration(
            labelText: 'Label',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
    );
  }
}

/// A realistic dashboard built with [StatCardGrid].
class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid();

  @override
  Widget build(BuildContext context) {
    return const StatCardGrid(
      minCardWidth: 180,
      children: <StatCard>[
        StatCard(
          value: '1,248',
          label: 'Deliveries this month',
          unit: 'pkg',
          icon: Icon(Icons.local_shipping_outlined),
          trend: StatTrend.up('+12.4%'),
        ),
        StatCard(
          value: '4,28,930',
          label: 'Revenue',
          unit: 'INR',
          icon: Icon(Icons.currency_rupee),
          trend: StatTrend.up('+3.1%'),
        ),
        StatCard(
          value: '312',
          label: 'Active users',
          icon: Icon(Icons.people_outline),
          trend: StatTrend.flat('0.0%'),
        ),
        StatCard(
          value: '18',
          label: 'Pending pickups',
          icon: Icon(Icons.inventory_2_outlined),
          trend: StatTrend.down('-8.7%'),
        ),
        StatCard(
          value: '27',
          label: 'Average delivery time',
          unit: 'min',
          icon: Icon(Icons.timer_outlined),
          trend: StatTrend.down('-2.4%'),
        ),
        StatCard(
          value: '4.8',
          label: 'Satisfaction score',
          unit: '/5',
          icon: Icon(Icons.sentiment_satisfied_alt_outlined),
          trend: StatTrend.up('+0.2'),
        ),
      ],
    );
  }
}

/// Demonstrates [StatCard.number]: the same figure at shrinking widths, plus a
/// value that counts to a new reading.
class _NumberSection extends StatefulWidget {
  const _NumberSection();

  @override
  State<_NumberSection> createState() => _NumberSectionState();
}

class _NumberSectionState extends State<_NumberSection> {
  static const List<num> _readings = <num>[1250000, 87423, 1248930551, 4980];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'The same number, degraded to fit before the font is touched.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            for (final double width in <double>[220, 140, 116, 100])
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('${width.round()} px'),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: width,
                    child: StatCard.number(
                      1250000,
                      label: 'Deliveries this month',
                      icon: const Icon(Icons.local_shipping_outlined),
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('animateValue counts to the new reading.'),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            SizedBox(
              width: 220,
              child: StatCard.number(
                _readings[_index],
                label: 'Deliveries this month',
                animateValue: true,
                icon: const Icon(Icons.local_shipping_outlined),
                trend: const StatTrend.up('+12.4%'),
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.tonal(
              onPressed: () =>
                  setState(() => _index = (_index + 1) % _readings.length),
              child: const Text('New reading'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Demonstrates [StatCardSyncScope] as the before/after it only makes sense as.
class _SyncSection extends StatefulWidget {
  const _SyncSection();

  @override
  State<_SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends State<_SyncSection> {
  bool _synced = true;

  Widget _row() {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        SizedBox(
          width: 150,
          child: StatCard(value: '1,248,930,551', label: 'Deliveries'),
        ),
        SizedBox(
          width: 150,
          child: StatCard(value: '42', label: 'Open tickets'),
        ),
        SizedBox(
          width: 150,
          child: StatCard(value: '4.8', label: 'Satisfaction'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Every card below is 150 px wide. Only the long value has to shrink '
          '— a scope brings the others down with it.',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Wrap the row in a StatCardSyncScope'),
          value: _synced,
          onChanged: (bool v) => setState(() => _synced = v),
        ),
        const SizedBox(height: 8),
        StatCardSyncScope(enabled: _synced, child: _row()),
      ],
    );
  }
}

/// Demonstrates sparklines alongside the loading, error, empty and selected
/// states.
class _StatesSection extends StatefulWidget {
  const _StatesSection();

  @override
  State<_StatesSection> createState() => _StatesSectionState();
}

class _StatesSectionState extends State<_StatesSection> {
  static const List<double> _series = <double>[
    3,
    5,
    4,
    9,
    7,
    12,
    11,
    15,
    13,
    18,
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        SizedBox(
          width: 200,
          child: StatCard(
            value: '4.2',
            label: 'Revenue',
            unit: 'Cr',
            sparkline: _series,
            icon: const Icon(Icons.currency_rupee),
            trend: const StatTrend.up('+3.1%'),
            selected: _selected == 0,
            onTap: () => setState(() => _selected = 0),
          ),
        ),
        SizedBox(
          width: 200,
          child: StatCard(
            value: '1,248',
            label: 'Deliveries',
            sparkline: _series,
            icon: const Icon(Icons.local_shipping_outlined),
            selected: _selected == 1,
            onTap: () => setState(() => _selected = 1),
            onLongPress: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Long pressed Deliveries')),
            ),
          ),
        ),
        const SizedBox(
          width: 200,
          child: StatCard(
            value: '',
            label: 'Queue depth',
            icon: Icon(Icons.error_outline),
            error: 'The metrics service did not respond within 30 seconds',
          ),
        ),
        const SizedBox(
          width: 200,
          child: StatCard(
            value: '',
            label: 'Refunds',
            icon: Icon(Icons.receipt_long_outlined),
          ),
        ),
        const SizedBox(width: 200, child: StatCard.loading()),
      ],
    );
  }
}
