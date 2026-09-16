import 'package:ai_doctor_app/userchat.dart';
import 'package:ai_doctor_app/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'userchat.dart';
import 'expert_review.dart';

// 🎨 Theme Constants for a Modern Look
const Color kPrimaryColor = Color(0xFF1E88E5); // Blue 600
const Color kSecondaryColor = Color(0xFFFFC107); // Amber (for review/accent)
const Color kBackgroundColor = Color(0xFFF5F5F5); // Light Grey Background
const Color kCardColor = Colors.white;
const double kBorderRadius = 18.0;

class ViewExperts extends StatefulWidget {
  const ViewExperts({super.key, required this.title});
  final String title;

  @override
  State<ViewExperts> createState() => _ViewExpertsState();
}

class _ViewExpertsState extends State<ViewExperts> {
  // Existing state variables - DO NOT CHANGE
  List<int> id_ = [];
  List<String> name_ = [];
  List<String> place_ = [];
  List<String> image_ = [];
  List<String> gender_ = [];
  List<String> LOGIN_ = [];

  List<int> filteredIndexes = [];
  String selectedType = "All";

  bool isLoading = true; // New state for loading indicator

  @override
  void initState() {
    super.initState();
    // Wrap the call to set isLoading=false after data fetch
    ViewExpertss().then((_) {
      setState(() {
        isLoading = false;
      });
    });
  }

