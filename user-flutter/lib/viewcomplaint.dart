import 'package:ai_doctor_app/sent_complaint.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const ViewReply());
}

class ViewReply extends StatelessWidget {
  const ViewReply({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'View Reply',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
      ),
      home: const ViewComplaints(title: 'View Reply'),
    );
  }
}

class ViewComplaints extends StatefulWidget {
  const ViewComplaints({super.key, required this.title});
  final String title;

  @override
  State<ViewComplaints> createState() => _ViewComplaintsState();
}

class _ViewComplaintsState extends State<ViewComplaints>
    with SingleTickerProviderStateMixin {
  List<int> id_ = [];
  List<String> complaint_ = [];
  List<String> date_ = [];
  List<String> reply_ = [];
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Palette ──────────────────────────────────────────────────────────────
  static const Color _bg         = Color(0xFFF0F4FF);
  static const Color _surface    = Color(0xFFFFFFFF);
  static const Color _primary    = Color(0xFF1565C0);
  static const Color _accent     = Color(0xFF42A5F5);
  static const Color _textDark   = Color(0xFF0D1B3E);
  static const Color _textMid    = Color(0xFF4A5568);
  static const Color _textLight  = Color(0xFF90A4AE);
  static const Color _border     = Color(0xFFDDE3F0);
  static const Color _replyBg    = Color(0xFFE8F5E9);
  static const Color _replyClr   = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    viewComplaints();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ─────────────────────────────────────────────────────
  void viewComplaints() async {
    List<int> id = <int>[];
    List<String> date = <String>[];
    List<String> complaint = <String>[];
    List<String> reply = <String>[];

    try {
      SharedPreferences sh = await SharedPreferences.getInstance();
      String urls = sh.getString('url').toString();
      String url = '$urls/user_view_reply';
      String lid = sh.getString("lid").toString();
      var data = await http.post(Uri.parse(url), body: {"lid": lid});
      var jsondata = json.decode(data.body);
      String statuss = jsondata['status'];
      var arr = jsondata["data"];

      for (int i = 0; i < arr.length; i++) {
        id.add(arr[i]['id']);
        date.add(arr[i]['date'].toString());
        complaint.add(arr[i]['complaint']);
        reply.add(arr[i]['reply']);
      }

      setState(() {
        id_        = id;
        date_      = date;
        complaint_ = complaint;
        reply_     = reply;
        _isLoading = false;
      });
      _fadeController.forward();
    } catch (e) {
      print("Error: " + e.toString());
      setState(() => _isLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            if (_isLoading)
              const SliverFillRemaining(child: _LoadingView())
            else if (id_.isEmpty)
              const SliverFillRemaining(child: _EmptyView())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => FadeTransition(
                      opacity: _fadeAnimation,
                      child: _ComplaintCard(
                        index: index,
                        date: date_[index],
                        complaint: complaint_[index],
                        reply: reply_[index],
                      ),
                    ),
                    childCount: id_.length,
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: _buildFAB(context),
      ),
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: _primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          tooltip: 'Refresh',
          onPressed: () {
            setState(() => _isLoading = true);
            _fadeController.reset();
            viewComplaints();
          },
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.refresh_rounded,
                color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.mark_chat_read_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Complaints & Replies',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'Track your submitted issues',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!_isLoading && id_.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _HeaderChip(
                      icon: Icons.inbox_rounded,
                      label: '${id_.length} complaint${id_.length == 1 ? '' : 's'}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        'Complaints & Replies',
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────
  Widget _buildFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => compl(title: '')),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── Complaint Card ────────────────────────────────────────────────────────
class _ComplaintCard extends StatelessWidget {
  final int index;
  final String date;
  final String complaint;
  final String reply;

  const _ComplaintCard({
    required this.index,
    required this.date,
    required this.complaint,
    required this.reply,
  });

  bool get _hasReply => reply.trim().isNotEmpty && reply.trim() != 'null';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE3F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F8FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFF1565C0),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: Color(0xFF90A4AE)),
                const SizedBox(width: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _StatusBadge(hasReply: _hasReply),
              ],
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Complaint section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 3,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'COMPLAINT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF90A4AE),
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            complaint,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0D1B3E),
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: Color(0xFFEEF2FF), thickness: 1),
                const SizedBox(height: 14),

                // Reply section
                if (_hasReply)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF2E7D32).withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E7D32).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.reply_rounded,
                              color: Color(0xFF2E7D32), size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REPLY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2E7D32),
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reply,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1B4D1E),
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded,
                            color: Color(0xFFF59E0B), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Awaiting reply from support',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool hasReply;
  const _StatusBadge({required this.hasReply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: hasReply
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasReply
              ? const Color(0xFF2E7D32).withOpacity(0.3)
              : const Color(0xFFF59E0B).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasReply
                ? Icons.check_circle_rounded
                : Icons.pending_rounded,
            size: 11,
            color: hasReply
                ? const Color(0xFF2E7D32)
                : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 4),
          Text(
            hasReply ? 'Replied' : 'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: hasReply
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header Chip ───────────────────────────────────────────────────────────
class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Loading View ──────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF1565C0),
              backgroundColor: Color(0xFFDDE3F0),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading complaints...',
            style: TextStyle(
              color: Color(0xFF4A5568),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty View ────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF9),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF1565C0).withOpacity(0.2),
                    width: 2),
              ),
              child: const Icon(Icons.inbox_rounded,
                  color: Color(0xFF1565C0), size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Complaints Yet',
              style: TextStyle(
                color: Color(0xFF0D1B3E),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the button below to submit\nyour first complaint',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF4A5568), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}