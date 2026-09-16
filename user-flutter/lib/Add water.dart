import 'dart:convert';
import 'package:ai_doctor_app/userhome.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// 🎨 UI Constants (consistent with viewWaterfull)
// Using slightly deeper shades for a richer feel
const Color kPrimaryWaterColor = Color(0xFF4FC3F7); // Light Blue
const Color kSecondaryColor = Color(0xFF0288D1); // Deep Blue (used for app bar)
const Color kSuccessColor = Color(0xFF43A047); // Deeper Green
const Color kLightBackgroundColor = Color(0xFFE3F2FD); // Very light blue for background
const double kBorderRadius = 18.0; // Slightly larger border radius for smooth look

// Re-using the MaterialApp/main structure from your original file
void main() {
  runApp(const com());
}

class com extends StatelessWidget {
  const com({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Add Water Log',
      theme: ThemeData(
        // Set primary colors for form elements
        colorScheme: ColorScheme.fromSeed(seedColor: kSecondaryColor),
        useMaterial3: true,
      ),
      home: const AddWater(title: 'Add Water Log'),
    );
  }
}

class AddWater extends StatefulWidget {
  const AddWater({super.key, required this.title});
  final String title;

  @override
  State<AddWater> createState() => _AddWaterState();
}

class _AddWaterState extends State<AddWater> {
  // === LOGIC & STATE (UNCHANGED) ===
  TextEditingController alertControler = TextEditingController();
  TextEditingController typeControler = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  String? selectedType;
  final List<String> waterTypes = ['glass', 'bottle', 'cup', 'other'];

  // Method to handle form submission - LOGIC REMAINS UNCHANGED
  void sendAddWateraint() async {
    // String date = dateController.text; // Original code commented this out
    String alert = alertControler.text;
    // Use the selected dropdown value or the free text if 'other'
    String type = selectedType == 'other' ? typeControler.text : (selectedType ?? '');

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();
    String lid = sh.getString('lid').toString();
    final urls = Uri.parse(url + "/add_water");

    try {
      final response = await http.post(urls, body: {
        // 'date': date,
        'lid': lid,
        'alert': alert,
        'type': type,
      });
      if (response.statusCode == 200) {
        String status = jsonDecode(response.body)['status'];
        if (status == 'ok') {
          Fluttertoast.showToast(msg: 'Water Log Added');
          // Navigate back (or to DietHome as in original code)
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  DietHome()));
        } else {
          Fluttertoast.showToast(msg: 'Failed to add log');
        }
      } else {
        Fluttertoast.showToast(msg: 'Network Error: ${response.statusCode}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  // --- UI Builder ---
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // === LOGIC (UNCHANGED) ===
      onWillPop: () async {
        Navigator.push(context, MaterialPageRoute(builder: (context) =>  DietHome()));
        return false;
      },
      child: Scaffold(
        // Use a lighter background
        backgroundColor: kLightBackgroundColor,
        appBar: AppBar(
          backgroundColor: kSecondaryColor,
          foregroundColor: Colors.white,
          title: const Text('New Hydration Log', style: TextStyle(fontWeight: FontWeight.w800)),
          elevation: 0,
          // Add a subtle gradient effect for the header
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kSecondaryColor, kPrimaryWaterColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Form(
          key: _formkey,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. Title Card (Enhanced with Gradient and Shadow)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(kBorderRadius),
                      gradient: LinearGradient(
                        colors: [kPrimaryWaterColor.withOpacity(0.9), Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: kSecondaryColor.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(25.0),
                      child: Column(
                        children: [
                          Icon(Icons.water_drop_outlined, size: 60, color: kSecondaryColor),
                          SizedBox(height: 10),
                          Text(
                            "Track Your Daily Water",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            "Every drop counts!",
                            style: TextStyle(fontSize: 14, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 2. Water Type Dropdown (Refined Input Decoration)
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Volume Type",
                      hintText: "Select the container size",
                      prefixIcon: const Icon(Icons.local_drink_rounded, color: kSecondaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: BorderSide(color: kPrimaryWaterColor.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: kSecondaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: selectedType,
                    items: waterTypes.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value.toUpperCase(),
                          style: TextStyle(fontWeight: value == selectedType ? FontWeight.bold : FontWeight.normal),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedType = newValue;
                        if (newValue != 'other') {
                          typeControler.clear();
                        }
                      });
                    },
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return "Please select a type.";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // 3. Custom Type Input (Shown only if 'other' is selected)
                  if (selectedType == 'other')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: TextFormField(
                        controller: typeControler,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          labelText: "Custom Type/Volume (e.g., 'small flask' or '350ml')",
                          prefixIcon: const Icon(Icons.text_fields, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kBorderRadius),
                            borderSide: const BorderSide(color: Colors.grey, width: 1),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (String? value) {
                          if (selectedType == 'other' && (value == null || value.isEmpty)) {
                            return "Please enter a custom type.";
                          }
                          return null;
                        },
                      ),
                    ),

                  // 4. Alert/Note Field (Enhanced with hint and focus style)
                  TextFormField(
                    controller: alertControler,
                    keyboardType: TextInputType.text,
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: "Note to remember",
                      hintText: "Optional: Why did you drink? (e.g., 'after gym', 'morning routine')",
                      alignLabelWithHint: true,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 60.0, left: 10, right: 10),
                        child: Icon(Icons.lightbulb_outline, color: kPrimaryWaterColor),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kBorderRadius)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: BorderSide(color: kPrimaryWaterColor.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                        borderSide: const BorderSide(color: kSecondaryColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        // Relaxing the validation slightly since it's a "note"
                        return "Please add a brief note or a dash (-).";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // 5. Submit Button (Final Check and Polish)
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formkey.currentState!.validate()) {
                        sendAddWateraint();
                      }
                    },
                    icon: const Icon(Icons.assignment_turned_in_outlined, size: 24),
                    label: const Text(
                      'LOG THIS INTAKE',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kBorderRadius),
                      ),
                      elevation: 8, // Higher elevation
                      shadowColor: kSuccessColor.withOpacity(0.5),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}