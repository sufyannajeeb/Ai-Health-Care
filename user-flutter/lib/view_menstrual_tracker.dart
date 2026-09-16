import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Theme Constants (Red → Violet gradient theme) ────────────────────────────
const _kPink       = Color(0xFF9C1FE9);   // primary violet
const _kPinkLight  = Color(0xFFE0354B);   // vivid red (gradient start)
const _kPinkPale   = Color(0xFFF5F0FF);   // pale violet tint
const _kPinkBorder = Color(0xFFCFAAEE);   // soft violet border
const _kPinkDeep   = Color(0xFFFFF9F9);   // deep violet (gradient end)
const _kBg         = Color(0xFFFFFFFF);   // near-white violet bg
const _kTextDark   = Color(0xFF1E0A2D);   // very dark violet-black
const _kTextMid    = Color(0xFF6B3FA0);   // medium violet
const _kTextLight  = Color(0xFFB39DCC);   // muted violet

// Gradient helpers used throughout
const _kGradMain   = [Color(0xFFE0354B), Color(0xFFB8186E), Color(0xFF6A0DAD)];
const _kGradShort  = [Color(0xFFE0354B), Color(0xFF9C1FE9)];

// ─── Storage Keys ─────────────────────────────────────────────────────────────
const _kKeyLastPeriodDate   = 'last_period_date';
const _kKeyCycleLength      = 'cycle_length';
const _kKeyPeriodLength     = 'period_length';
const _kKeyPeriodHistory    = 'period_history';
const _kKeySelectedSymptoms = 'selected_symptoms';

// ─── Prediction Model ─────────────────────────────────────────────────────────
class CyclePrediction {
  final DateTime predictedStart;
  final DateTime predictedEnd;
  final int cycleUsed;
  final String source;      // "smart" | "manual"
  final double? confidence; // 0–1

