import 'package:ai_doctor_app/userhome.dart';
import 'package:ai_doctor_app/view%20experts.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'Add water.dart';

// 🎨 UI Constants
const Color kPrimaryWaterColor = Color(0xFF4FC3F7); // Light Blue 400
const Color kSecondaryColor = Color(0xFF03A9F4); // Cyan/Deep Blue
const Color kBackgroundColor = Color(0xFFF5F9FD); // Very light blue background
const double kBorderRadius = 14.0;

class WaterLog {
  final int id;
  final DateTime date;
  final String type;
  final String alert;

  WaterLog({
    required this.id,
    required this.date,
    required this.type,
    required this.alert,
  });
}

class viewWaterfull extends StatefulWidget {
  const viewWaterfull({super.key, required this.title});
  final String title;

  @override
  State<viewWaterfull> createState() => _viewWaterfullState();
}

class _viewWaterfullState extends State<viewWaterfull> {
  // === LOGIC & STATE (UNCHANGED) ===
  final int dailyGoal = 2000;
  int dailyIntake = 0;
  bool isLoading = true;

  List<WaterLog> logs = [];

  static const Map<String, int> intakeRules = {
    'glass': 250,
    'bottle': 500,
    'cup': 200,
  };

  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    fetchWaterLogs();
  }

  Future<void> fetchWaterLogs() async {
    // === LOGIC (UNCHANGED) ===
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final baseUrl = sh.getString('url')!;
      final lid = sh.getString('lid')!;

      final response = await http.post(
        Uri.parse('$baseUrl/user_view_waterlo'),
        body: {'lid': lid},
      );

      final jsonData = json.decode(response.body);

      if (jsonData['status'] != 'ok') {
        Fluttertoast.showToast(msg: 'No data available');
        return;
      }

      final List<WaterLog> fetchedLogs = (jsonData['data'] as List)
          .map((e) => WaterLog(
        id: e['id'],
        date: DateTime.parse(e['date']),
        type: e['type'],
        alert: e['alert'],
      ))
          .toList();

      setState(() {
        logs = fetchedLogs.reversed.toList(); // Display newest logs first
        calculateDailyIntake();
        isLoading = false;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  void calculateDailyIntake() {
    // === LOGIC (UNCHANGED) ===
    final today = DateTime.now();
    int total = 0;

    for (final log in logs) {
      if (isSameDay(log.date, today)) {
        final type = log.type.toLowerCase();
        final intake = intakeRules.entries
            .firstWhere(
              (e) => type.contains(e.key),
          orElse: () => const MapEntry('', 200),
        )
            .value;
        total += intake;
      }
    }

    dailyIntake = total;
  }

  Future<void> deleteWaterLog(int index) async {
    // === LOGIC (UNCHANGED) ===
    final logId = logs[index].id.toString();
    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final baseUrl = sh.getString('url')!;

      final response = await http.post(
        Uri.parse('$baseUrl/delete_water_log'),
        body: {'wid': logId},
      );

      if (jsonDecode(response.body)['status'] == 'ok') {
        setState(() {
          logs.removeAt(index);
          calculateDailyIntake(); // Recalculate intake after deletion
        });
        Fluttertoast.showToast(msg: 'Log deleted successfully');
      } else {
        Fluttertoast.showToast(msg: 'Delete failed');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  // === UI HELPER FUNCTIONS ===

  Widget _buildWaterProgress(BuildContext context) {
    final progress = (dailyIntake / dailyGoal).clamp(0.0, 1.0);
    final isGoalReached = dailyIntake >= dailyGoal;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "💧 Today's Intake",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kSecondaryColor,
                ),
              ),
              Text(
                "${dailyIntake} ml / ${dailyGoal} ml",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isGoalReached ? Colors.green.shade700 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Custom Linear Progress Indicator for a modern look
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isGoalReached ? Colors.green : kPrimaryWaterColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              isGoalReached ? "Goal Achieved! 🎉" : "Keep Hydrating!",
              style: TextStyle(
                color: isGoalReached ? Colors.green.shade700 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to format date nicely
  String _formatLogDate(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) return 'Today';
    if (isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    // Using Colors.white for kCardColor here since it's not defined globally in the constraints
    const Color kCardColor = Colors.white;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Hydration Tracker',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Water Progress Section
          _buildWaterProgress(context),

          const SizedBox(height: 10),

          // 2. Log History Title
          const Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Log History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // 3. Log List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: kSecondaryColor))
                : logs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.waves, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  const Text(
                    'No water logs found for today. Tap + to add!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: logs.length,
              itemBuilder: (_, index) {
                final log = logs[index];
                final intakeAmount = intakeRules.entries
                    .firstWhere(
                      (e) => log.type.toLowerCase().contains(e.key),
                  orElse: () => const MapEntry('', 200),
                )
                    .value;

                // Use Dismissible for swipe-to-delete UX
                return Dismissible(
                  key: ValueKey(log.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red.shade600,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: const Icon(Icons.delete_forever, color: Colors.white, size: 30),
                  ),
                  confirmDismiss: (direction) async {
                    // Show confirmation dialog before deleting (better UX)
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Confirm Deletion"),
                          content: const Text("Are you sure you want to delete this log?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text("CANCEL"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text("DELETE", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    // Actual delete function (Logic remains unchanged)
                    deleteWaterLog(index);
                  },
                  child: Card(
                    color: kCardColor,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kPrimaryWaterColor.withOpacity(0.2),
                        child: Icon(Icons.local_drink, color: kSecondaryColor),
                      ),
                      title: Text(
                        "${intakeAmount} ml (${log.type})",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        log.alert.isEmpty ? "No notes" : log.alert,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatLogDate(log.date),
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          Text(
                            "${log.date.hour}:${log.date.minute.toString().padLeft(2, '0')}",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // 4. Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to AddWater and wait for a result (refresh)
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWater(title: '')),
          );
          // Refresh logs when returning from AddWater
          setState(() {
            isLoading = true; // Show loading while fetching fresh data
          });
          fetchWaterLogs();
        },
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_circle_outline, size: 30),
      ),
    );
  }
}