import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../utils/colors.dart';

class TeacherChatScreen extends StatefulWidget {
  final String userName;
  const TeacherChatScreen({super.key, required this.userName});
  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _messages = [];
  String? _selectedEmail;
  String? _selectedName;
  bool _loadingStudents = false;
  bool _loadingMessages = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      if (_selectedEmail != null) await _fetchMessages(_selectedEmail!, silent: true);
      await _fetchStudents(silent: true);
      return mounted;
    });
  }

  Future<void> _fetchStudents({bool silent = false}) async {
    if (!silent) setState(() => _loadingStudents = true);
    try {
      final dio = Dio();
      final res = await dio.get('$_baseUrl/messages');
      final list = res.data['students'] as List;
      if (mounted) {
        setState(() {
          _students = list.map((s) => {
            'email': s['_id'] ?? '',
            'name': s['studentName'] ?? 'Student',
            'lastMessage': s['lastMessage'] ?? '',
            'unread': s['unread'] ?? 0,
            'color': LC.primary,
          }).toList();
          _loadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStudents = false);
    }
  }

  Future<void> _fetchMessages(String email, {bool silent = false}) async {
    if (!silent) setState(() => _loadingMessages = true);
    try {
      final dio = Dio();
      final encodedEmail = Uri.encodeComponent(email);
      final res = await dio.get('$_baseUrl/messages/$encodedEmail');
      final list = res.data['messages'] as List;
      if (mounted) {
        setState(() {
          _messages = list.map((m) => {
            'text': m['text'] ?? '',
            'from': m['from'] ?? 'student',
            'isTeacher': m['from'] == 'teacher',
            'time': _formatTime(m['createdAt'] ?? ''),
          }).toList();
          _loadingMessages = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty || _sending || _selectedEmail == null) return;
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    setState(() {
      _sending = true;
      _messages.add({
        'text': text,
        'from': 'teacher',
        'isTeacher': true,
        'time': 'Now',
      });
    });
    _scrollToBottom();
    try {
      final dio = Dio();
      await dio.post('$_baseUrl/messages', data: {
        'studentEmail': _selectedEmail,
        'studentName': _selectedName,
        'text': text,
        'from': 'teacher',
      });
      setState(() => _sending = false);
    } catch (e) {
      setState(() => _sending = false);
    }
  }

  void _selectStudent(Map<String, dynamic> student) {
    setState(() {
      _selectedEmail = student['email'] as String;
      _selectedName = student['name'] as String;
      _messages = [];
    });
    _fetchMessages(_selectedEmail!);
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final m = dt.minute.toString().padLeft(2, '0');
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) { return 'Now'; }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _msgCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? size.width * 0.1 : 18.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(children: [
      // Header
      Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFE0DEFF), LC.accent]).createShader(b),
              child: const Text('Student Messages', style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            ),
            const Text('Reply to your students',
              style: TextStyle(color: LC.tMuted, fontSize: 13)),
          ])),
          GestureDetector(
            onTap: () => _fetchStudents(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: LC.primary.withOpacity(0.12),
                border: Border.all(color: LC.primary.withOpacity(0.3))),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.refresh_rounded, color: LC.primary, size: 14),
                SizedBox(width: 4),
                Text('Refresh', style: TextStyle(
                  color: LC.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
      ),

      // Student list or chat
      Expanded(
        child: _selectedEmail == null
          ? _buildStudentList(hPad)
          : _buildChat(hPad, bottomPad),
      ),
    ]);
  }

  Widget _buildStudentList(double hPad) {
    if (_loadingStudents) {
      return const Center(child: CircularProgressIndicator(color: LC.primary));
    }
    if (_students.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💬', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('No messages yet', style: TextStyle(color: LC.tMuted, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('Students will appear here when they message you',
            style: TextStyle(color: LC.tMuted, fontSize: 12),
            textAlign: TextAlign.center),
        ]));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
      itemCount: _students.length,
      itemBuilder: (_, i) {
        final s = _students[i];
        final color = s['color'] as Color;
        final unread = s['unread'] as int;
        return GestureDetector(
          onTap: () => _selectStudent(s),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: unread > 0 ? color.withOpacity(0.08) : LC.glass,
              border: Border.all(
                color: unread > 0 ? color.withOpacity(0.3) : LC.glassBd)),
            child: Row(children: [
              Container(width: 46, height: 46,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.6)])),
                child: Center(child: Text(
                  (s['name'] as String)[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.w900)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s['name'] as String, style: const TextStyle(
                  color: LC.tPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(s['lastMessage'] as String,
                  style: const TextStyle(color: LC.tMuted, fontSize: 12),
                  overflow: TextOverflow.ellipsis),
              ])),
              if (unread > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10), color: LC.rose),
                  child: Text('$unread new', style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)))
              else
                const Icon(Icons.arrow_forward_ios_rounded, color: LC.tMuted, size: 13),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildChat(double hPad, double bottomPad) {
    return Column(children: [
      // Back + student name
      Padding(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() {
              _selectedEmail = null;
              _selectedName = null;
              _messages = [];
            }),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: LC.glass,
                border: Border.all(color: LC.glassBd)),
              child: const Icon(Icons.arrow_back_rounded, color: LC.tPrimary, size: 18)),
          ),
          const SizedBox(width: 12),
          Container(width: 36, height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [LC.primary, LC.accent])),
            child: Center(child: Text(
              (_selectedName ?? 'S')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)))),
          const SizedBox(width: 10),
          Text(_selectedName ?? 'Student', style: const TextStyle(
            color: LC.tPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: () => _fetchMessages(_selectedEmail!),
            child: const Icon(Icons.refresh_rounded, color: LC.tMuted, size: 18)),
        ]),
      ),
      Divider(color: Colors.white.withOpacity(0.06), height: 1),

      // Messages
      Expanded(
        child: _loadingMessages
          ? const Center(child: CircularProgressIndicator(color: LC.primary))
          : _messages.isEmpty
            ? const Center(child: Text('No messages yet',
                style: TextStyle(color: LC.tMuted, fontSize: 13)))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  final isTeacher = m['isTeacher'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: isTeacher
                        ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isTeacher) ...[
                          Container(width: 30, height: 30,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [LC.primary, LC.accent])),
                            child: Center(child: Text(
                              (_selectedName ?? 'S')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.w900)))),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isTeacher ? 18 : 4),
                                bottomRight: Radius.circular(isTeacher ? 4 : 18)),
                              gradient: isTeacher
                                ? const LinearGradient(
                                    colors: [LC.gold, LC.accent]) : null,
                              color: isTeacher ? null : LC.glass,
                              border: isTeacher ? null
                                : Border.all(color: LC.glassBd)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['text'] as String, style: TextStyle(
                                  color: isTeacher ? Colors.white : LC.tPrimary,
                                  fontSize: 13.5, height: 1.4)),
                                const SizedBox(height: 4),
                                Text(m['time'] as String, style: TextStyle(
                                  color: isTeacher
                                    ? Colors.white.withOpacity(0.6) : LC.tMuted,
                                  fontSize: 10)),
                              ]),
                          ),
                        ),
                        if (isTeacher) const SizedBox(width: 4),
                      ],
                    ),
                  );
                },
              ),
      ),

      // Input
      Container(
        padding: EdgeInsets.fromLTRB(hPad, 10, hPad, bottomPad + 90),
        decoration: BoxDecoration(
          color: LC.bg2,
          border: Border(top: BorderSide(
            color: Colors.white.withOpacity(0.06)))),
        child: Row(children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: LC.glass,
                border: Border.all(color: LC.glassBd)),
              child: TextField(
                controller: _msgCtrl,
                style: const TextStyle(color: LC.tPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Reply to student...',
                  hintStyle: TextStyle(color: LC.tMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12)),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(width: 46, height: 46,
              decoration: BoxDecoration(shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [LC.gold, LC.accent]),
                boxShadow: [BoxShadow(
                  color: LC.gold.withOpacity(0.4), blurRadius: 12)]),
              child: _sending
                ? const Padding(padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
          ),
        ]),
      ),
    ]);
  }
}



