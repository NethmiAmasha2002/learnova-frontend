import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../utils/colors.dart';
import 'teacher_notifications_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  final String userName;
  final Function(int) onNavigate;
  const TeacherDashboardScreen({
    super.key,
    required this.userName,
    required this.onNavigate,
  });
  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  int _submissionCount = 0;
  int _notesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final dio = Dio();
      final r1 = await dio.get('$_baseUrl/assignments');
      final r2 = await dio.get('$_baseUrl/notes');
      setState(() {
        _submissionCount = (r1.data['submissions'] as List).length;
        _notesCount = (r2.data['files'] as List).length;
      });
    } catch (_) {}
  }

  void _openNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: LC.bg1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: TeacherNotificationsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? size.width * 0.1 : 18.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final h = DateTime.now().hour;
    final greeting = h < 12 ? 'Good Morning ☀️'
      : h < 17 ? 'Good Afternoon 🌤️' : 'Good Evening 🌙';

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad + 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Header ──
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(greeting,
                    style: const TextStyle(color: LC.tMuted, fontSize: 13)),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFE0DEFF), LC.accent]).createShader(b),
                    child: Text(widget.userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width > 600 ? 28 : 24,
                        fontWeight: FontWeight.w900)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [
                        LC.gold.withOpacity(0.2),
                        LC.accent.withOpacity(0.1)]),
                      border: Border.all(color: LC.gold.withOpacity(0.4)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 6, height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: LC.gold,
                          boxShadow: [BoxShadow(
                            color: LC.gold.withOpacity(0.8), blurRadius: 5)])),
                      const SizedBox(width: 6),
                      const Text('Teacher — Mathematics',
                        style: TextStyle(
                          color: LC.gold, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ],
              ),
            ),

            // Notification bell
            Column(children: [
              GestureDetector(
                onTap: _openNotifications,
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: LC.glass,
                    border: Border.all(color: LC.glassBd)),
                  child: const Icon(Icons.notifications_rounded,
                    color: LC.rose, size: 20)),
              ),
              const SizedBox(height: 8),
              // Avatar → Profile
              GestureDetector(
                onTap: () => widget.onNavigate(4),
                child: Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [LC.gold, LC.accent]),
                    boxShadow: [BoxShadow(
                      color: LC.gold.withOpacity(0.4), blurRadius: 16)]),
                  child: Center(
                    child: Text(
                      widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase() : 'T',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w900))),
                ),
              ),
            ]),
          ]),

          const SizedBox(height: 20),

          // ── Teacher Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D1B69),
                  Color(0xFF11998E),
                  Color(0xFF38EF7D)],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [BoxShadow(
                color: LC.green.withOpacity(0.3),
                blurRadius: 32,
                offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.18)),
                  child: const Row(children: [
                    Icon(Icons.cast_for_education_rounded,
                      color: Colors.white, size: 13),
                    SizedBox(width: 5),
                    Text('TEACHER PANEL', style: TextStyle(
                      color: Colors.white, fontSize: 10,
                      fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  ])),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.18)),
                  child: const Text('Grade 11', style: TextStyle(
                    color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w700))),
              ]),
              const SizedBox(height: 14),
              const Text('Advanced Math Class', style: TextStyle(
                color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('Next class: Today at 3:00 PM',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.78), fontSize: 13)),
              const SizedBox(height: 18),
              Row(children: [
                _stat('24', 'Students'),
                const SizedBox(width: 24),
                _stat('$_submissionCount', 'Submissions'),
                const SizedBox(width: 24),
                _stat('$_notesCount', 'Notes'),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Quick Actions ──
          const Text('Quick Actions', style: TextStyle(
            color: LC.tPrimary, fontSize: 15,
            fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _actionCard(context, '📋', 'Submissions',
                'View student work', LC.primary, 2),
              _actionCard(context, '📁', 'Upload Notes',
                'Share with students', LC.gold, 2),
              _actionCard(context, '💬', 'Messages',
                'Reply to students', LC.accent, 3),
              _actionCard(context, '📅', 'Schedule',
                'Manage classes', LC.green, 1),
            ],
          ),

          const SizedBox(height: 20),

          // ── Stats ──
          const Text('Overview', style: TextStyle(
            color: LC.tPrimary, fontSize: 15,
            fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statCard('24', 'Students',
              Icons.people_rounded, LC.primary)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('$_submissionCount', 'Pending',
              Icons.assignment_rounded, LC.rose)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('$_notesCount', 'Notes',
              Icons.folder_rounded, LC.gold)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('12', 'Sessions',
              Icons.video_call_rounded, LC.green)),
          ]),

          const SizedBox(height: 20),

          // ── Recent Submissions ──
          Row(children: [
            const Text('📋 Recent Submissions', style: TextStyle(
              color: LC.tPrimary, fontSize: 15,
              fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(
              onTap: () => widget.onNavigate(2),
              child: const Text('See all →',
                style: TextStyle(
                  color: LC.accent, fontSize: 12,
                  fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          _submissionCount == 0
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: LC.glass,
                  border: Border.all(color: LC.glassBd)),
                child: const Center(
                  child: Text('No submissions yet',
                    style: TextStyle(color: LC.tMuted, fontSize: 13))))
            : Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: LC.glass,
                  border: Border.all(
                    color: LC.primary.withOpacity(0.2))),
                child: Row(children: [
                  Container(width: 42, height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LC.primary.withOpacity(0.15)),
                    child: const Icon(Icons.assignment_rounded,
                      color: LC.primary, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      '$_submissionCount new submission'
                      '${_submissionCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: LC.tPrimary, fontSize: 13,
                        fontWeight: FontWeight.w700)),
                    const Text('Tap to review',
                      style: TextStyle(color: LC.tMuted, fontSize: 11)),
                  ])),
                  GestureDetector(
                    onTap: () => widget.onNavigate(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [LC.primary, LC.accent])),
                      child: const Text('Review',
                        style: TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ),
        ],
      ),
    );
  }

  Widget _stat(String val, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(val, style: const TextStyle(
        color: Colors.white, fontSize: 20,
        fontWeight: FontWeight.w900)),
      Text(label, style: TextStyle(
        color: Colors.white.withOpacity(0.65), fontSize: 11)),
    ],
  );

  Widget _actionCard(BuildContext context, String emoji,
      String title, String sub, Color color, int tabIndex) {
    return GestureDetector(
      onTap: () => widget.onNavigate(tabIndex),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: LC.glass,
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(
            color: color.withOpacity(0.1), blurRadius: 16)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(
              color: LC.tPrimary, fontSize: 13,
              fontWeight: FontWeight.w800)),
            Text(sub, style: const TextStyle(
              color: LC.tMuted, fontSize: 10)),
          ]),
      ),
    );
  }

  Widget _statCard(String val, String label,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: LC.glass,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Container(width: 34, height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15)),
          child: Icon(icon, color: color, size: 16)),
        const SizedBox(height: 7),
        Text(val, style: TextStyle(
          color: color, fontSize: 17,
          fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
          color: LC.tMuted, fontSize: 9.5),
          textAlign: TextAlign.center),
      ]),
    );
  }
}



