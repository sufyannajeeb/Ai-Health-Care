import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'Add food.dart';
import 'app_theme.dart';
import 'userhome.dart';

// NOTE: No void main() here. Entry point is lib/ip.dart (or your main.dart).

class FoodItem {
  final int id;
  final String type;
  final String date;
  final String gram;
  final String calorie;

  FoodItem({
    required this.id,
    required this.type,
    required this.date,
    required this.gram,
    required this.calorie,
  });
}

class ViewFoodsfull extends StatefulWidget {
  const ViewFoodsfull({super.key, required this.title});
  final String title;

  @override
  State<ViewFoodsfull> createState() => _ViewFoodsfullState();
}

class _ViewFoodsfullState extends State<ViewFoodsfull>
    with TickerProviderStateMixin {
  List<FoodItem> foodItems = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    fetchFoodLogs();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchFoodLogs() async {
    setState(() {
      isLoading = true;
      hasError = false;
      errorMessage = '';
    });
    _fadeController.reset();

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final String? baseUrl = sh.getString('url');
      final String? lid = sh.getString('lid');

      if (baseUrl == null || baseUrl.trim().isEmpty) {
        _setError('Server URL not configured. Please login again.');
        return;
      }
      if (lid == null || lid.trim().isEmpty) {
        _setError('Session expired. Please login again.');
        return;
      }

      final String cleanUrl =
      baseUrl.endsWith('/') ? baseUrl.trimRight() : baseUrl;

      final response = await http
          .post(
        Uri.parse('$cleanUrl/user_view_foodlo'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {'lid': lid},
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded == null || decoded['data'] == null) {
          setState(() {
            foodItems = [];
            isLoading = false;
          });
          _fadeController.forward();
          return;
        }

        final arr = decoded['data'];
        final List<FoodItem> items = [];
        for (int i = 0; i < arr.length; i++) {
          items.add(FoodItem(
            id: arr[i]['id'] is int
                ? arr[i]['id']
                : int.tryParse(arr[i]['id'].toString()) ?? 0,
            date: arr[i]['date']?.toString() ?? '',
            type: arr[i]['type']?.toString() ?? '',
            gram: arr[i]['gram']?.toString() ?? '',
            calorie: arr[i]['callorie']?.toString() ?? '',
          ));
        }

        setState(() {
          foodItems = items;
          isLoading = false;
        });
        _fadeController.forward();
      } else {
        _setError('Server error (${response.statusCode}). Try again.');
      }
    } on http.ClientException catch (e) {
      _setError('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _setError('Connection timed out. Check your internet.');
      } else if (e.toString().contains('SocketException')) {
        _setError('No internet connection.');
      } else if (e.toString().contains('FormatException')) {
        _setError('Invalid server response. Contact support.');
      } else {
        _setError('Something went wrong. Please try again.');
      }
    }
  }

  void _setError(String msg) {
    setState(() {
      hasError = true;
      errorMessage = msg;
      isLoading = false;
    });
  }

  Future<void> deleteFoodItem(int index) async {
    final item = foodItems[index];
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final String? baseUrl = sh.getString('url');
      if (baseUrl == null || baseUrl.trim().isEmpty) {
        Fluttertoast.showToast(msg: 'Server URL not configured');
        return;
      }

      final String cleanUrl =
      baseUrl.endsWith('/') ? baseUrl.trimRight() : baseUrl;

      final response = await http
          .post(
        Uri.parse('$cleanUrl/delete_food_log'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {'wid': item.id.toString()},
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final status = jsonDecode(response.body)['status'];
        if (status == 'ok') {
          setState(() => foodItems.removeAt(index));
          Fluttertoast.showToast(
            msg: 'Food entry removed',
            backgroundColor: AppTheme.primary,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(msg: 'Could not delete. Try again.');
        }
      } else {
        Fluttertoast.showToast(
            msg: 'Server error (${response.statusCode})');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Network error. Please try again.');
    }
  }

  double get totalCalories => foodItems.fold(
      0.0, (s, i) => s + (double.tryParse(i.calorie) ?? 0.0));

  double get totalGrams => foodItems.fold(
      0.0, (s, i) => s + (double.tryParse(i.gram) ?? 0.0));

  Color _mealColor(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return AppTheme.breakfastClr;
      case 'lunch':     return AppTheme.lunchClr;
      case 'dinner':    return AppTheme.dinnerClr;
      case 'snack':     return AppTheme.snackClr;
      default:          return AppTheme.otherClr;
    }
  }

  String _mealEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast': return '🌅';
      case 'lunch':     return '🍱';
      case 'dinner':    return '🌙';
      case 'snack':     return '🍎';
      default:          return '🍽️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: AppTheme.bgPage,
        body: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppTheme.primary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  onPressed: fetchFoodLogs,
                  tooltip: 'Refresh',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Colors.white,
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Food Log',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Today's nutrition overview",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (!isLoading && !hasError && foodItems.isNotEmpty)
                            Row(
                              children: [
                                _SummaryChip(
                                  icon: Icons.local_fire_department_rounded,
                                  label:
                                  '${totalCalories.toStringAsFixed(0)} kcal',
                                ),
                                const SizedBox(width: 8),
                                _SummaryChip(
                                  icon: Icons.scale_rounded,
                                  label:
                                  '${totalGrams.toStringAsFixed(0)} g',
                                ),
                                const SizedBox(width: 8),
                                _SummaryChip(
                                  icon: Icons.fastfood_rounded,
                                  label: '${foodItems.length} items',
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ──
            if (isLoading)
              const SliverFillRemaining(child: _LoadingView())
            else if (hasError)
              SliverFillRemaining(
                child: _ErrorView(
                  message: errorMessage,
                  onRetry: fetchFoodLogs,
                ),
              )
            else if (foodItems.isEmpty)
                const SliverFillRemaining(child: _EmptyView())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => FadeTransition(
                        opacity: _fadeAnimation,
                        child: _FoodCard(
                          item: foodItems[index],
                          mealColor: _mealColor(foodItems[index].type),
                          mealEmoji: _mealEmoji(foodItems[index].type),
                          onDelete: () => _showDeleteDialog(index),
                        ),
                      ),
                      childCount: foodItems.length,
                    ),
                  ),
                ),
          ],
        ),

        // ── FAB ──
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D5E), Color(0xFF43A87A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddFoods(title: '')),
              ).then((_) => fetchFoodLogs());
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Add Food',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(int index) {
    final item = foodItems[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardWhite,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.errorClr.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppTheme.errorClr, size: 26),
        ),
        title: const Text(
          'Remove Entry',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        content: Text(
          'Remove "${item.type}" from your food log?',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textMid, fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textMid,
                    side: const BorderSide(color: AppTheme.borderClr),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    deleteFoodItem(index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorClr,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Delete',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Food Card ──
class _FoodCard extends StatelessWidget {
  final FoodItem item;
  final Color mealColor;
  final String mealEmoji;
  final VoidCallback onDelete;

  const _FoodCard({
    required this.item,
    required this.mealColor,
    required this.mealEmoji,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderClr, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Emoji avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: mealColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: mealColor.withOpacity(0.25), width: 1.2),
              ),
              child: Center(
                child:
                Text(mealEmoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: mealColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type.toUpperCase(),
                          style: TextStyle(
                            color: mealColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.calendar_today_rounded,
                          size: 11, color: AppTheme.textLight),
                      const SizedBox(width: 3),
                      Text(
                        item.date,
                        style: const TextStyle(
                          color: AppTheme.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatPill(
                        icon: Icons.local_fire_department_rounded,
                        value: '${item.calorie} kcal',
                        color: AppTheme.breakfastClr,
                        bg: const Color(0xFFFFF3E0),
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: Icons.scale_rounded,
                        value: '${item.gram} g',
                        color: AppTheme.primary,
                        bg: AppTheme.primaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Delete
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.errorClr.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppTheme.errorClr.withOpacity(0.2)),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppTheme.errorClr, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Pill ──
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final Color bg;

  const _StatPill(
      {required this.icon,
        required this.value,
        required this.color,
        required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Summary Chip ──
class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Loading ──
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primary,
              backgroundColor: AppTheme.borderClr,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your food log...',
            style: TextStyle(
                color: AppTheme.textMid,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Error ──
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorClr.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.errorClr.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  color: AppTheme.errorClr, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Connection Failed',
                style: TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.textMid, fontSize: 14)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty ──
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3), width: 2),
            ),
            child: const Center(
              child:
              Text('🍽️', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Nothing logged yet',
              style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first meal',
            style:
            TextStyle(color: AppTheme.textMid, fontSize: 14),
          ),
        ],
      ),
    );
  }
}