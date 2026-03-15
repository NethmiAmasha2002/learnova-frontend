import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../utils/colors.dart';

class DashboardScreen extends StatefulWidget {
  final String userName;
  final String userRole;
  final Function(int) onNavigate;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userRole,
    required this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  int _notifCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotifCount();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 30));
      if (!mounted) return false;
      await _fetchNotifCount();
      return mounted;
    });
  }

  Future<void> _fetchNotifCount() async {
    try {
      final dio = Dio();
      final res = await dio.get('$_baseUrl/notifications');
      final list = res.data['notifications'] as List;
      if (mounted) setState(() => _notifCount = list.length);
    } catch (_) {}
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  void _showNotification(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _openNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _NotificationsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? size.width * 0.1 : 18.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad + 130),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header ──
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(_greeting(),
              style: const TextStyle(color: LC.tMuted, fontSize: 13)),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFE0DEFF), LC.accent]).createShader(b),
              child: Text(widget.userName, style: TextStyle(
                color: Colors.white,
                fontSize: size.width > 600 ? 28 : 24,
                fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(colors: [
                  LC.primary.withOpacity(0.2),
                  LC.accent.withOpacity(0.1)]),
                border: Border.all(color: LC.primary.withOpacity(0.3)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: LC.green,
                    boxShadow: [BoxShadow(
                      color: LC.green.withOpacity(0.8), blurRadius: 5)])),
                const SizedBox(width: 6),
                const Text('Mathematics Class — Active',
                  style: TextStyle(
                    color: LC.pLight, fontSize: 11,
                    fontWeight: FontWeight.w600)),
              ]),
            ),
          ])),

          Column(children: [
            // Notification bell
            GestureDetector(
              onTap: () => _openNotifications(context),
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LC.glass,
                  border: Border.all(color: LC.glassBd)),
                child: Stack(alignment: Alignment.center, children: [
                  Icon(Icons.notifications_outlined,
                    color: Colors.white.withOpacity(0.8), size: 20),
                  if (_notifCount > 0)
                    Positioned(top: 6, right: 6,
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: LC.rose,
                          boxShadow: [BoxShadow(
                            color: LC.rose.withOpacity(0.8),
                            blurRadius: 5)]),
                        child: Center(child: Text('$_notifCount',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 9,
                            fontWeight: FontWeight.w900))))),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            // Avatar
            GestureDetector(
              onTap: () => widget.onNavigate(4),
              child: Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [LC.primary, LC.accent]),
                  boxShadow: [BoxShadow(
                    color: LC.primary.withOpacity(0.5), blurRadius: 16)]),
                child: Center(child: Text(
                  widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w900))),
              ),
            ),
          ]),
        ]),

        const SizedBox(height: 20),

        // ── Class Banner ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A3FCC),
                Color(0xFF1E6BCC),
                Color(0xFF00C9DE)],
              stops: [0.0, 0.5, 1.0],
            ),
            boxShadow: [BoxShadow(
              color: LC.primary.withOpacity(0.45),
              blurRadius: 32, offset: const Offset(0, 8))],
          ),
          child: Stack(children: [
            Positioned(right: 0, top: -8,
              child: Text('∑π√∞', style: TextStyle(
                fontSize: 52,
                color: Colors.white.withOpacity(0.07),
                fontWeight: FontWeight.w900))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.18)),
                  child: const Row(children: [
                    Icon(Icons.school_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 5),
                    Text('MATHEMATICS', style: TextStyle(
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
                _bannerStat('24', 'Students'),
                const SizedBox(width: 24),
                _bannerStat('12', 'Sessions Done'),
                const SizedBox(width: 24),
                _bannerStat('85%', 'Your Score'),
              ]),
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
          crossAxisCount: size.width > 600 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: size.width > 600 ? 1.8 : 1.45,
          children: [
            _actionCard(context, '📅', 'Schedule',
              'View classes', LC.primary, 1),
            _actionCard(context, '📝', 'Assignments',
              'Submit work', LC.rose, 2),
            _actionCard(context, '📁', 'Notes',
              'Download files', LC.gold, 2),
            _actionCard(context, '💬', 'Chat Teacher',
              'Send message', LC.accent, 3),
          ],
        ),

        const SizedBox(height: 20),

        // ── Stats ──
        const Text('Your Stats', style: TextStyle(
          color: LC.tPrimary, fontSize: 15,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _statCard('3', 'This\nWeek',
            Icons.calendar_today_rounded, LC.primary,
            () => widget.onNavigate(1))),
          const SizedBox(width: 10),
          Expanded(child: _statCard('2', 'Pending\nTasks',
            Icons.assignment_late_outlined, LC.rose,
            () => widget.onNavigate(2))),
          const SizedBox(width: 10),
          Expanded(child: _statCard('85%', 'Overall\nGrade',
            Icons.grade_rounded, LC.gold, null)),
          const SizedBox(width: 10),
          Expanded(child: _statCard('5', 'New\nNotes',
            Icons.folder_outlined, LC.green,
            () => widget.onNavigate(2))),
        ]),

        const SizedBox(height: 20),

        // ── Progress ──
        const Text('📊 Topic Progress', style: TextStyle(
          color: LC.tPrimary, fontSize: 15,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _progressCard(),

        const SizedBox(height: 20),

        // ── Announcements ──
        const Text('🔔 Announcements', style: TextStyle(
          color: LC.tPrimary, fontSize: 15,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _announcementCard(context, '📢 Exam Next Week!',
          'The mid-term exam is on March 20. Topics: Algebra & Calculus.',
          LC.rose),
        const SizedBox(height: 10),
        _announcementCard(context, '📁 New Notes Added',
          'Chapter 6 notes are available. Download from Tasks tab.',
          LC.gold),
        const SizedBox(height: 10),
        _announcementCard(context, '📅 Class Rescheduled',
          'Thursday class moved to Friday 2:00 PM. Join link updated.',
          LC.accent),
      ]),
    );
  }

  Widget _bannerStat(String val, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(val, style: const TextStyle(
        color: Colors.white, fontSize: 20,
        fontWeight: FontWeight.w900)),
      Text(label, style: TextStyle(
        color: Colors.white.withOpacity(0.65), fontSize: 11)),
    ],
  );

  Widget _actionCard(BuildContext context, String emoji, String title,
      String sub, Color color, int tabIndex) {
    return GestureDetector(
      onTap: () {
        _showNotification(context, 'Opening $title...', color);
        Future.delayed(const Duration(milliseconds: 400),
          () => widget.onNavigate(tabIndex));
      },
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

  Widget _statCard(String val, String label, IconData icon,
      Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }

  Widget _progressCard() {
    final subjects = [
      {'name': 'Algebra', 'score': 0.88, 'color': LC.primary},
      {'name': 'Calculus', 'score': 0.72, 'color': LC.accent},
      {'name': 'Trigonometry', 'score': 0.65, 'color': LC.gold},
      {'name': 'Statistics', 'score': 0.91, 'color': LC.green},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: LC.glass,
        border: Border.all(color: LC.glassBd),
      ),
      child: Row(children: [
        Container(width: 76, height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [LC.primary, LC.accent]),
            boxShadow: [BoxShadow(
              color: LC.primary.withOpacity(0.4), blurRadius: 18)]),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            Text('85%', style: TextStyle(
              color: Colors.white, fontSize: 18,
              fontWeight: FontWeight.w900)),
            Text('Overall', style: TextStyle(
              color: Colors.white70, fontSize: 9)),
          ])),
        const SizedBox(width: 18),
        Expanded(child: Column(
          children: subjects.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              SizedBox(width: 76, child: Text(s['name'] as String,
                style: const TextStyle(
                  color: LC.tMuted, fontSize: 11))),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s['score'] as double,
                  backgroundColor: Colors.white.withOpacity(0.07),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    s['color'] as Color),
                  minHeight: 6,
                ))),
              const SizedBox(width: 8),
              Text('${((s['score'] as double) * 100).toInt()}%',
                style: TextStyle(
                  color: s['color'] as Color,
                  fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          )).toList(),
        )),
      ]),
    );
  }

  Widget _announcementCard(BuildContext context, String title,
      String body, Color color) {
    return GestureDetector(
      onTap: () => _showNotification(context, title, color),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: LC.glass,
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(width: 4, height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withOpacity(0.3)]))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(title, style: const TextStyle(
              color: LC.tPrimary, fontSize: 13,
              fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(body, style: const TextStyle(
              color: LC.tMuted, fontSize: 12, height: 1.4)),
          ])),
        ]),
      ),
    );
  }
}

