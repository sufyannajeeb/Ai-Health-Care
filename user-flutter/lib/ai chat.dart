import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const dietsiggestionchat(title: 'Flutter Demo Home Page'),
    );
  }
}

class dietsiggestionchat extends StatefulWidget {
  const dietsiggestionchat({super.key, required this.title});



  final String title;

  @override
  State<dietsiggestionchat> createState() => _dietsiggestionchatState();
}

class _dietsiggestionchatState extends State<dietsiggestionchat> {

  TextEditingController chatcontroller = new TextEditingController();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(

        child: Column(


          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[


            TextField( controller: chatcontroller,decoration: InputDecoration(
              border: OutlineInputBorder(),label: Text("Response")),),

            SizedBox(height: 20,),

          ElevatedButton(onPressed: (){}, child: Text("Submit"))



          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }


  void senddata() async {
    String chat = chatcontroller.text;


    SharedPreferences sh = await SharedPreferences.getInstance();
    String url = sh.getString('url').toString();
    final urls = Uri.parse(url + "/flutter_login");

    try {
      final response = await http.post(urls, body: {
        'chat': chat,

      });

      if (response.statusCode == 200) {
        String status = jsonDecode(response.body)['status'];
        if (status == 'ok') {
          Fluttertoast.showToast(msg: 'Success');
          String type = jsonDecode(response.body)['type'];
          String lid = jsonDecode(response.body)['lid'].toString();
          sh.setString("lid", lid);

          if (type == 'user') {

          }
        } else {
          Fluttertoast.showToast(msg: 'Invalid username or password');
        }
      } else {
        Fluttertoast.showToast(msg: 'Network Error');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

}
