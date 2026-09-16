import 'package:ai_doctor_app/userchat.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final String expertId;
  final int amount; // in rupees

  const PaymentPage({super.key, required this.expertId, required this.amount});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Razorpay? _razorpay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    // Razorpay callbacks
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay!.clear();
    super.dispose();
  }

  _startPayment() async {
    setState(() => _isLoading = true);

    SharedPreferences sh = await SharedPreferences.getInstance();
    final baseUrl = sh.getString('url')!;
    final userId = sh.getString('lid')!;

    // 1️⃣ Create order from backend
    final res = await http.post(
      Uri.parse("$baseUrl/create_order"),
      body: {
        "user_id": userId,
        "expert_id": widget.expertId,
      },
    );

    final data = json.decode(res.body);

    if (data["status"] == "error") {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data["message"])),
      );
      return;
    }

    final orderId = data["order_id"];
    final key = data["key"];
    final amountPaise = data["amount"];

    // Razorpay checkout params
    var options = {
      "key": key,
      "amount": amountPaise,
      "name": "Ai Doctor Consultation",
      "description": "Chat access with doctor",
      "order_id": orderId,
      "timeout": 300,
      "prefill": {
        "email": sh.getString("email") ?? "",
        "contact": sh.getString("phone") ?? "",
      }
    };

    setState(() => _isLoading = false);

    // Open Razorpay UI
    _razorpay!.open(options);
  }

  // ====================== CALLBACKS ================================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    final baseUrl = sh.getString('url')!;

    final verifyRes = await http.post(
      Uri.parse("$baseUrl/verify_payment"),
      body: {
        "order_id": response.orderId,
        "payment_id": response.paymentId,
        "signature": response.signature
      },
    );

    final jsonResp = json.decode(verifyRes.body);

    if (jsonResp["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful! Chat Unlocked")),
      );

      // Save expiry time returned from backend
      final expiresAt = jsonResp["expires_at"];
      if (expiresAt != null) {
        await sh.setString("chat_expiry", expiresAt);
        print("🔥 Saved chat_expiry = $expiresAt");
      } else {
        print("⚠️ verify_payment didn't return expires_at");
      }

      // Save expert id for chat
      await sh.setString("clid", widget.expertId);
      await sh.setString("chatname", "Doctor");

      // Redirect to chat
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyChatPage(title: 'Chat')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(jsonResp["message"])),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Failed. Try again.")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
    );
  }

  // ====================== UI ================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment"),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Icon(Icons.medical_services_rounded,
                size: 90, color: Colors.blue.shade700),

            const SizedBox(height: 20),

            Text(
              "Doctor Consultation Access",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            Text(
              "Unlock 24-hour chat access with your selected doctor.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            _paymentTile("Expert ID", widget.expertId),
            _paymentTile("Access Duration", "24 Hours"),
            _paymentTile("Amount", "₹ ${widget.amount}"),

            const Spacer(),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 30),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Proceed to Pay",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  color: Colors.blue.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          Text(value,
              style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ],
      ),
    );
  }
}
