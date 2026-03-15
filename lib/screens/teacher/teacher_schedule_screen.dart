import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../utils/colors.dart';

class TeacherScheduleScreen extends StatefulWidget {
  const TeacherScheduleScreen({super.key});
  @override
  State<TeacherScheduleScreen> createState() => _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends State<TeacherScheduleScreen> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  List<Map<String, dynamic>> _classes = [];
  bool _loading = false;

  // Form fields
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60 min');
  final _topicCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _durationCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchClasses() async {
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final res = await dio.get('$_baseUrl/classes');
      final list = res.data['classes'] as List;
      setState(() {
        _classes = list.map((c) => {
          'id': c['_id'] ?? '',
          'title': c['title'] ?? '',
          'date': c['date'] ?? '',
          'time': c['time'] ?? '',
          'duration': c['duration'] ?? '',
          'link': c['link'] ?? '',
          'topic': c['topic'] ?? '',
          'status': c['status'] ?? 'upcoming',
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _createClass() async {
    if (_titleCtrl.text.isEmpty || _linkCtrl.text.isEmpty) {
      _showSnack('Please fill title and meeting link!', LC.rose);
      return;
    }
    try {
      final dio = Dio();
      final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
      final hour = _selectedTime.hourOfPeriod == 0 ? 12 : _selectedTime.hourOfPeriod;
      final minute = _selectedTime.minute.toString().padLeft(2, '0');
      final ampm = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
      final timeStr = '$hour:$minute $ampm';

      await dio.post('$_baseUrl/classes', data: {
        'title': _titleCtrl.text.trim(),
        'date': dateStr,
        'time': timeStr,
        'duration': _durationCtrl.text.trim(),
        'link': _linkCtrl.text.trim(),
        'topic': _topicCtrl.text.trim(),
        'status': 'upcoming',
      });

      _titleCtrl.clear();
      _linkCtrl.clear();
      _topicCtrl.clear();
      _showSnack('✅ Class created! Students can see it now.', LC.green);
      Navigator.pop(context);
      _fetchClasses();
    } catch (e) {
      _showSnack('❌ Failed to create class.', LC.rose);
    }
  }

  Future<void> _deleteClass(String id) async {
    try {
      final dio = Dio();
      await dio.delete('$_baseUrl/classes/$id');
      _showSnack('🗑️ Class deleted', LC.rose);
      _fetchClasses();
    } catch (e) {
      _showSnack('❌ Delete failed', LC.rose);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          decoration: BoxDecoration(
            color: LC.bg2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2)))),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFE0DEFF), LC.gold]).createShader(b),
                child: const Text('Create New Class', style: TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 20),

              // Title
              _label('Class Title'),
              const SizedBox(height: 8),
              _field(_titleCtrl, 'e.g. Algebra — Chapter 7',
                Icons.school_rounded),
              const SizedBox(height: 16),

              // Topic
              _label('Topic (optional)'),
              const SizedBox(height: 8),
              _field(_topicCtrl, 'e.g. Quadratic Equations',
                Icons.topic_rounded),
              const SizedBox(height: 16),

              // Meeting Link
              _label('Google Meet / Zoom Link'),
              const SizedBox(height: 8),
              _field(_linkCtrl, 'https://meet.google.com/...',
                Icons.videocam_rounded),
              const SizedBox(height: 16),

              // Duration
              _label('Duration'),
              const SizedBox(height: 8),
              _field(_durationCtrl, '60 min',
                Icons.timer_rounded),
              const SizedBox(height: 16),

              // Date picker
              _label('Date'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (_, child) => Theme(
                      data: ThemeData.dark(), child: child!));
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                    setModalState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.09))),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                      color: LC.gold, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: const TextStyle(color: LC.tPrimary, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded,
                      color: LC.tMuted, size: 20),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Time picker
              _label('Time'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                    builder: (_, child) => Theme(
                      data: ThemeData.dark(), child: child!));
                  if (picked != null) {
                    setState(() => _selectedTime = picked);
                    setModalState(() => _selectedTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.09))),
                  child: Row(children: [
                    const Icon(Icons.access_time_rounded,
                      color: LC.gold, size: 18),
                    const SizedBox(width: 10),
                    Text(_selectedTime.format(context),
                      style: const TextStyle(color: LC.tPrimary, fontSize: 14)),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded,
                      color: LC.tMuted, size: 20),
                  ]),
                ),
              ),
              const SizedBox(height: 24),

              // Create button
              GestureDetector(
                onTap: _createClass,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [LC.gold, LC.accent]),
                    boxShadow: [BoxShadow(
                      color: LC.gold.withOpacity(0.4),
                      blurRadius: 20, offset: const Offset(0, 6))]),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Create Class', style: TextStyle(
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

  Widget _label(String text) => Text(text, style: const TextStyle(
    color: LC.tMuted, fontSize: 12,
    fontWeight: FontWeight.w600, letterSpacing: 0.8));

  Widget _field(TextEditingController ctrl, String hint, IconData icon) =>
    Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.09))),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: LC.tPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 14),
          prefixIcon: Icon(icon, color: LC.gold, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14, horizontal: 4)),
      ),
    );

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
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFE0DEFF), LC.gold]).createShader(b),
              child: const Text('Class Schedule', style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
            ),
            const Text('Manage your classes',
              style: TextStyle(color: LC.tMuted, fontSize: 13)),
          ])),
          GestureDetector(
            onTap: _showCreateDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(colors: [LC.gold, LC.accent]),
                boxShadow: [BoxShadow(
                  color: LC.gold.withOpacity(0.4), blurRadius: 12)]),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add_rounded, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text('New Class', style: TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ]),
            ),
          ),
        ]),
      ),
      Divider(color: Colors.white.withOpacity(0.06), height: 1),

      // Classes list
      Expanded(
        child: _loading
          ? const Center(child: CircularProgressIndicator(color: LC.gold))
          : RefreshIndicator(
              color: LC.gold,
              onRefresh: _fetchClasses,
              child: _classes.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(child: Column(children: [
                      const Text('📅', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('No classes yet',
                        style: TextStyle(color: LC.tMuted, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text('Tap "+ New Class" to create one',
                        style: TextStyle(color: LC.tMuted, fontSize: 12)),
                    ])),
                  ])
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(hPad, 12, hPad, bottomPad + 130),
                    itemCount: _classes.length,
                    itemBuilder: (_, i) => _classCard(_classes[i]),
                  ),
            ),
      ),
    ]);
  }

  Widget _classCard(Map<String, dynamic> c) {
    final colors = [LC.primary, LC.accent, LC.gold, LC.green, LC.rose];
    final color = colors[_classes.indexOf(c) % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: LC.glass,
        border: Border.all(color: color.withOpacity(0.25))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [
                color.withOpacity(0.3), color.withOpacity(0.1)])),
            child: Icon(Icons.school_rounded, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(c['title'] as String, style: const TextStyle(
              color: LC.tPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.calendar_today_rounded, color: LC.tMuted, size: 11),
              const SizedBox(width: 4),
              Text('${c['date']}  •  ${c['time']}  •  ${c['duration']}',
                style: const TextStyle(color: LC.tMuted, fontSize: 11)),
            ]),
          ])),
          GestureDetector(
            onTap: () => _deleteClass(c['id'] as String),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: LC.rose.withOpacity(0.12),
                border: Border.all(color: LC.rose.withOpacity(0.3))),
              child: const Icon(Icons.delete_outline_rounded,
                color: LC.rose, size: 18)),
          ),
        ]),
        if ((c['topic'] as String).isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('📌 ${c['topic']}',
            style: const TextStyle(color: LC.tMuted, fontSize: 12)),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Row(children: [
            Icon(Icons.link_rounded, color: color, size: 14),
            const SizedBox(width: 8),
            Expanded(child: Text(c['link'] as String,
              style: const TextStyle(color: LC.tMuted, fontSize: 11),
              overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ]),
    );
  }
}



