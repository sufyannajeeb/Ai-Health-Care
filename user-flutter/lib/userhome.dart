import 'package:ai_doctor_app/view%20experts.dart';
import 'package:ai_doctor_app/view%20diet_chart.dart';
import 'package:ai_doctor_app/view%20food.dart';
import 'package:ai_doctor_app/view%20water.dart';
import 'package:ai_doctor_app/viewcomplaint.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'view_menstrual_tracker.dart';
import 'Add water.dart';
import 'bmi.dart';
import 'callorie chart.dart';
import 'chatbot.dart';
import 'diet_response_ai_chart_page.dart';
import 'logins.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ai_doctor_app/health_tip.dart';

// --- NEW CLASS: Notification Data Structure ---
class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  NotificationItem({required this.id, required this.title, required this.subtitle, required this.icon, required this.color});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'icon': icon.codePoint, // Store icon as codepoint
    'color': color.value, // Store color as value
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'],
    title: json['title'],
    subtitle: json['subtitle'],
    icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
    color: Color(json['color']),
  );
}

class DietHome extends StatefulWidget {
  @override
  _DietHomeState createState() => _DietHomeState();
}

class _DietHomeState extends State<DietHome> {
  final List<String> imgList = [
    'assets/ai_bot.jpg',
    // You can add more placeholder images here if you have them
  ];

  List<Map<String, dynamic>> foodData = [];
  int totalCalories = 0;
  bool isLoading = true;
  int _currentCarouselIndex = 0;

  // Added for UI visualization (Mock target)
  final int targetCalories = 2200;

  String userName = "User";