  CyclePrediction({
    required this.predictedStart,
    required this.predictedEnd,
    required this.cycleUsed,
    required this.source,
    this.confidence,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
class MenstrualTrackerPage extends StatefulWidget {
  const MenstrualTrackerPage({super.key});

  @override
  State<MenstrualTrackerPage> createState() => _MenstrualTrackerPageState();
}

class _MenstrualTrackerPageState extends State<MenstrualTrackerPage> {
  DateTime?      _lastPeriodDate;
  int            _cycleLength  = 28;
  int            _periodLength = 5;
  List<String>   _selectedSymptoms = [];
  List<DateTime> _periodHistory    = [];
  bool           _isLoading = true;

  final List<String> symptoms = [
    'Cramps', 'Mood Swings', 'Headache', 'Fatigue',
    'Acne', 'Back Pain', 'Bloating', 'Food Cravings',
  ];

  final Map<String, IconData> symptomIcons = {
    'Cramps':        Icons.waves,
    'Mood Swings':   Icons.mood,
    'Headache':      Icons.psychology,
    'Fatigue':       Icons.battery_2_bar,
    'Acne':          Icons.face,
    'Back Pain':     Icons.accessibility_new,
    'Bloating':      Icons.bubble_chart,
    'Food Cravings': Icons.restaurant,
  };

  final Map<String, String> symptomTips = {
    'Cramps':        'Try light exercises or a warm compress to relieve cramps.',
    'Mood Swings':   'Stay hydrated and try meditation to balance your mood.',
    'Headache':      'Rest in a quiet, dark room and avoid screens for a while.',
    'Fatigue':       'Increase your iron intake and ensure enough sleep.',
    'Acne':          'Keep your skin clean and avoid oily foods.',
    'Back Pain':     'Gentle yoga stretches can help reduce back pain.',
    'Bloating':      'Reduce salty food and drink more water.',
    'Food Cravings': 'Opt for healthy alternatives like fruits or nuts.',
  };

  // ─── Lifecycle ───────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── Persistence ─────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final prefs          = await SharedPreferences.getInstance();
    final historyStrings = prefs.getStringList(_kKeyPeriodHistory) ?? [];
    setState(() {
      final lastStr     = prefs.getString(_kKeyLastPeriodDate);
      _lastPeriodDate   = lastStr != null ? DateTime.tryParse(lastStr) : null;
      _cycleLength      = prefs.getInt(_kKeyCycleLength)  ?? 28;
      _periodLength     = prefs.getInt(_kKeyPeriodLength) ?? 5;
      _periodHistory    = historyStrings
          .map((s) => DateTime.tryParse(s))
          .whereType<DateTime>()
          .toList()
        ..sort((a, b) => b.compareTo(a));
      _selectedSymptoms = prefs.getStringList(_kKeySelectedSymptoms) ?? [];
      _isLoading        = false;
    });
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lastPeriodDate != null) {
      await prefs.setString(_kKeyLastPeriodDate, _lastPeriodDate!.toIso8601String());
    } else {
      await prefs.remove(_kKeyLastPeriodDate);
    }
    await prefs.setInt(_kKeyCycleLength,  _cycleLength);
    await prefs.setInt(_kKeyPeriodLength, _periodLength);
    await prefs.setStringList(
      _kKeyPeriodHistory,
      _periodHistory.map((d) => d.toIso8601String()).toList(),
    );
    await prefs.setStringList(_kKeySelectedSymptoms, _selectedSymptoms);
  }

  // ─── Smart Prediction Engine ──────────────────────────────────────────────────
  List<DateTime> get _allDates {
    final all  = <DateTime>[?_lastPeriodDate, ..._periodHistory];
    final seen = <String>{};
    return all
        .where((d) => seen.add(d.toIso8601String().substring(0, 10)))
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  int? get _smartCycleLength {
    final dates = _allDates;
    if (dates.length < 2) return null;
    final gaps = <int>[];
    for (int i = 0; i < dates.length - 1; i++) {
      final gap = dates[i].difference(dates[i + 1]).inDays;
      if (gap >= 15 && gap <= 60) gaps.add(gap);
    }
    if (gaps.isEmpty) return null;
    double weightedSum = 0, totalWeight = 0;
    for (int i = 0; i < gaps.length; i++) {
      final w = (gaps.length - i).toDouble();
      weightedSum += gaps[i] * w;
      totalWeight += w;
    }
    return (weightedSum / totalWeight).round();
  }

  double? get _predictionConfidence {
    final dates = _allDates;
    if (dates.length < 2) return null;
    final gaps = <int>[];
    for (int i = 0; i < dates.length - 1; i++) {
      final gap = dates[i].difference(dates[i + 1]).inDays;
      if (gap >= 15 && gap <= 60) gaps.add(gap);
    }
    if (gaps.length < 2) return 0.5;
    final mean     = gaps.reduce((a, b) => a + b) / gaps.length;
    final variance = gaps.map((g) => (g - mean) * (g - mean)).reduce((a, b) => a + b) / gaps.length;
    final stdDev   = variance <= 0 ? 0.0 : _sqrt(variance);
    return (1.0 - (stdDev / 7.0)).clamp(0.2, 1.0);
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double z = x;
    for (int i = 0; i < 20; i++) { z = (z + x / z) / 2; }
    return z;
  }

  CyclePrediction? get prediction {
    final dates = _allDates;
    if (dates.isEmpty) return null;
    final smart         = _smartCycleLength;
    final effectiveCycle = smart ?? _cycleLength;
    final start = dates.first.add(Duration(days: effectiveCycle));
    final end   = start.add(Duration(days: _periodLength - 1));
    return CyclePrediction(
      predictedStart: start,
      predictedEnd:   end,
      cycleUsed:      effectiveCycle,
      source:         smart != null ? 'smart' : 'manual',
      confidence:     _predictionConfidence,
    );
  }

  // ─── Status ───────────────────────────────────────────────────────────────────
  String get periodStatus {
    final p = prediction;
    if (p == null) return 'Log your first period to get started';
    final days = p.predictedStart.difference(DateTime.now()).inDays;
    if (days < 0)  return 'You may have missed logging your cycle';
    if (days == 0) return 'Your period might start today';
    if (days <= 5) return "Period coming soon · $days day${days == 1 ? '' : 's'}";
    return 'Currently in normal cycle phase';
  }

  Color get statusColor {
    final p = prediction;
    if (p == null) return _kTextLight;
    final days = p.predictedStart.difference(DateTime.now()).inDays;
    if (days < 0)  return Colors.orange.shade600;
    if (days == 0) return _kPink;
    if (days <= 5) return _kPinkDeep;
    return Colors.green.shade600;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────
  List<String> get tips => _selectedSymptoms
      .map((s) => symptomTips[s] ?? '')
      .where((t) => t.isNotEmpty)
      .toList();

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ─── Actions ──────────────────────────────────────────────────────────────────
  Future<void> _pickLastPeriodDate() async {
    final picked = await _datePicker(DateTime.now());
    if (picked == null) return;
    setState(() {
      if (_lastPeriodDate != null &&
          !_periodHistory.any((d) => _sameDay(d, _lastPeriodDate!))) {
        _periodHistory
          ..insert(0, _lastPeriodDate!)
          ..sort((a, b) => b.compareTo(a));
      }
      _lastPeriodDate = picked;
    });
    await _saveAll();
  }

  Future<void> _addToPeriodHistory() async {
    final picked = await _datePicker(DateTime.now(), firstDate: DateTime(2020));
    if (picked == null) return;
    if (_periodHistory.any((d) => _sameDay(d, picked)) ||
        (_lastPeriodDate != null && _sameDay(_lastPeriodDate!, picked))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('This date is already logged.'),
        backgroundColor: _kPinkDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    setState(() {
      _periodHistory
        ..insert(0, picked)
        ..sort((a, b) => b.compareTo(a));
    });
    await _saveAll();
  }

  Future<void> _removeHistory(DateTime date) async {
    setState(() => _periodHistory.removeWhere((d) => _sameDay(d, date)));
    await _saveAll();
  }

  Future<DateTime?> _datePicker(DateTime initial, {DateTime? firstDate}) =>
      showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: firstDate ?? DateTime(2022),
        lastDate: DateTime.now(),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPink, onPrimary: Colors.white,
              surface: Colors.white, onSurface: _kTextDark,
            ),
          ),
          child: child!,
        ),
      );

