import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../utils/colors.dart';

class ChatScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  const ChatScreen({super.key, required this.userName, required this.userEmail});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll for new messages every 5 seconds
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      await _fetchMessages(silent: true);
      return mounted;
    });
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final dio = Dio();
      final email = Uri.encodeComponent(widget.userEmail.isNotEmpty
        ? widget.userEmail : widget.userName);
      final res = await dio.get('$_baseUrl/messages/$email');
      final list = res.data['messages'] as List;
      if (mounted) {
        setState(() {
          _messages = list.map((m) => {
            'text': m['text'] ?? '',
            'from': m['from'] ?? 'student',
            'time': _formatTime(m['createdAt'] ?? ''),
            'isMe': m['from'] == 'student',
          }).toList();
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty || _sending) return;
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    setState(() {
      _sending = true;
      _messages.add({'text': text, 'from': 'student', 'isMe': true, 'time': 'Now'});
    });
    _scrollToBottom();
    try {
      final dio = Dio();
      await dio.post('$_baseUrl/messages', data: {
        'studentEmail': widget.userEmail.isNotEmpty
          ? widget.userEmail : widget.userName,
        'studentName': widget.userName,
        'text': text,
        'from': 'student',
      });
      setState(() => _sending = false);
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red));
      }
    }
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
    final hPad = size.width > 600 ? size.width * 0.1 : 16.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(children: [
      // Header
      Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 12),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [LC.primary, LC.accent]),
              boxShadow: [BoxShadow(
                color: LC.primary.withOpacity(0.4), blurRadius: 14)]),
            child: const Center(child: Text('T',
              style: TextStyle(color: Colors.white, fontSize: 22,
                fontWeight: FontWeight.w900)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Math Teacher', style: TextStyle(
              color: LC.tPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
            Row(children: [
              Container(width: 7, height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: LC.green,
                  boxShadow: [BoxShadow(
                    color: LC.green.withOpacity(0.9), blurRadius: 6)])),
              const SizedBox(width: 5),
              const Text('Private chat', style: TextStyle(color: LC.green, fontSize: 12)),
            ]),
          ])),
          GestureDetector(
            onTap: () => _fetchMessages(),
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
      Divider(color: Colors.white.withOpacity(0.06), height: 1),

      // Messages
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: LC.primary))
          : _messages.isEmpty
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('💬', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  const Text('No messages yet',
                    style: TextStyle(color: LC.tMuted, fontSize: 14)),
                  const SizedBox(height: 8),
                  const Text('Send a message to your teacher!',
                    style: TextStyle(color: LC.tMuted, fontSize: 12)),
                ]))
            : ListView.builder(
                controller: _scrollCtrl,
                padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 12),
                itemCount: _messages.length,
                itemBuilder: (_, i) {
                  final m = _messages[i];
                  final isMe = m['isMe'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: isMe
                        ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          Container(width: 30, height: 30,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [LC.primary, LC.accent])),
                            child: const Center(child: Text('T',
                              style: TextStyle(color: Colors.white,
                                fontSize: 13, fontWeight: FontWeight.w900)))),
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
                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 18)),
                              gradient: isMe ? const LinearGradient(
                                colors: [LC.primary, Color(0xFF5A4FFF)]) : null,
                              color: isMe ? null : Colors.white.withOpacity(0.08),
                              border: isMe ? null : Border.all(
                                color: Colors.white.withOpacity(0.08))),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['text'] as String, style: TextStyle(
                                  color: isMe ? Colors.white : LC.tPrimary,
                                  fontSize: 13.5, height: 1.4)),
                                const SizedBox(height: 4),
                                Text(m['time'] as String, style: TextStyle(
                                  color: isMe
                                    ? Colors.white.withOpacity(0.6) : LC.tMuted,
                                  fontSize: 10)),
                              ]),
                          ),
                        ),
                        if (isMe) const SizedBox(width: 4),
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
                  hintText: 'Message your teacher...',
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
                gradient: const LinearGradient(colors: [LC.primary, LC.accent]),
                boxShadow: [BoxShadow(
                  color: LC.primary.withOpacity(0.5), blurRadius: 14)]),
              child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
          ),
        ]),
      ),
    ]);
  }
}