  // --- NEW STATE VARIABLES FOR NOTIFICATIONS (FIXED) ---
  bool _isChatBannerDismissed = false;
  String _dismissedExpiryTime = ''; // Tracks the expiry time that was dismissed
  List<NotificationItem> _dismissedNotifications = [];
  // -----------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadNotificationState(); // Load dismissal state
    fetchCalorieData();
    loadUserName();
  }

  // --- UPDATED NOTIFICATION STATE MANAGEMENT WIRING ---

  Future<void> _loadNotificationState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isChatBannerDismissed = prefs.getBool('isChatBannerDismissed') ?? false;
      // FIX: Load the specific expiry time that was dismissed
      _dismissedExpiryTime = prefs.getString('dismissedChatExpiry') ?? '';

      // Load list of dismissed notifications
      List<String> dismissedJson = prefs.getStringList('dismissedNotifications') ?? [];
      _dismissedNotifications = dismissedJson.map((item) => NotificationItem.fromJson(json.decode(item))).toList();
    });
  }

  Future<void> _dismissChatBanner(NotificationItem notification, String currentExpiryString) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isChatBannerDismissed = true;
      // FIX: Save the current expiry string being dismissed
      _dismissedExpiryTime = currentExpiryString;

      prefs.setBool('isChatBannerDismissed', true);
      prefs.setString('dismissedChatExpiry', currentExpiryString); // Save the expiry time

      // Add to dismissed list if not already present
      if (!_dismissedNotifications.any((item) => item.id == notification.id)) {
        _dismissedNotifications.add(notification);
        _saveDismissedNotifications(prefs);
      }
    });
  }

  Future<void> _clearDismissedNotification(NotificationItem notification) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _dismissedNotifications.removeWhere((item) => item.id == notification.id);

      // If the chat banner is cleared from the center, allow it to reappear on the main screen
      if(notification.id == 'chat_banner') {
        _isChatBannerDismissed = false;
        // FIX: Reset the dismissed expiry time as well
        _dismissedExpiryTime = '';

        prefs.setBool('isChatBannerDismissed', false);
        prefs.remove('dismissedChatExpiry'); // Clear the expiry time
      }
      _saveDismissedNotifications(prefs);
    });
  }

  Future<void> _saveDismissedNotifications(SharedPreferences prefs) async {
    List<String> dismissedJson = _dismissedNotifications.map((item) => json.encode(item.toJson())).toList();
    prefs.setStringList('dismissedNotifications', dismissedJson);
  }

  // -----------------------------------------------------------------

  Future<void> loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("username") ?? "User";
    });
  }

  // --- EXISTING WIRING PRESERVED ---
  Future<void> fetchCalorieData() async {
    // ... (Existing logic remains)
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
            foodData = List<Map<String, dynamic>>.from(jsonResponse['data']);
            totalCalories = jsonResponse['total_calories'];
            isLoading = false;
          });
        } else {
          showToast("No data available");
        }
      } else {
        showToast("Error: ${response.statusCode}");
      }
    } catch (e) {
      showToast("Error: ${e.toString()}");
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Define a consistent color palette
    final Color primaryColor = Colors.blue.shade700;
    final Color secondaryColor = Colors.purple.shade600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Custom Extended App Bar Area
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: Text("Ai Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // --- MODIFIED: BELL ICON ACTION ---
          IconButton(
            icon: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.white24, shape: BoxShape.circle),
              child: Stack(
                children: [
                  Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                  if (_dismissedNotifications.isNotEmpty)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(minWidth: 10, minHeight: 10),
                      ),
                    )
                ],
              ),
            ),
            onPressed: () {
              // Show the new Notification Center Overlay
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => _NotificationCenterOverlay(
                  notifications: _dismissedNotifications,
                  onClear: _clearDismissedNotification,
                ),
              );
            },
          ),
          // ------------------------------------

          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    title: Text("Confirm Logout"),
                    content: Text("Are you sure you want to log out?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text("Cancel", style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => Ftnesslogin()),
                          );
                        },
                        child: Text("Logout", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context), // Extracted Drawer for cleaner code
      body: Stack(
        children: [
          // Background Gradient decoration
          Container(
            height: 168,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          // Main Scrollable Body
          SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Chat Timer Banner - visibility is now handled inside the widget
                _buildChatTimerBanner(),

                SizedBox(height: 10),

                // 2. Header Welcome Text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, $userName!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Let's check your health status today.",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25),

                // 3. Main Stats Card (Replaces the Carousel as the Hero Element)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _buildCalorieProgressCard(),
                ),

                SizedBox(height: 20),

                // 4. Carousel (Moved down slightly as a feature highlight)
                CarouselSlider(
                  options: CarouselOptions(
                    height: 140,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.9,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentCarouselIndex = index;
                      });
                    },
                  ),
                  items: imgList.map((item) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: AssetImage(item),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(Colors.black26, BlendMode.darken),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Ask AI Anything",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  )).toList(),
                ),

                SizedBox(height: 25),

                // 5. Grid Menu
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Quick Access", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Icon(Icons.grid_view_rounded, size: 20, color: Colors.grey),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                _buildFeatureGrid(context),

                SizedBox(height: 30),

                // 6. NEW SECTION: Hydration Tracker (Visual)
                _buildHydrationSection(),

                SizedBox(height: 20),

                // 7. NEW SECTION: Daily Insights (Scrollable Content)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text("Daily Insights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 10),
                _buildDailyInsightsList(),

                SizedBox(height: 80), // Bottom padding for FAB
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));
        },
        backgroundColor: Colors.green.shade600,
        icon: Icon(Icons.assistant, color: Colors.white),
        label: Text("AI Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  // --- MODIFIED: CHAT TIMER BANNER WITH DISMISSAL BUTTON (FIXED LOGIC) ---
  Widget _buildChatTimerBanner() {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final prefs = snapshot.data!;
        final expiryString = prefs.getString("chat_expiry");
        if (expiryString == null) return SizedBox.shrink(); // Use SizedBox.shrink() instead of SizedBox() for better performance

        final expiry = DateTime.tryParse(expiryString);
        if (expiry == null) return SizedBox.shrink();

        final now = DateTime.now();
        final diff = expiry.difference(now);

        // **CORE FIX LOGIC**
        // 1. Get the last dismissed expiry time from state
        final lastDismissedExpiry = _dismissedExpiryTime;

        // 2. Determine if the current banner should be hidden:
        //    a. Is the banner marked as dismissed? (_isChatBannerDismissed is loaded in initState)
        //    b. AND is the current 'chat_expiry' value identical to the one that was dismissed?
        final bool shouldHideBanner = _isChatBannerDismissed && (expiryString == lastDismissedExpiry);

        if (shouldHideBanner) {
          return SizedBox.shrink(); // Hide the banner if it was dismissed for this specific timer
        }
        // **END CORE FIX LOGIC**


        Color bgColor;
        IconData icon;
        String text;
        String subText;
        String notificationId = 'chat_banner'; // Unique ID for this notification

        if (diff.isNegative) {
          bgColor = Colors.redAccent;
          icon = Icons.timer_off;
          text = "Session Expired";
          subText = "Renew to chat";
        } else {
          bgColor = Colors.green;
          icon = Icons.timer;
          text = "Chat Active";
          String two(int n) => n.toString().padLeft(2, '0');
          subText = "${two(diff.inHours)}:${two(diff.inMinutes % 60)}:${two(diff.inSeconds % 60)} remaining";
        }

        // Define the notification item to be dismissed
        final NotificationItem notificationItem = NotificationItem(
          id: notificationId,
          title: text,
          subtitle: subText,
          icon: icon,
          color: bgColor,
        );


        return Dismissible(
          // FIX: Key changed to include expiryString for uniqueness across sessions
          key: Key(notificationId + expiryString),
          direction: DismissDirection.startToEnd,
          onDismissed: (direction) {
            // FIX: Pass the current expiry string when dismissing
            _dismissChatBanner(notificationItem, expiryString);
          },
          background: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.only(left: 20),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.red.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.delete_sweep, color: Colors.white),
          ),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(color: bgColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: bgColor),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(subText, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  // FIX: Pass the current expiry string when dismissing
                  onPressed: () => _dismissChatBanner(notificationItem, expiryString),
                )
              ],
            ),
          ),
        );
      },
    );
  }
  // -------------------------------------------------------------------------


  Widget _buildCalorieProgressCard() {
    // ... (Existing logic remains)
    double progress = (totalCalories / targetCalories).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Calories Eaten", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                    "$totalCalories kcal",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
              ),
            ],
          ),
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("0 kcal", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text("Target: $targetCalories kcal", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // --- EXISTING WIDGET BUILDERS REMAIN INTACT ---
  Widget _buildFeatureGrid(BuildContext context) {
    // ... (Existing logic remains)
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: 0.9,
        children: [
          _buildFeatureTile("Calorie", Icons.pie_chart_outline, Colors.teal, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CalorieChartPage(title: '')));
          }),
          _buildFeatureTile("Health Plan", Icons.restaurant, Colors.green, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => DietChartPage()));
          }),
          _buildFeatureTile("BMI Calc", Icons.monitor_weight_outlined, Colors.orange, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => BMIPage()));
          }),
          _buildFeatureTile("Water", Icons.water_drop_outlined, Colors.blue, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => viewWaterfull(title: '')));
          }),
          _buildFeatureTile("Tips", Icons.lightbulb_outline, Colors.purple, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => HealthTipPage()));
          }),
          _buildFeatureTile("Cycle", Icons.calendar_month, Colors.pink, () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => MenstrualTrackerPage()));
          }),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String title, IconData icon, Color color, VoidCallback onTap) {
    // ... (Existing logic remains)
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationSection() {
    // ... (Existing logic remains)
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text("Hydration Goal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Text("3/8 Glasses", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(8, (index) {
              bool isDrank = index < 3; // Mock logic: first 3 drank
              return Icon(
                isDrank ? Icons.water_drop : Icons.water_drop_outlined,
                color: isDrank ? Colors.blue : Colors.blue.shade200,
                size: 24,
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildDailyInsightsList() {
    // ... (Existing logic remains)
    final List<Map<String, String>> articles = [
      {"title": "Why Sleep Matters", "subtitle": "Recovery & Health", "time": "5 min read"},
      {"title": "Sugar vs Sweeteners", "subtitle": "Diet Myths", "time": "3 min read"},
      {"title": "10 min Home Workout", "subtitle": "Fitness", "time": "10 min"},
    ];

    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.article, color: Colors.grey),
            ),
            title: Text(articles[index]["title"]!, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(articles[index]["subtitle"]!),
            trailing: Text(articles[index]["time"]!, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    // ... (Existing logic remains)
    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/ai_bot.jpg'), // Fallback if asset missing
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.blue.withOpacity(0.8), BlendMode.srcOver),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 35, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text('Ai Doctor', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('Stay Healthy', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            _drawerTile(Icons.dashboard, 'Dashboard', () => Navigator.pop(context)),
            _drawerTile(Icons.restaurant_menu, 'Health Plan', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewDietChartsPage()))),
            _drawerTile(Icons.medical_services, 'Consult Doctors', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewExperts(title: '')))),
            Divider(),
            _drawerTile(Icons.water_drop, 'Water Log', () => Navigator.push(context, MaterialPageRoute(builder: (context) => viewWaterfull(title: '')))),
            _drawerTile(Icons.fastfood, 'Food Log', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewFoodsfull(title: '')))),
            _drawerTile(Icons.feedback, 'Complaints', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ViewComplaints(title: '')))),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, VoidCallback onTap) {
    // ... (Existing logic remains)
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
      onTap: onTap,
    );
  }
}

// --- NEW CLASS: Notification Center Overlay ---

class _NotificationCenterOverlay extends StatelessWidget {
  final List<NotificationItem> notifications;
  final Function(NotificationItem) onClear;

  const _NotificationCenterOverlay({
    required this.notifications,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Takes up 75% of screen height
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Notification Center",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey[200]),
          Expanded(
            child: notifications.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt, color: Colors.green, size: 50),
                  SizedBox(height: 10),
                  Text("All caught up!", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  Text("No dismissed notifications.", style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            )
                : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Dismissible(
                  key: Key(item.id + index.toString()), // Unique key for Dismissible
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    onClear(item); // Call the clear logic
                  },
                  child: ListTile(
                    leading: Icon(item.icon, color: item.color),
                    title: Text(item.title, style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(item.subtitle),
                    trailing: Icon(Icons.arrow_back_ios, size: 12, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}