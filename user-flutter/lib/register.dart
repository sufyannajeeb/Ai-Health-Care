import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'logins.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  TextEditingController firstnameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController placeController = TextEditingController();
  TextEditingController districtController = TextEditingController();
  TextEditingController pinController = TextEditingController();
  TextEditingController postController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController bloodtypeController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  XFile? _image;

  _imgFromCamera() async {
    XFile? image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
    );
    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  _imgFromGallery() async {
    XFile? image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  void _showPicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Wrap(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library, color: Colors.blue.shade600),
                  title: Text('Photo Library', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    _imgFromGallery();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera, color: Colors.blue.shade600),
                  title: Text('Camera', style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    _imgFromCamera();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialDate)
      setState(() {
        dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
  }

  Future<void> _registerUser() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a profile photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final sh = await SharedPreferences.getInstance();
    String url = sh.getString("url").toString();
    print(url);

    try {
      var uri = Uri.parse(url + '/user_reg');
      var request = http.MultipartRequest('POST', uri);

      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      request.fields['name'] = firstnameController.text;
      request.fields['email'] = emailController.text;
      request.fields['gender'] = genderController.text;
      request.fields['phone'] = phoneNumberController.text;
      request.fields['password'] = passwordController.text;
      request.fields['dob'] = dobController.text;
      request.fields['place'] = placeController.text;
      request.fields['district'] = districtController.text;
      request.fields['pin'] = pinController.text;
      request.fields['post'] = postController.text;
      request.fields['bloodtype'] = bloodtypeController.text;

      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully Registered with Ai Doctor'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Ftnesslogin()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Patient Registration",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_add, size: 40, color: Colors.blue.shade700),
                  SizedBox(height: 10),
                  Text(
                    'Join Ai Doctor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Create your medical profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Profile Photo Section
            Center(
              child: Column(
                children: [
                  Text(
                    'Profile Photo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      _showPicker(context);
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.blue.shade300,
                          width: 3,
                        ),
                      ),
                      child: _image != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.file(
                          File(_image!.path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.blue.shade400,
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Personal Information Section
            _buildSectionTitle('Personal Information'),
            SizedBox(height: 20),

            // Form Fields in a Grid Layout
            Column(
              children: [
                _buildTextFieldRow([
                  _buildTextField(
                    controller: firstnameController,
                    label: "Full Name",
                    icon: Icons.person_outline,
                    isHalf: true,
                  ),
                  _buildTextField(
                    controller: emailController,
                    label: "Email",
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    isHalf: true,
                  ),
                ]),
                SizedBox(height: 16),
                _buildTextFieldRow([
                  _buildTextField(
                    controller: phoneNumberController,
                    label: "Phone Number",
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    isHalf: true,
                  ),
                  _buildTextField(
                    controller: genderController,
                    label: "Gender",
                    icon: Icons.transgender,
                    isHalf: true,
                  ),
                ]),
                SizedBox(height: 16),
                _buildTextField(
                  controller: bloodtypeController,
                  label: "Blood Type",
                  icon: Icons.bloodtype,
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    _selectDate(context);
                  },
                  child: AbsorbPointer(
                    child: _buildTextField(
                      controller: dobController,
                      label: "Date of Birth",
                      icon: Icons.calendar_today,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildTextField(
                  controller: passwordController,
                  label: "Password",
                  icon: Icons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                        color: Colors.grey.shade600),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                SizedBox(height: 30),

                _buildSectionTitle('Address Information'),
                SizedBox(height: 20),

                _buildTextField(
                  controller: placeController,
                  label: "Place",
                  icon: Icons.place,
                ),
                SizedBox(height: 16),
                _buildTextFieldRow([
                  _buildTextField(
                    controller: districtController,
                    label: "District",
                    icon: Icons.location_city,
                    isHalf: true,
                  ),
                  _buildTextField(
                    controller: pinController,
                    label: "PIN Code",
                    icon: Icons.pin,
                    keyboardType: TextInputType.number,
                    isHalf: true,
                  ),
                ]),
                SizedBox(height: 16),
                _buildTextField(
                  controller: postController,
                  label: "Post Office",
                  icon: Icons.local_post_office,
                ),
              ],
            ),

            SizedBox(height: 40),

            // Register Button
            Container(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Creating Account...',
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
                    Icon(Icons.person_add_alt_1, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Create Medical Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue.shade800,
      ),
    );
  }

  Widget _buildTextFieldRow(List<Widget> children) {
    return Row(
      children: [
        Expanded(child: children[0]),
        SizedBox(width: 16),
        Expanded(child: children[1]),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    bool isHalf = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Container(
            padding: EdgeInsets.all(12),
            child: Icon(icon, color: Colors.blue.shade600),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}