// ── Notifications Bottom Sheet ──────────────────────────────────────────────
class _NotificationsSheet extends StatefulWidget {
  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final dio = Dio();
      final res = await dio.get('$_baseUrl/notifications');
      final list = res.data['notifications'] as List;
      if (mounted) {
        setState(() {
          _notifications = list.map((n) => {
            'id': n['_id'] ?? '',
            'title': n['title'] ?? '',
            'body': n['body'] ?? '',
            'type': n['type'] ?? 'general',
            'createdAt': n['createdAt'] ?? '',
          }).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'exam': return LC.rose;
      case 'homework': return LC.gold;
      case 'notes': return LC.accent;
      case 'schedule': return LC.green;
      default: return LC.primary;
    }
  }

  String _typeIcon(String type) {
    switch (type) {
      case 'exam': return '📢';
      case 'homework': return '📝';
      case 'notes': return '📁';
      case 'schedule': return '📅';
      default: return '🔔';
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: LC.bg2,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.white.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(children: [
            const Text('Notifications', style: TextStyle(
              color: LC.tPrimary, fontSize: 18,
              fontWeight: FontWeight.w900)),
            const SizedBox(width: 10),
            if (_notifications.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: LC.rose.withOpacity(0.2)),
                child: Text('${_notifications.length} new',
                  style: const TextStyle(
                    color: LC.rose, fontSize: 11,
                    fontWeight: FontWeight.w700))),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close',
                style: TextStyle(color: LC.tMuted, fontSize: 13))),
          ]),
        ),
        Divider(color: Colors.white.withOpacity(0.06)),
        Expanded(
          child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: LC.primary))
            : _notifications.isEmpty
              ? const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🔔', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 12),
                    Text('No notifications yet',
                      style: TextStyle(
                        color: LC.tMuted, fontSize: 13)),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                  itemCount: _notifications.length,
                  itemBuilder: (_, i) {
                    final n = _notifications[i];
                    final color = _typeColor(n['type'] as String);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: color.withOpacity(0.08),
                        border: Border.all(
                          color: color.withOpacity(0.3))),
                      child: Row(children: [
                        Container(width: 42, height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.15)),
                          child: Center(child: Text(
                            _typeIcon(n['type'] as String),
                            style: const TextStyle(fontSize: 18)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Row(children: [
                            Expanded(child: Text(n['title'] as String,
                              style: const TextStyle(
                                color: LC.tPrimary, fontSize: 13,
                                fontWeight: FontWeight.w800))),
                            Container(width: 8, height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, color: color,
                                boxShadow: [BoxShadow(
                                  color: color.withOpacity(0.8),
                                  blurRadius: 5)])),
                          ]),
                          const SizedBox(height: 3),
                          Text(n['body'] as String,
                            style: const TextStyle(
                              color: LC.tMuted, fontSize: 12,
                              height: 1.3)),
                          const SizedBox(height: 4),
                          Text(_formatTime(n['createdAt'] as String),
                            style: TextStyle(
                              color: color.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                        ])),
                      ]),
                    );
                  },
                ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ]),
    );
  }
}



