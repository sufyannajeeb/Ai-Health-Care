import 'dart:convert';
import 'package:ai_doctor_app/userhome.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() {
  runApp(const com());
}

class com extends StatelessWidget {
  const com({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Send Feedback',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const feedback(title: 'Review Expert'),
    );
  }
}

class feedback extends StatefulWidget {
  const feedback({super.key, required this.title});

  final String title;

  @override
  State<feedback> createState() => _feedbackState();
}

class _feedbackState extends State<feedback> {
  TextEditingController feedbackaintcontroller = TextEditingController();
  double _rating = 0;
  final _formkey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('Expert Feedback'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formkey,
              child: Column(
                children: [

                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.rate_review, color: Colors.white, size: 40),
                        SizedBox(height: 8),
                        Text(
                          "Share Your Experience",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Your feedback helps improve service quality",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Review Text Box
                  TextFormField(
                    maxLines: 5,
                    controller: feedbackaintcontroller,
                    decoration: InputDecoration(
                      labelText: "Write your review",
                      alignLabelWithHint: true,
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.comment, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    validator: (value) =>
                    value == null || value.isEmpty ? "Please enter feedback." : null,
                  ),

                  const SizedBox(height: 20),

                  // Rating Bar
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    itemCount: 5,
                    allowHalfRating: true,
                    itemSize: 45,
                    unratedColor: Colors.grey.shade300,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4),
                    itemBuilder: (context, _) =>
                    const Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),

                  const SizedBox(height: 30),

                  // Send Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        if (_formkey.currentState!.validate()) {
                          sendfeedbackiant();
                        }
                      },
                      child: const Text(
                        "Send Feedback",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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

  void sendfeedbackiant() async {
    String feedbackiant = feedbackaintcontroller.text.trim();

    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();
    String lid = sh.getString('lid').toString();
    String rid = sh.getString('eid').toString();
    final urls = Uri.parse(url + "/send_feedback");

    try {
      final response = await http.post(urls, body: {
        'feedback': feedbackiant,
        'rating': _rating.toString(),
        'lid': lid,
        'eid': rid,
      });

      if (response.statusCode == 200) {
        String status = jsonDecode(response.body)['status'];
        if (status == 'ok') {
          Fluttertoast.showToast(msg: 'Feedback Sent');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DietHome()),
          );
        } else {
          Fluttertoast.showToast(msg: 'Unable to submit');
        }
      } else {
        Fluttertoast.showToast(msg: 'Network Issue');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }
}
