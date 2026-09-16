import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryColor = Color(0xFF1E88E5);
const Color kOnlineColor  = Color(0xFF43A047);

class ChatMessage {
  final String messageContent;
  final String messageType;
  final bool   isImage;
  const ChatMessage({
    required this.messageContent,
    required this.messageType,
    this.isImage = false,
  });
}

class MyChatPage extends StatefulWidget {
  const MyChatPage({super.key, required this.title});
  final String title;
  @override
  State<MyChatPage> createState() => _MyChatPageState();
}

class _MyChatPageState extends State<MyChatPage> {
  Timer?                      _chatUpdateTimer;
  List<ChatMessage>           messages = [];
  final TextEditingController _teMessage        = TextEditingController();
  final ScrollController      _scrollController = ScrollController();
  final ImagePicker           _picker           = ImagePicker();
  bool _isSending  = false;
  bool _isFetching = false;

  String _doctorName      = "Doctor";
  String _doctorImageUrl  = "";
  String _doctorSpecialty = "";
  String _expertId        = "";
  String _userId          = "";
  String _baseUrl         = "";

  Duration? timeLeft;
  Timer?    expiryTimer;
  bool      isExpired = false;

  @override
  void initState() {
    super.initState();
    _loadDoctorInfo();
    _loadExpiryTime();
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewMessage());
    _chatUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && !_isFetching && !isExpired) _viewMessage();
    });
  }

  @override
  void dispose() {
    _chatUpdateTimer?.cancel();
    expiryTimer?.cancel();
    _teMessage.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorInfo() async {
    final pref     = await SharedPreferences.getInstance();
    final userId   = pref.getString("lid")  ?? "";
    final expertId = pref.getString("clid") ?? "";
    final base     = pref.getString("url")  ?? "";
    setState(() {
      _userId          = userId;
      _expertId        = expertId;
      _baseUrl         = base;
      _doctorName      = pref.getString("chatname")      ?? "Doctor";
      _doctorImageUrl  = pref.getString("chatimage")     ?? "";
      _doctorSpecialty = pref.getString("chatspecialty") ?? "";
    });
  }

  String _buildRoomName(String expertId, String userId) =>
      "AiDoctorExpert${expertId}User${userId}";

  void _startVideoCall() {
    // Video call feature removed
  }

  Future<void> _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _viewMessage() async {
    _isFetching = true;
    try {
      final pref   = await SharedPreferences.getInstance();
      final base   = pref.getString('url')  ?? '';
      final fromId = pref.getString("lid")  ?? '';
      final toId   = pref.getString("clid") ?? '';
      if (base.isEmpty || fromId.isEmpty || toId.isEmpty) return;

      final res = await http
          .post(Uri.parse('$base/user_viewchat'),
          body: {'from_id': fromId, 'to_id': toId})
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return;
      final body = res.body.trim();
      if (body.startsWith('<')) return;

      final jsondata = json.decode(body) as Map<String, dynamic>;
      if (jsondata['status'] != "success") return;

      final arr     = jsondata["data"] as List<dynamic>? ?? [];
      final newMsgs = <ChatMessage>[];
      for (final item in arr) {
        final from    = (item['from_id'] ?? item['from'] ?? '').toString();
        final msg     = (item['msg']     ?? item['message'] ?? '').toString();
        final isImage = (item['msg_type'] ?? 'text').toString() == 'image';
        String content = msg;
        if (isImage && msg.isNotEmpty && !msg.startsWith('http')) {
          content = base.endsWith('/')
              ? '${base.substring(0, base.length - 1)}$msg'
              : '$base$msg';
        }
        newMsgs.add(ChatMessage(
          messageContent: content,
          messageType: (from == fromId) ? "sender" : "receiver",
          isImage: isImage,
        ));
      }
      setState(() => messages = newMsgs);
      await _scrollToBottom();
    } catch (e) {
      debugPrint("_viewMessage error: $e");
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _sendMessage() async {
    final text = _teMessage.text.trim();
    if (text.isEmpty || _isSending) return;
    if (_checkExpired()) return;
    setState(() => _isSending = true);
    try {
      final pref   = await SharedPreferences.getInstance();
      final base   = pref.getString('url')  ?? '';
      final fromId = pref.getString("lid")  ?? '';
      final toId   = pref.getString("clid") ?? '';
      if (base.isEmpty || fromId.isEmpty || toId.isEmpty) return;

      final res = await http.post(
        Uri.parse("$base/user_sendchat"),
        body: {'message': text, 'from_id': fromId, 'to_id': toId},
      ).timeout(const Duration(seconds: 10));

      final body = res.body.trim();
      if (body.startsWith('<')) return;
      final jsondata = json.decode(body) as Map<String, dynamic>;
      if (jsondata['status'] == "success") {
        _teMessage.clear();
        await _viewMessage();
      } else {
        _showSnack(jsondata['message'] ?? 'Send failed');
      }
    } catch (e) {
      _showSnack("Network error while sending");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_checkExpired()) return;
    final XFile? picked = await _picker.pickImage(
        source: source, imageQuality: 70, maxWidth: 1280);
    if (picked == null) return;
    setState(() => _isSending = true);
    try {
      final pref   = await SharedPreferences.getInstance();
      final base   = pref.getString('url')  ?? '';
      final fromId = pref.getString("lid")  ?? '';
      final toId   = pref.getString("clid") ?? '';
      if (base.isEmpty || fromId.isEmpty || toId.isEmpty) return;

      final request =
      http.MultipartRequest('POST', Uri.parse("$base/user_sendchat_image"));
      request.fields['from_id']  = fromId;
      request.fields['to_id']    = toId;
      request.fields['msg_type'] = 'image';
      request.files.add(await http.MultipartFile.fromPath('image', picked.path));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final res      = await http.Response.fromStream(streamed);
      final body     = res.body.trim();
      if (body.startsWith('<')) { _showSnack("Server error"); return; }
      final jsondata = json.decode(body) as Map<String, dynamic>;
      if (jsondata['status'] == "success") {
        await _viewMessage();
      } else {
        _showSnack(jsondata['message'] ?? 'Image send failed');
      }
    } catch (e) {
      _showSnack("Failed to send image");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4))),
            const Text("Send Image",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: CircleAvatar(backgroundColor: kPrimaryColor.withOpacity(0.1),
                  child: const Icon(Icons.camera_alt, color: kPrimaryColor)),
              title: const Text("Take a photo"),
              onTap: () { Navigator.pop(context); _pickAndSendImage(ImageSource.camera); },
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.purple.withOpacity(0.1),
                  child: const Icon(Icons.photo_library, color: Colors.purple)),
              title: const Text("Choose from gallery"),
              onTap: () { Navigator.pop(context); _pickAndSendImage(ImageSource.gallery); },
            ),
          ]),
        ),
      ),
    );
  }

  bool _checkExpired() {
    if (isExpired) { _showSnack("Chat expired. Please purchase again."); return true; }
    return false;
  }

  Future<void> _loadExpiryTime() async {
    final pref = await SharedPreferences.getInstance();
    final str  = pref.getString("chat_expiry");
    if (str == null) return;
    DateTime expiry;
    try { expiry = DateTime.parse(str); } catch (_) { return; }
    expiryTimer?.cancel();
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) {
      setState(() { isExpired = true; timeLeft = Duration.zero; }); return;
    }
    setState(() { isExpired = false; timeLeft = diff; });
    expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final d = expiry.difference(DateTime.now());
      if (d.isNegative) {
        if (mounted) setState(() { isExpired = true; timeLeft = Duration.zero; });
        expiryTimer?.cancel(); _chatUpdateTimer?.cancel(); return;
      }
      if (mounted) setState(() => timeLeft = d);
    });
  }

  String _formatDuration(Duration d) {
    if (d.inSeconds <= 0) return "Expired";
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)} left";
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _doctorAvatar({double radius = 22}) {
    final size = radius * 2;
    final url  = _doctorImageUrl.trim();
    return SizedBox(width: size, height: size,
      child: Stack(children: [
        Container(width: size, height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.shade100),
            child: Icon(Icons.person, color: kPrimaryColor, size: radius * 0.85)),
        if (url.isNotEmpty)
          ClipOval(child: Image.network(url, width: size, height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink())),
      ]),
    );
  }

  Widget _messageBubble(ChatMessage msg) {
    final isSender = msg.messageType == "sender";
    Widget content;
    if (msg.isImage && msg.messageContent.isNotEmpty) {
      content = ClipRRect(borderRadius: BorderRadius.circular(12),
        child: Image.network(msg.messageContent, width: 200, height: 200,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, prog) {
            if (prog == null) return child;
            return Container(width: 200, height: 200, color: Colors.grey.shade200,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
          },
          errorBuilder: (_, __, ___) => Container(width: 200, height: 60,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.broken_image, color: Colors.grey))),
        ),
      );
    } else {
      content = Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 15),
        decoration: BoxDecoration(
          color: isSender ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(18),
            topRight:    const Radius.circular(18),
            bottomLeft:  isSender ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isSender ? const Radius.circular(4)  : const Radius.circular(18),
          ),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(1,2))],
        ),
        child: Text(msg.messageContent,
            style: TextStyle(
                color: isSender ? Colors.white : Colors.black87, fontSize: 15)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender) ...[_doctorAvatar(radius: 14), const SizedBox(width: 6)],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: content,
          ),
          if (isSender) const SizedBox(width: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 3,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kPrimaryColor),
            onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: Row(children: [
          Stack(children: [
            _doctorAvatar(radius: 22),
            Positioned(bottom: 0, right: 0,
                child: Container(width: 12, height: 12,
                    decoration: BoxDecoration(color: kOnlineColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)))),
          ]),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Dr. $_doctorName",
                style: const TextStyle(color: Colors.black87,
                    fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis),
            Text(_doctorSpecialty.isNotEmpty ? _doctorSpecialty : "Online",
                style: const TextStyle(fontSize: 12, color: kOnlineColor)),
          ])),
        ]),
        actions: [
          // Video call button removed
          IconButton(
              icon: const Icon(Icons.more_vert, color: kPrimaryColor),
              onPressed: () {}),
        ],
      ),
      body: Column(children: [
        if (timeLeft != null)
          Container(
            width: double.infinity,
            color: isExpired ? Colors.red.shade50 : Colors.green.shade50,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(Icons.access_time,
                    color: isExpired ? Colors.red : Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(isExpired ? "Chat expired" : "Chat expires in:",
                    style: TextStyle(
                        color: isExpired ? Colors.red.shade700 : Colors.green.shade800,
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              Text(isExpired ? "00:00:00" : _formatDuration(timeLeft!),
                  style: TextStyle(fontSize: 14,
                      color: isExpired ? Colors.red.shade700 : Colors.green.shade800,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
        Expanded(
          child: messages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            _doctorAvatar(radius: 40), const SizedBox(height: 14),
            Text("Dr. $_doctorName",
                style: const TextStyle(fontSize: 18,
                    fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 6),
            const Text("No messages yet.\nSay hello to get started!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ]))
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: messages.length,
            itemBuilder: (_, i) => _messageBubble(messages[i]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: const BoxDecoration(color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12,
                  blurRadius: 4, offset: Offset(0, -2))]),
          child: Row(children: [
            GestureDetector(
              onTap: isExpired ? null : _showImageSourceSheet,
              child: Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                      color: isExpired
                          ? Colors.grey.shade200
                          : kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: Icon(Icons.image_outlined,
                      color: isExpired ? Colors.grey : kPrimaryColor, size: 20)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25)),
              child: TextField(
                controller: _teMessage, enabled: !isExpired,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: isExpired
                      ? "Chat expired — purchase access"
                      : "Type a message…",
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.grey),
                ),
              ),
            )),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: (_isSending || isExpired) ? null : _sendMessage,
              child: CircleAvatar(
                radius: 22,
                backgroundColor:
                (_isSending || isExpired) ? Colors.grey : kPrimaryColor,
                child: _isSending
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}