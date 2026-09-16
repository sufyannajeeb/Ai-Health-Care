import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ViewDietChartsPage extends StatefulWidget {
  const ViewDietChartsPage({Key? key}) : super(key: key);

  @override
  State<ViewDietChartsPage> createState() => _ViewDietChartsPageState();
}

class _ViewDietChartsPageState extends State<ViewDietChartsPage> {
  List<dynamic> dietCharts = [];

  @override
  void initState() {
    super.initState();
    fetchDietCharts();
  }
  String result="";
  Future<void> fetchDietCharts() async {
    try {
      final pref = await SharedPreferences.getInstance();
      String? lid = pref.getString("lid");

      if (lid == null) {
        Fluttertoast.showToast(msg: "No session found. Please log in again.");
        return;
      }


      String url = "${pref.getString("url") ?? ''}/view_diet_charts";
      var response = await http.post(
        Uri.parse(url),
        body: {'lid': lid},
      );

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        String status = jsonData['status'];

        if (status == 'ok') {
          setState(() {
            dietCharts = jsonData['data'];
            result = jsonData['result'];
          });
          Fluttertoast.showToast(msg: "Sccessfull");
        } else {
          Fluttertoast.showToast(msg: "Error: ${jsonData['message']}");
        }
      } else {
        Fluttertoast.showToast(msg: "Failed to load diet charts. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching diet charts: $e");
      Fluttertoast.showToast(msg: "An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diet Charts"),
        centerTitle: true,
        backgroundColor: Colors.teal,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body:
        Text(result.toString())
      // dietCharts.isEmpty
      //     ? const Center(
      //   child: Text(
      //     "No diet charts found.",
      //     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      //   ),
      // )
      //     : ListView.builder(
      //   itemCount: dietCharts.length,
      //   itemBuilder: (BuildContext context, int index) {
      //     return Card(
      //       margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      //       elevation: 4,
      //       shape: RoundedRectangleBorder(
      //         borderRadius: BorderRadius.circular(12),
      //       ),
      //       child: Padding(
      //         padding: const EdgeInsets.all(16),
      //         child: Column(
      //           crossAxisAlignment: CrossAxisAlignment.start,
      //           children: [
      //             Text(
      //               "Name: ${dietCharts[index]['name'].toString()}",
      //               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "Date: ${dietCharts[index]['date'].toString()}",
      //               style: const TextStyle(fontSize: 14),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "Time: ${dietCharts[index]['time'].toString()}",
      //               style: const TextStyle(fontSize: 14),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "Diet Plan: ${dietCharts[index]['dietplan'].toString()}",
      //               style: const TextStyle(fontSize: 14),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "Gender: ${dietCharts[index]['gender'].toString()}",
      //               style: const TextStyle(fontSize: 14),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "Obesity: ${dietCharts[index]['obicity'].toString()}",
      //               style: const TextStyle(fontSize: 14),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "Blood Pressure: ${dietCharts[index]['bloodpressure'].toString()}",
      //               style: const TextStyle(fontSize: 14),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "Diabetes: ${dietCharts[index]['diabetes'].toString()}",
      //               style: const TextStyle(fontSize: 14),
      //             ),
      //             const SizedBox(height: 8),
      //             Text(
      //               "Cholesterol: ${dietCharts[index]['cholestrol'].toString()}",
      //               style: const TextStyle(fontSize: 14),
      //             ),
      //             // Add more fields as necessary
      //           ],
      //         ),
      //       ),
      //     );
      //   },
      // ),
    );
  }
}
