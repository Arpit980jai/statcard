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
