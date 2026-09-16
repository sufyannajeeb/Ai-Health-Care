import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';
import 'userhome.dart';

// NOTE: No void main() here — this file is a page widget, not an entry point.
// Entry point is lib/ip.dart (or your main.dart).

class AddFoods extends StatefulWidget {
  const AddFoods({super.key, required this.title});
  final String title;

  @override
  State<AddFoods> createState() => _AddFoodsState();
}

class _AddFoodsState extends State<AddFoods>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gramController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _selectedType;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> _foodTypes = [
    {'label': 'Fruits',                     'icon': '🍎'},
    {'label': 'Vegetables',                 'icon': '🥦'},
    {'label': 'Grains and Legumes',         'icon': '🌾'},
    {'label': 'Dairy',                      'icon': '🥛'},
    {'label': 'Egg, Meats and Fish',        'icon': '🥩'},
    {'label': 'Indian Dishes',              'icon': '🍛'},
    {'label': 'Chinese Dishes',             'icon': '🍜'},
    {'label': 'Italian Dishes',             'icon': '🍝'},
    {'label': 'Arabian Dishes',             'icon': '🫕'},
    {'label': 'Mexican Dishes',             'icon': '🌮'},
    {'label': 'Middle Eastern Dishes',      'icon': '🧆'},
    {'label': 'Other International Dishes', 'icon': '🍽️'},
    {'label': 'Nuts and Seeds',             'icon': '🥜'},
  ];

  @override
  void initState() {
    super.initState();
    _dateController.text =
    DateTime.now().toLocal().toString().split(' ')[0];

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _gramController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppTheme.primary,
            onPrimary: Colors.white,
            surface: AppTheme.cardWhite,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateController.text =
        picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  Future<void> _submitFood() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      final String? baseUrl = sh.getString('url');
      final String? lid = sh.getString('lid');

      if (baseUrl == null || baseUrl.trim().isEmpty) {
        _showError('Server URL not configured. Please login again.');
        return;
      }
      if (lid == null || lid.trim().isEmpty) {
        _showError('Session expired. Please login again.');
        return;
      }

      final String cleanUrl =
      baseUrl.endsWith('/') ? baseUrl.trimRight() : baseUrl;
      final Uri uri = Uri.parse('$cleanUrl/user_add_food');

      final response = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'lid': lid,
          'name': _nameController.text.trim(),
          'gram': _gramController.text.trim(),
          'type': _selectedType ?? '',
          'date': _dateController.text.trim(),
        },
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonBody = jsonDecode(response.body);
        final String status = jsonBody['status']?.toString() ?? '';
        if (status == 'ok') {
          Fluttertoast.showToast(
            msg: '✅ Food added successfully!',
            backgroundColor: AppTheme.primary,
            textColor: Colors.white,
            toastLength: Toast.LENGTH_SHORT,
          );
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DietHome()),
            );
          }
        } else {
          _showError(
              jsonBody['message']?.toString() ?? 'Failed to add. Try again.');
        }
      } else {
        _showError('Server error (${response.statusCode}). Please try again.');
      }
    } on http.ClientException catch (e) {
      _showError('Network error: ${e.message}');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        _showError('Connection timed out. Check your internet.');
      } else if (e.toString().contains('SocketException')) {
        _showError('No internet connection.');
      } else if (e.toString().contains('FormatException')) {
        _showError('Invalid server response. Contact support.');
      } else {
        _showError('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) setState(() => _isLoading = false);
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: AppTheme.errorClr,
      textColor: Colors.white,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DietHome()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgPage,
        body: CustomScrollView(
          slivers: [
            // ── App Bar ──
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              backgroundColor: AppTheme.primary,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => DietHome()),
                ),
              ),
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
                                    Icons.restaurant_menu_rounded,
                                    color: Colors.white,
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Log Food',
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
                            'Track what you eat today',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Form ──
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(label: 'Food Details'),
                          const SizedBox(height: 12),

                          // Food Name
                          _FieldCard(
                            child: TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              textCapitalization:
                              TextCapitalization.sentences,
                              style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              decoration: _buildDecoration(
                                label: 'Food Name',
                                hint: 'e.g. Grilled Chicken',
                                icon: Icons.lunch_dining_rounded,
                              ),
                              validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter a food name'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Food Type
                          _FieldCard(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.primary),
                              dropdownColor: AppTheme.cardWhite,
                              style: const TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600),
                              decoration: _buildDecoration(
                                label: 'Food Category',
                                hint: 'Select a category',
                                icon: Icons.category_rounded,
                              ),
                              validator: (v) =>
                              (v == null || v.isEmpty)
                                  ? 'Please select a category'
                                  : null,
                              onChanged: (val) =>
                                  setState(() => _selectedType = val),
                              items: _foodTypes
                                  .map((t) => DropdownMenuItem<String>(
                                value: t['label'] as String,
                                child: Row(
                                  children: [
                                    Text(t['icon'] as String,
                                        style: const TextStyle(
                                            fontSize: 18)),
                                    const SizedBox(width: 10),
                                    Text(t['label'] as String,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color:
                                            AppTheme.textDark)),
                                  ],
                                ),
                              ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          const _SectionLabel(label: 'Quantity & Date'),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _FieldCard(
                                  child: TextFormField(
                                    controller: _gramController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .digitsOnly
                                    ],
                                    style: const TextStyle(
                                        color: AppTheme.textDark,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                    decoration: _buildDecoration(
                                      label: 'Grams (g)',
                                      hint: '0',
                                      icon: Icons.scale_rounded,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty)
                                        return 'Required';
                                      if (int.tryParse(v) == null)
                                        return 'Numbers only';
                                      if (int.parse(v) <= 0)
                                        return 'Must be > 0';
                                      return null;
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _FieldCard(
                                  child: TextFormField(
                                    controller: _dateController,
                                    readOnly: true,
                                    onTap: _selectDate,
                                    style: const TextStyle(
                                        color: AppTheme.textDark,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                    decoration: _buildDecoration(
                                      label: 'Date',
                                      hint: 'YYYY-MM-DD',
                                      icon: Icons.calendar_today_rounded,
                                    ),
                                    validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                              _isLoading ? null : _submitFood,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                disabledBackgroundColor:
                                AppTheme.primary.withOpacity(0.5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                                  : const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      Icons
                                          .add_circle_outline_rounded,
                                      size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add to Food Log',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Cancel
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DietHome()),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textMid,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
          color: AppTheme.textMid,
          fontSize: 13,
          fontWeight: FontWeight.w600),
      hintStyle:
      const TextStyle(color: AppTheme.textLight, fontSize: 14),
      prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      errorStyle: const TextStyle(
          color: AppTheme.errorClr,
          fontSize: 11,
          fontWeight: FontWeight.w500),
    );
  }
}

// ── Section Label ──
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Field Card ──
class _FieldCard extends StatelessWidget {
  final Widget child;
  const _FieldCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderClr, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}