  // ══════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator(color: _kPink)),
      );
    }
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildCycleSettings(),
                const SizedBox(height: 16),
                _buildPredictionCard(),
                const SizedBox(height: 16),
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildSymptomsCard(),
                const SizedBox(height: 16),
                _buildHistoryCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ──────────────────────────────────────────────────────────────────
  Widget _buildAppBar() => SliverAppBar(
    expandedHeight: 160,
    pinned: true,
    backgroundColor: _kPinkDeep,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: _kGradMain,
          ),
        ),
        child: Stack(children: [
          _circle(right: -30, top: -30, size: 140, opacity: 0.08),
          _circle(right: 40,  top: 30,  size: 70,  opacity: 0.08),
          _circle(left: -20,  bottom: -20, size: 100, opacity: 0.06),
          Positioned(
            left: 20, right: 20, bottom: 20,
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🌸', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Menstrual Tracker',
                      style: TextStyle(color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  Text('Your cycle, your way',
                      style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.3)),
                ],
              ),
            ]),
          ),
        ]),
      ),
    ),
  );

  Widget _circle({double? left, double? right, double? top, double? bottom,
    required double size, required double opacity}) =>
      Positioned(
        left: left, right: right, top: top, bottom: bottom,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: opacity),
          ),
        ),
      );

  // ─── Shared UI ────────────────────────────────────────────────────────────────
  Widget _label(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: _kGradShort),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(
          color: _kTextDark, fontSize: 15,
          fontWeight: FontWeight.w700, letterSpacing: 0.2)),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(
        color: _kPink.withValues(alpha: 0.08),
        blurRadius: 20, offset: const Offset(0, 6),
      )],
    ),
    child: child,
  );

  // ─── Cycle Settings ───────────────────────────────────────────────────────────
  Widget _buildCycleSettings() {
    final smart = _smartCycleLength;
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Cycle Settings', Icons.tune),

      // Date picker row
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _kPinkPale, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kPinkBorder),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kPink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today, color: _kPink, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Last Period Date',
                style: TextStyle(color: _kTextMid, fontSize: 11, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(
              _lastPeriodDate == null ? 'Tap to select' : _fmt(_lastPeriodDate!),
              style: TextStyle(
                color: _lastPeriodDate == null ? _kTextLight : _kTextDark,
                fontSize: 14, fontWeight: FontWeight.w600,
              ),
            ),
          ])),
          GestureDetector(
            onTap: _pickLastPeriodDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: _kGradShort),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(
                  color: _kPink.withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3),
                )],
              ),
              child: const Text('Edit',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      // Smart banner
      if (smart != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EEFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kPinkLight),
          ),
          child: Row(children: [
            const Text('🧠', style: TextStyle(fontSize: 15)),
            const SizedBox(width: 8),
            Expanded(child: RichText(text: TextSpan(
              style: const TextStyle(fontSize: 12, color: _kPinkLight),
              children: [
                const TextSpan(text: 'Smart prediction active · ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(
                  text: 'Using your $smart-day average from ${_allDates.length} logged periods',
                ),
              ],
            ))),
          ]),
        ),
        const SizedBox(height: 14),
      ],

      Row(children: [
        Expanded(child: _lengthPicker(
          label: smart != null ? 'Manual Override' : 'Cycle Length',
          value: _cycleLength,
          items: List.generate(15, (i) => 21 + i),
          onChanged: (v) async { setState(() => _cycleLength = v!); await _saveAll(); },
          unit: 'days', muted: smart != null,
        )),
        const SizedBox(width: 12),
        Expanded(child: _lengthPicker(
          label: 'Period Length',
          value: _periodLength,
          items: List.generate(10, (i) => 3 + i),
          onChanged: (v) async { setState(() => _periodLength = v!); await _saveAll(); },
          unit: 'days',
        )),
      ]),
    ]));
  }

  Widget _lengthPicker({
    required String label, required int value, required List<int> items,
    required ValueChanged<int?> onChanged, required String unit, bool muted = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: muted ? const Color(0xFFF0EAFA) : _kPinkPale,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: muted ? _kPinkBorder : _kPinkBorder),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          color: muted ? _kTextLight : _kTextMid,
          fontSize: 11, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value, isDense: true,
          style: TextStyle(
              color: muted ? _kTextLight : _kTextDark,
              fontSize: 14, fontWeight: FontWeight.w700),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14),
          items: items.map((v) =>
              DropdownMenuItem(value: v, child: Text('$v $unit'))).toList(),
          onChanged: onChanged,
        ),
      ),
    ]),
  );

  // ─── Prediction Card ──────────────────────────────────────────────────────────
  Widget _buildPredictionCard() {
    final p       = prediction;
    final daysAway = p?.predictedStart.difference(DateTime.now()).inDays;
    final conf    = p?.confidence;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: _kGradMain,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: _kPinkDeep.withValues(alpha: 0.35),
          blurRadius: 24, offset: const Offset(0, 10),
        )],
      ),
      child: Stack(children: [
        _circle(right: -20, top: -20, size: 110, opacity: 0.08),
        _circle(right: 20, bottom: -15, size: 60, opacity: 0.06),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🔮', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Next Period Prediction',
                  style: TextStyle(color: Colors.white, fontSize: 15,
                      fontWeight: FontWeight.w700, letterSpacing: 0.3))),
              if (p != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.source == 'smart' ? '🧠 Smart' : '✏️ Manual',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
            ]),
            const SizedBox(height: 18),

            if (p == null)
              const Text('Log your first period date\nto activate smart prediction',
                  style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.6))
            else ...[
              Row(children: [
                Expanded(child: _predStat('Starts On', _fmt(p.predictedStart))),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(child: _predStat('Ends On', _fmt(p.predictedEnd))),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _predStat('Cycle Used', '${p.cycleUsed} days')),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(child: _predStat('Data Points',
                    '${_allDates.length} period${_allDates.length == 1 ? '' : 's'}')),
              ]),
              const SizedBox(height: 16),
              if (conf != null && p.source == 'smart') ...[
                _confidenceBar(conf),
                const SizedBox(height: 12),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(
                  daysAway != null && daysAway >= 0
                      ? daysAway == 0 ? '🩸 Starting today!'
                      : '⏳  $daysAway day${daysAway == 1 ? '' : 's'} away'
                      : '⚠️  Check your cycle log',
                  style: const TextStyle(color: Colors.white, fontSize: 14,
                      fontWeight: FontWeight.w700, letterSpacing: 0.4),
                )),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _predStat(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(
          color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _confidenceBar(double conf) {
    final pct   = (conf * 100).round();
    final label = pct >= 80 ? 'High accuracy' : pct >= 55 ? 'Moderate accuracy' : 'Low accuracy';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Prediction accuracy · $label',
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        Text('$pct%', style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Container(height: 6, color: Colors.white24),
          FractionallySizedBox(
            widthFactor: conf,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ─── Status Card ──────────────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    final sc = statusColor;
    return _card(child: Row(children: [
      Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: sc.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.favorite_rounded, color: sc, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cycle Status',
            style: TextStyle(color: _kTextMid, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(periodStatus, style: TextStyle(
            color: sc, fontSize: 14, fontWeight: FontWeight.w700)),
      ])),
    ]));
  }

  // ─── Symptoms Card ────────────────────────────────────────────────────────────
  Widget _buildSymptomsCard() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Symptoms', Icons.health_and_safety_outlined),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: symptoms.map((s) {
          final sel = _selectedSymptoms.contains(s);
          return GestureDetector(
            onTap: () async {
              setState(() => sel ? _selectedSymptoms.remove(s) : _selectedSymptoms.add(s));
              await _saveAll();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: sel ? const LinearGradient(colors: _kGradShort) : null,
                color: sel ? null : _kPinkPale,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: sel ? _kPink : _kPinkBorder, width: sel ? 0 : 1),
                boxShadow: sel ? [BoxShadow(
                  color: _kPink.withValues(alpha: 0.3),
                  blurRadius: 8, offset: const Offset(0, 3),
                )] : [],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(symptomIcons[s] ?? Icons.circle,
                    size: 14, color: sel ? Colors.white : _kPink),
                const SizedBox(width: 6),
                Text(s, style: TextStyle(
                    color: sel ? Colors.white : _kTextMid,
                    fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          );
        }).toList(),
      ),
      if (_selectedSymptoms.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(width: double.infinity, height: 1, color: _kPinkBorder),
        const SizedBox(height: 14),
        const Row(children: [
          Text('💡', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Text('Tips for You', style: TextStyle(
              color: _kTextDark, fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        ...tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              margin: const EdgeInsets.only(top: 5),
              width: 6, height: 6,
              decoration: const BoxDecoration(color: _kPink, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(tip, style: const TextStyle(
                color: _kTextMid, fontSize: 13, height: 1.5))),
          ]),
        )),
      ],
    ],
  ));

  // ─── History Card ─────────────────────────────────────────────────────────────
  Widget _buildHistoryCard() => _card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Expanded(child: _label('Period History', Icons.history_rounded)),
        GestureDetector(
          onTap: _addToPeriodHistory,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _kPinkPale, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kPinkBorder),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.add, color: _kPink, size: 14),
              SizedBox(width: 4),
              Text('Add', style: TextStyle(
                  color: _kPink, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),

      if (_allDates.length >= 2) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: _kPinkPale, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kPinkBorder),
          ),
          child: Row(children: [
            Expanded(child: _historyStat('Avg Cycle',
                _smartCycleLength != null ? '$_smartCycleLength days' : '—', Icons.loop)),
            Container(width: 1, height: 32, color: _kPinkBorder),
            Expanded(child: _historyStat('Tracked',
                '${_allDates.length} periods', Icons.calendar_month)),
            Container(width: 1, height: 32, color: _kPinkBorder),
            Expanded(child: _historyStat('Accuracy',
                _predictionConfidence != null
                    ? '${(_predictionConfidence! * 100).round()}%' : '—',
                Icons.track_changes)),
          ]),
        ),
      ],

      if (_allDates.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: _kPinkPale, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_month_outlined, color: _kPinkLight, size: 28),
            ),
            const SizedBox(height: 12),
            const Text('No history yet', style: TextStyle(
                color: _kTextDark, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Dates auto-save when you update\nyour last period date',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kTextLight, fontSize: 12, height: 1.5)),
          ]),
        )
      else
        Column(children: [
          if (_lastPeriodDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _historyEntry(
                date: _lastPeriodDate!, label: 'Current', labelColor: _kPink,
                gapDays: _periodHistory.isNotEmpty
                    ? _lastPeriodDate!.difference(_periodHistory.first).inDays : null,
                canDelete: false,
              ),
            ),
          ...List.generate(_periodHistory.length, (i) {
            final date    = _periodHistory[i];
            final gapDays = i + 1 < _periodHistory.length
                ? _periodHistory[i].difference(_periodHistory[i + 1]).inDays : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _historyEntry(date: date, gapDays: gapDays, canDelete: true),
            );
          }),
        ]),
    ],
  ));

  Widget _historyStat(String label, String value, IconData icon) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Column(children: [
      Icon(icon, color: _kPink, size: 16),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(
          color: _kTextDark, fontSize: 13, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: _kTextLight, fontSize: 10)),
    ]),
  );

  Widget _historyEntry({
    required DateTime date, int? gapDays, required bool canDelete,
    String? label, Color? labelColor,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _kPinkPale, borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kPinkBorder),
    ),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: _kGradShort,
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text('${date.day}', style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_fmt(date), style: const TextStyle(
              color: _kTextDark, fontWeight: FontWeight.w600, fontSize: 13)),
          if (label != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (labelColor ?? _kPink).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(label, style: TextStyle(
                  color: labelColor ?? _kPink,
                  fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        if (gapDays != null)
          Text('$gapDays-day gap to previous',
              style: const TextStyle(color: _kTextLight, fontSize: 11)),
      ])),
      if (canDelete)
        GestureDetector(
          onTap: () => _removeHistory(date),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.shade50, borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 16),
          ),
        ),
    ]),
  );
}