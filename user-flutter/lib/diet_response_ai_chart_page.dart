import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class DietChartPage extends StatefulWidget {
  @override
  _DietChartPageState createState() => _DietChartPageState();
}

class _DietChartPageState extends State<DietChartPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController genderController = TextEditingController();
  final TextEditingController obesityController = TextEditingController();
  final TextEditingController alcoholAbuseController = TextEditingController();
  final TextEditingController drugUseController = TextEditingController();
  final TextEditingController smokingController = TextEditingController();
  final TextEditingController headachesController = TextEditingController();
  final TextEditingController asthmaController = TextEditingController();
  final TextEditingController cancerController = TextEditingController();
  final TextEditingController strokeController = TextEditingController();
  final TextEditingController kidneyController = TextEditingController();
  final TextEditingController liverController = TextEditingController();
  final TextEditingController depressionController = TextEditingController();
  final TextEditingController allergiesController = TextEditingController();
  final TextEditingController arthritisController = TextEditingController();
  final TextEditingController pregnancyController = TextEditingController();
  final TextEditingController bmiController = TextEditingController();
  final TextEditingController bloodPressureController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<String> aiPhrases = [
    "Engaging AI Predictive Engine…",
    "Analyzing Biological Patterns…",
    "Processing Health Metrics…",
    "Running Diagnostic Algorithms…",
    "Generating Personalized Chart",
    "Finalizing Recommendation"
  ];

  int _phraseIndex = 0;
  Timer? _phraseTimer;

  List<Map<String, String>> dietPlans = [];
  String results = '';
  // NOTE: Changed _isLoading to false initially and updated the finally block logic
  bool _isLoading = false;

  // --- WIRING PRESERVED: FETCH LOGIC INTACT ---
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final startTime = DateTime.now();

      setState(() {
        _isLoading = true;
        _phraseIndex = 0; // Reset index for new submission
        // Start the phrase timer immediately when loading starts
        _phraseTimer = Timer.periodic(Duration(milliseconds: 600), (_) {
          if (!_isLoading) return;
          setState(() {
            _phraseIndex = (_phraseIndex + 1) % aiPhrases.length;
          });
        });
      });

      var data = {
        'Gender': genderController.text,
        'Obicity': obesityController.text,
        'Alcoholabuse': alcoholAbuseController.text,
        'Druguse': drugUseController.text,
        'Smoking': smokingController.text,
        'Headaches': headachesController.text,
        'Asthma': asthmaController.text,
        'Cancer': cancerController.text,
        'Stroke': strokeController.text,
        'Kidney': kidneyController.text,
        'Liver': liverController.text,
        'Depression': depressionController.text,
        'Allergies': allergiesController.text,
        'Arthritis': arthritisController.text,
        'Pregnancy': pregnancyController.text,
        'BMI': bmiController.text,
        'BloodPressure': bloodPressureController.text,
      };

      try {
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
        String baseUrl = sharedPreferences.getString('url') ?? '';
        print("📌 API URL = $baseUrl/predict_diet");
        print("📌 REQUEST BODY = $data");

        final response = await http.post(
          Uri.parse('$baseUrl/predict_diet'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data),
        );

        print("📌 RAW RESPONSE = ${response.body}");
        print("📌 STATUS CODE = ${response.statusCode}");

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          print("📌 PARSED RESPONSE = $jsonResponse");

          List<dynamic> diets = jsonResponse['dietPlans'] ?? [];
          String resultText = jsonResponse['result'] ?? '';

          setState(() {
            results = resultText;
            dietPlans = diets.map<Map<String, String>>((diet) {
              final name = diet['name']?.toString() ?? 'Unknown';
              final plan = diet['dietplan']?.toString() ?? '';
              // NOTE: Preserving the core link construction logic
              final link = plan.isNotEmpty ? baseUrl + plan : '';

              return {
                'dietName': name,
                'dietPlan': plan,
                'dietlink': link,
              };
            }).toList();
          });

        } else {
          print("❌ Server returned error. BODY: ${response.body}");
          print("❌ STATUS CODE: ${response.statusCode}");
          throw Exception('Failed to load diet plans');
        }
      } catch (e) {
        print("🔥 ERROR: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: Unable to fetch data'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // --- LOADING & TIMER LOGIC PRESERVED ---
        _phraseTimer?.cancel();

        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        const minLoading = 3000; // Minimum 3 seconds for better UX

        if (elapsed < minLoading) {
          await Future.delayed(Duration(milliseconds: minLoading - elapsed));
        }

        setState(() {
          _isLoading = false;
        });

        // Auto-scroll to results section after loading is complete
        await Future.delayed(Duration(milliseconds: 300));
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  // --- WIRING PRESERVED: YES/NO FIELD LOGIC INTACT ---
  Widget _buildYesNoField(String label, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Color(0xFF555555), fontSize: 13, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50).withOpacity(0.7), size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: ['Yes', 'No']
            .map((option) => DropdownMenuItem<String>(
          value: option,
          child: Text(option, style: TextStyle(fontSize: 14, color: option == 'Yes' ? Color(0xFF4CAF50) : Color(0xFFE57373))),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            controller.text = value!;
          });
        },
        validator: (value) =>
        value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  // --- WIRING PRESERVED: DOWNLOAD LOGIC INTACT ---
  Future<void> _generateAndDownloadPDF() async {
    try {
      if (dietPlans.isEmpty && results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No data available to export."),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Generate content
      StringBuffer pdfContent = StringBuffer();
      pdfContent.writeln("AI Health Prediction Report");
      pdfContent.writeln("------------------------------");
      pdfContent.writeln("Prediction Result: $results\n");

      for (var plan in dietPlans) {
        pdfContent.writeln("Diet Name: ${plan['dietName']}");
        pdfContent.writeln("Plan: ${plan['dietPlan']}");
        pdfContent.writeln("Link: ${plan['dietlink']}");
        pdfContent.writeln("\n");
      }

      // Create a path to save the file
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = p.join(directory.path, "Diet_Report_${DateTime.now().millisecondsSinceEpoch}.txt");
      final file = File(filePath);
      await file.writeAsString(pdfContent.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Report saved to Download folder."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error creating PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to save report. Please check app permissions."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Define the color palette for the improved UI
    const Color primaryColor = Color(0xFF039BE5); // Deep Sky Blue
    const Color accentColor = Color(0xFF4CAF50); // Green for success/link

    return Scaffold(
      backgroundColor: Color(0xFFF0F2F5), // Light grey background
      appBar: AppBar(
        title: Text(
          'AI Health Guidance',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Color(0xFF00C8F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            children: [
              // === 1. HEADER SECTION (Card Look) ===
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.monitor_heart, color: primaryColor, size: 28),
                        SizedBox(width: 12),
                        Text(
                          'AI Prediction Engine',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Input your metrics to generate a precise, personalized health and diet chart.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // === 2. CORE METRICS SECTION ===
              _buildSectionTitle('Primary Health Metrics', Icons.insights),
              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Gender Dropdown
                    _buildCustomDropdownField(
                      'Gender',
                      genderController,
                      ['Male', 'Female', 'Other'],
                      Icons.person_outline,
                    ),
                    SizedBox(height: 16),

                    // BMI Input
                    _buildCustomTextField(
                      'BMI (Body Mass Index)',
                      bmiController,
                      Icons.accessibility_new,
                      TextInputType.number,
                    ),
                    SizedBox(height: 16),

                    // Blood Pressure Dropdown
                    _buildCustomDropdownField(
                      'Blood Pressure Level',
                      bloodPressureController,
                      ['Low', 'Medium', 'High'],
                      Icons.favorite_border,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // === 3. HEALTH CONDITIONS SECTION ===
              _buildSectionTitle('Existing Medical History', Icons.medical_services_outlined),
              SizedBox(height: 16),

              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(width: 150, child: _buildYesNoField('Obesity', obesityController)),
                    SizedBox(width: 150, child: _buildYesNoField('Alcohol', alcoholAbuseController)),
                    SizedBox(width: 150, child: _buildYesNoField('Smoking', smokingController)),
                    SizedBox(width: 150, child: _buildYesNoField('Drug Use', drugUseController)),
                    SizedBox(width: 150, child: _buildYesNoField('Headaches', headachesController)),
                    SizedBox(width: 150, child: _buildYesNoField('Asthma', asthmaController)),
                    SizedBox(width: 150, child: _buildYesNoField('Cancer', cancerController)),
                    SizedBox(width: 150, child: _buildYesNoField('Stroke', strokeController)),
                    SizedBox(width: 150, child: _buildYesNoField('Kidney Issues', kidneyController)),
                    SizedBox(width: 150, child: _buildYesNoField('Liver Issues', liverController)),
                    SizedBox(width: 150, child: _buildYesNoField('Depression', depressionController)),
                    SizedBox(width: 150, child: _buildYesNoField('Allergies', allergiesController)),
                    SizedBox(width: 150, child: _buildYesNoField('Arthritis', arthritisController)),
                    SizedBox(width: 150, child: _buildYesNoField('Pregnancy', pregnancyController)),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // === 4. PREDICT BUTTON ===
              Container(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        aiPhrases[_phraseIndex],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.smart_toy_outlined, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Generate Personalized Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // === 5. RESULTS SECTION ===
              if (results.isNotEmpty || dietPlans.isNotEmpty)
                _buildResultsSection(primaryColor, accentColor),

              // === 6. SAVE REPORT BUTTON ===
              if (dietPlans.isNotEmpty || results.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _generateAndDownloadPDF,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: Icon(Icons.download_rounded, color: Colors.white),
                      label: Text(
                        "Download AI Report (.txt)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF2C3E50), size: 20),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      TextInputType keyboardType,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(icon, color: Color(0xFF039BE5).withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        keyboardType: keyboardType,
        validator: (value) =>
        value == null || value.isEmpty ? 'Required field' : null,
      ),
    );
  }

  Widget _buildCustomDropdownField(
      String label,
      TextEditingController controller,
      List<String> options,
      IconData icon,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          prefixIcon: Icon(icon, color: Color(0xFF039BE5).withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: options
            .map((option) => DropdownMenuItem<String>(
          value: option,
          child: Text(option, style: TextStyle(fontSize: 14)),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            controller.text = value!;
          });
        },
        validator: (value) =>
        value == null || value.isEmpty ? 'Please select an option' : null,
      ),
    );
  }

  Widget _buildResultsSection(Color primaryColor, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_border, color: primaryColor, size: 24),
              SizedBox(width: 8),
              Text(
                'AI Prediction Report',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          Divider(height: 25, thickness: 1, color: Colors.grey.shade200),

          if (results.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnosis Summary:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E9), // Light green background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    results,
                    style: TextStyle(
                      fontSize: 14,
                      color: accentColor.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),

          if (dietPlans.isNotEmpty) ...[
            Text(
              'Recommended Diet Plans:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: dietPlans.length,
              itemBuilder: (context, index) {
                final diet = dietPlans[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Card(
                    margin: EdgeInsets.zero,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade100)
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.food_bank, color: primaryColor, size: 24),
                      ),
                      title: Text(
                        diet['dietName'] ?? 'No Name',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      subtitle: Text(
                        'Plan: ${diet['dietPlan'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.open_in_new, color: accentColor),
                        onPressed: () async {
                          final url = diet['dietlink'] ?? '';
                          if (await canLaunch(url)) {
                            await launch(url);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not open link'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}