  // Existing ViewExpertss method - LOGIC/WIRING MUST REMAIN UNCHANGED
  Future<void> ViewExpertss() async {
    List<int> ids = [];
    List<String> names = [];
    List<String> places = [];
    List<String> images = [];
    List<String> genders = [];
    List<String> logins = [];

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final base = sh.getString('url') ?? '';
      final imgBase = sh.getString('imgurl') ?? '';

      if (base.isEmpty) {
        print("Base URL missing!");
        return;
      }

      final res = await http
          .post(Uri.parse('$base/user_view_expert'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return;

      final jsondata = json.decode(res.body);
      final arr = jsondata["data"] ?? [];

      for (var item in arr) {
        ids.add(item['id'] ?? 0);
        names.add(item['name']?.toString() ?? "");
        places.add(item['place']?.toString() ?? "");
        genders.add(item['gender']?.toString() ?? "");
        logins.add(item['LOGIN']?.toString() ?? "");

        final rawImg = item['image'];
        images.add(
            rawImg == null || rawImg.toString().trim().isEmpty
                ? ""
                : imgBase + rawImg.toString()
        );
      }

      setState(() {
        id_ = ids;
        name_ = names;
        place_ = places;
        gender_ = genders;
        image_ = images;
        LOGIN_ = logins;
        filteredIndexes = List<int>.generate(names.length, (i) => i);
      });
    } catch (e) {
      print("Error: $e");
    }
  }

  // Existing filterByName method - LOGIC MUST REMAIN UNCHANGED
  void filterByName(String name) {
    setState(() {
      selectedType = name;
      filteredIndexes = (name == "All")
          ? List<int>.generate(name_.length, (i) => i)
          : List<int>.generate(name_.length, (i) => i)
          .where((i) => name_[i] == name)
          .toList();
    });
  }

  // Helper method to build the image widget with better handling
  Widget _buildDoctorImage(String imageUrl) {
    // Using a custom container with border for a clean look
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(kBorderRadius - 4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadius - 4),
        child: imageUrl.isEmpty
            ? const Center(
          child: Icon(Icons.person_4_outlined, size: 80, color: Colors.grey),
        )
            : Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
                color: kPrimaryColor,
              ),
            );
          },
          errorBuilder: (c, e, s) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image_outlined, size: 60, color: Colors.grey.shade400),
                const Text("Image Error", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for chat button logic (No logic change, only aesthetic isolation)
  void _handleChatButtonPress(int index) async {
    SharedPreferences sh = await SharedPreferences.getInstance();

    final userId = sh.getString('lid');
    final expertLoginId = LOGIN_[index];
    final baseUrl = sh.getString('url')!;

    // LOGIC START: Existing Shared Preferences and API call logic - DO NOT CHANGE
    await sh.setString('clid', expertLoginId);
    await sh.setString('chatname', name_[index]);

    final response = await http.post(
      Uri.parse("$baseUrl/check_chat_access"),
      body: {
        "user_id": userId,
        "expert_id": expertLoginId,
      },
    );

    final result = json.decode(response.body);

    // -------- ACCESS ALLOWED --------
    if (result["status"] == "allowed") {
      final expiresAt = result["expires_at"];
      if (expiresAt != null) {
        await sh.setString("chat_expiry", expiresAt);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyChatPage(title: ""),
        ),
      );
    }

    // -------- EXPIRED ACCESS --------
    else if (result["status"] == "expired") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Your chat access expired. Please purchase again."),
          backgroundColor: Colors.orange,
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            expertId: expertLoginId,
            amount: 1099, // Existing amount
          ),
        ),
      );
    }

    // -------- NO ACCESS --------
    else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            expertId: expertLoginId,
            amount: 1099, // Existing amount
          ),
        ),
      );
    }
    // LOGIC END
  }

  // Helper method for review button logic (No logic change, only aesthetic isolation)
  void _handleReviewButtonPress(int index) async {
    SharedPreferences sh = await SharedPreferences.getInstance();

    // LOGIC START: Existing Shared Preferences and Navigation logic - DO NOT CHANGE
    await sh.setString('eid', id_[index].toString());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => feedback(title: ''),
      ),
    );
    // LOGIC END
  }

  @override
  Widget build(BuildContext context) {
    // Ensure "All" is first, then the unique names
    final dropdownItems = ["All", ...{...name_}.where((n) => n.isNotEmpty)];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0, // Flat app bar for modern look
        actions: [
          // Using a Builder to correctly position the Dropdown button
          // This uses a custom button style for a modern look
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedType,
                icon: const Icon(Icons.filter_list, color: Colors.white),
                style: const TextStyle(color: kPrimaryColor, fontSize: 16),
                dropdownColor: Colors.white,
                items: dropdownItems.map((String value) {
                  return DropdownMenuItem(
                    value: value,
                    child: Text(
                      value,
                      style: TextStyle(
                        color: value == selectedType ? kPrimaryColor : Colors.black87,
                        fontWeight: value == selectedType ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) filterByName(newValue);
                },
              ),
            ),
          ),
        ],
      ),

      // ================= LIST OF DOCTORS =====================
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : filteredIndexes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              selectedType == "All"
                  ? "No doctors found."
                  : "No doctors named '$selectedType' found.",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: filteredIndexes.length,
        itemBuilder: (context, index) {
          final i = filteredIndexes[index];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildDoctorCard(i),
          );
        },
      ),
    );
  }

  // Extracted Doctor Card Widget for cleaner build method
  Widget _buildDoctorCard(int i) {
    return Card(
      color: kCardColor,
      elevation: 6, // Higher elevation for depth
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            _buildDoctorImage(image_[i]),

            const SizedBox(height: 16),

            // Name and Title Section
            Text(
              "Dr. ${name_[i]}",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: kPrimaryColor,
              ),
            ),

            const SizedBox(height: 8),

            // Details Section (Place & Gender)
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    place_[i],
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.people_alt_outlined, size: 20, color: Colors.blueGrey),
                const SizedBox(width: 6),
                Text(
                  gender_[i],
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),

            const Divider(height: 30, thickness: 1),

            // Action Buttons Section
            Row(
              children: [
                // ================= CHAT BUTTON =====================
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleChatButtonPress(i), // Use helper
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    label: const Text(
                      "Chat Now",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // ================= REVIEW BUTTON =====================
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleReviewButtonPress(i), // Use helper
                    icon: Icon(Icons.rate_review_outlined, color: kSecondaryColor),
                    label: const Text(
                      "Review",
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: kSecondaryColor, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}