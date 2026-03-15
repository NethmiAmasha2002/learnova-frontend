import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../utils/colors.dart';

class TeacherNotificationsScreen extends StatefulWidget {
  const TeacherNotificationsScreen({super.key});
  @override
  State<TeacherNotificationsScreen> createState() =>
      _TeacherNotificationsScreenState();
}

class _TeacherNotificationsScreenState
    extends State<TeacherNotificationsScreen> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = false;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _selectedType = 'general';

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _loading = true);
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

  Future<void> _createNotification() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      _showSnack('Please fill title and message!', LC.rose);
      return;
    }
    try {
      final dio = Dio();
      final res = await dio.post('$_baseUrl/notifications', data: {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'type': _selectedType,
      });
      if (res.statusCode == 200) {
        _titleCtrl.clear();
        _bodyCtrl.clear();
        if (mounted) Navigator.pop(context);
        if (mounted) _showSnack('✅ Notification sent!', LC.green);
        _fetchNotifications();
      } else {
        if (mounted) _showSnack('❌ Failed to send', LC.rose);
      }
    } catch (e) {
      if (mounted) _showSnack('❌ Check connection', LC.rose);
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      final dio = Dio();
      await dio.delete('$_baseUrl/notifications/$id');
      _showSnack('🗑️ Deleted', LC.rose);
      _fetchNotifications();
    } catch (e) {
      _showSnack('❌ Delete failed', LC.rose);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24,
            MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: LC.bg2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2)))),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFE0DEFF), LC.rose]).createShader(b),
                child: const Text('Send Notification', style: TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 6),
              const Text('All students will see this immediately',
                style: TextStyle(color: LC.tMuted, fontSize: 13)),
              const SizedBox(height: 24),

              // Type selector
              const Text('Type', style: TextStyle(
                color: LC.tMuted, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  'general', 'exam', 'homework', 'notes', 'schedule'
                ].map((type) {
                  final selected = _selectedType == type;
                  final color = _typeColor(type);
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedType = type);
                      setModalState(() => _selectedType = type);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: selected ? color.withOpacity(0.2) : LC.glass,
                        border: Border.all(
                          color: selected ? color : LC.glassBd,
                          width: selected ? 1.5 : 1)),
                      child: Text('${_typeIcon(type)} $type',
                        style: TextStyle(
                          color: selected ? color : LC.tMuted,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList()),
              ),
              const SizedBox(height: 20),

              // Title
              const Text('Title', style: TextStyle(
                color: LC.tMuted, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.09))),
                child: TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: LC.tPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Exam Next Week!',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.28), fontSize: 14),
                    prefixIcon: const Icon(Icons.title_rounded,
                      color: LC.rose, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 4)),
                ),
              ),
              const SizedBox(height: 16),

              // Body
              const Text('Message', style: TextStyle(
                color: LC.tMuted, fontSize: 12,
                fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.09))),
                child: TextField(
                  controller: _bodyCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: LC.tPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write your announcement here...',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.28), fontSize: 14),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.message_rounded,
                        color: LC.rose, size: 18)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 4)),
                ),
              ),
              const SizedBox(height: 28),

              GestureDetector(
                onTap: _createNotification,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [LC.rose, LC.primary]),
                    boxShadow: [BoxShadow(
                      color: LC.rose.withOpacity(0.4),
                      blurRadius: 20, offset: const Offset(0, 6))]),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Send to All Students', style: TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w900)),
                    ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? size.width * 0.1 : 18.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFE0DEFF), LC.rose]).createShader(b),
              child: const Text('Notifications', style: TextStyle(
                color: Colors.white, fontSize: 26,
                fontWeight: FontWeight.w900)),
            ),
            const Text('Send announcements to students',
              style: TextStyle(color: LC.tMuted, fontSize: 13)),
          ])),
          GestureDetector(
            onTap: _showCreateDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [LC.rose, LC.primary]),
                boxShadow: [BoxShadow(
                  color: LC.rose.withOpacity(0.4), blurRadius: 12)]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('New', style: TextStyle(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      ),
      Divider(color: Colors.white.withOpacity(0.06), height: 1),
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: LC.rose))
          : RefreshIndicator(
              color: LC.rose,
              onRefresh: _fetchNotifications,
              child: _notifications.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    const Center(child: Column(children: [
                      Text('🔔', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('No notifications yet',
                        style: TextStyle(color: LC.tMuted, fontSize: 14)),
                      SizedBox(height: 8),
                      Text('Tap "+ New" to send one',
                        style: TextStyle(color: LC.tMuted, fontSize: 12)),
                    ])),
                  ])
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      hPad, 12, hPad, bottomPad + 130),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final color = _typeColor(n['type'] as String);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: LC.glass,
                          border: Border.all(color: color.withOpacity(0.25))),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          Container(width: 4,
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
                            Row(children: [
                              Text(_typeIcon(n['type'] as String),
                                style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Expanded(child: Text(n['title'] as String,
                                style: const TextStyle(color: LC.tPrimary,
                                  fontSize: 13, fontWeight: FontWeight.w800))),
                            ]),
                            const SizedBox(height: 4),
                            Text(n['body'] as String,
                              style: const TextStyle(color: LC.tMuted,
                                fontSize: 12, height: 1.4)),
                            const SizedBox(height: 6),
                            Text(_formatTime(n['createdAt'] as String),
                              style: TextStyle(
                                color: color.withOpacity(0.7),
                                fontSize: 11, fontWeight: FontWeight.w600)),
                          ])),
                          GestureDetector(
                            onTap: () => _deleteNotification(n['id'] as String),
                            child: Icon(Icons.delete_outline_rounded,
                              color: LC.rose.withOpacity(0.6), size: 18)),
                        ]),
                      );
                    },
                  ),
            ),
      ),
    ]);
  }
}



