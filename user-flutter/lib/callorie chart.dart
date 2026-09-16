import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const DiseaseCountApp());
}

class DiseaseCountApp extends StatelessWidget {
  const DiseaseCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Disease Count Visualization',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Georgia',
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const CalorieChartPage(title: 'Disease Count by Year'),
    );
  }
}

class CalorieChartPage extends StatefulWidget {
  const CalorieChartPage({super.key, required this.title});
  final String title;

  @override
  State<CalorieChartPage> createState() => _CalorieChartPageState();
}

class _CalorieChartPageState extends State<CalorieChartPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> foodData = [];
  int totalCalories = 0;
  bool isLoading = true;
  int? touchedIndex;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _accent = Color(0xFF0D9488); // teal-600
  static const Color _accentLight = Color(0xFFCCFBF1); // teal-100
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    fetchCalorieData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchCalorieData() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('url') ?? '';
      String lid = prefs.getString('lid') ?? '';
      String url = '$baseUrl/user_view_take_calorie';

      var response = await http.post(
        Uri.parse(url),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'ok') {
          setState(() {
            foodData =
            List<Map<String, dynamic>>.from(jsonResponse['data']);
            totalCalories = jsonResponse['total_calories'];
            isLoading = false;
          });
          _animationController.forward(from: 0);
        } else {
          setState(() => isLoading = false);
          _showToast("No data available");
        }
      } else {
        setState(() => isLoading = false);
        _showToast("Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showToast("Error: ${e.toString()}");
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: _textPrimary,
      textColor: Colors.white,
    );
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFF0D9488),
      Color(0xFF0EA5E9),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF10B981),
      Color(0xFFF97316),
      Color(0xFF6366F1),
    ];
    return colors[index % colors.length];
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final String todayDate =
    DateFormat('EEEE, MMM d, yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: _accent,
          onRefresh: fetchCalorieData,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildSliverAppBar(todayDate),
              if (isLoading)
                const SliverFillRemaining(child: _LoadingView())
              else if (foodData.isEmpty)
                const SliverFillRemaining(child: _EmptyView())
              else
                _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(String date) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130,
      backgroundColor: _surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accentLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_fire_department_rounded,
                        color: _accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textPrimary,
          ),
        ),
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────
  Widget _buildContent() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 20),
                _buildChartCard(),
                const SizedBox(height: 20),
                _buildLegend(),
                const SizedBox(height: 20),
                _buildSectionLabel('Breakdown'),
                const SizedBox(height: 12),
                ..._buildFoodList(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ── Summary Card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF0891B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Calories',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  NumberFormat('#,###').format(totalCalories),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'kcal today',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }

  // ── Pie Chart Card ────────────────────────────────────────────────────────
  Widget _buildChartCard() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Distribution'),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse
                          .touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: _generatePieSections(),
                centerSpaceRadius: 50,
                sectionsSpace: 3,
              ),
            ),
          ),
          if (touchedIndex != null &&
              touchedIndex! >= 0 &&
              touchedIndex! < foodData.length) ...[
            const SizedBox(height: 16),
            _buildTouchedInfo(touchedIndex!),
          ],
        ],
      ),
    );
  }

  Widget _buildTouchedInfo(int index) {
    final item = foodData[index];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _getColor(index).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getColor(index).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _getColor(index),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            item['type'] ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _getColor(index),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            '${item['callorie'] ?? 0} kcal · ${item['gram'] ?? 0} g',
            style: const TextStyle(color: _textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Legend ────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('Legend'),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: foodData.asMap().entries.map((entry) {
              final color = _getColor(entry.key);
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.value['type'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Food list ─────────────────────────────────────────────────────────────
  List<Widget> _buildFoodList() {
    return foodData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final color = _getColor(index);
      final calories =
          double.tryParse(item['callorie']?.toString() ?? '0') ?? 0;
      final maxCal = foodData
          .map((e) => double.tryParse(e['callorie']?.toString() ?? '0') ?? 0)
          .reduce((a, b) => a > b ? a : b);
      final progress = maxCal > 0 ? calories / maxCal : 0.0;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _Card(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    (item['type'] ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['type'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          '${item['callorie'] ?? 0} kcal',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: color.withOpacity(0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['gram'] ?? 0} g',
                      style: const TextStyle(
                          fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _textSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    return foodData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == touchedIndex;
      final calories =
          double.tryParse(item['callorie']?.toString() ?? '0') ?? 0;

      return PieChartSectionData(
        value: calories,
        color: _getColor(index),
        title: isTouched ? '${item['type']}' : '',
        radius: isTouched ? 72 : 60,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? null
            : null,
      );
    }).toList();
  }
}

// ── Reusable Card ─────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Card({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Loading View ──────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFF0D9488),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading data...',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty View ────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFCCFBF1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inbox_rounded,
                color: Color(0xFF0D9488), size: 36),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pull down to refresh',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}