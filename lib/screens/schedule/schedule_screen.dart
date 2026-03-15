import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import '../../utils/colors.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _allClasses = [];
  bool _loading = false;

  late final List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _days = List.generate(14, (i) => today.add(Duration(days: i)));
    _fetchClasses();
  }

  Future<void> _fetchClasses() async {
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final res = await dio.get('$_baseUrl/classes');
      final list = res.data['classes'] as List;
      setState(() {
        _allClasses = list.map((c) => {
          'id': c['_id'] ?? '',
          'title': c['title'] ?? '',
          'date': c['date'] ?? '',
          'time': c['time'] ?? '',
          'duration': c['duration'] ?? '',
          'link': c['link'] ?? '',
          'topic': c['topic'] ?? '',
          'status': c['status'] ?? 'upcoming',
          'color': LC.primary,
          'icon': Icons.school_rounded,
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredClasses {
    final sel = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2,'0')}-${_selectedDate.day.toString().padLeft(2,'0')}';
    return _allClasses.where((c) => c['date'] == sel).toList();
  }

  bool _hasClass(DateTime day) {
    final sel = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
    return _allClasses.any((c) => c['date'] == sel);
  }

  String _dayLabel(DateTime d) {
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return days[d.weekday - 1];
  }

  String _monthName(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[d.month - 1];
  }

  void _copyLink(BuildContext context, String link, Color color) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(children: [
        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text('Link copied!'),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? size.width * 0.1 : 18.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final filtered = _filteredClasses;

    return RefreshIndicator(
      color: LC.primary,
      onRefresh: _fetchClasses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad + 130),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFE0DEFF), LC.accent]).createShader(b),
            child: const Text('Class Schedule', style: TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 4),
          const Text('Pull to refresh schedule',
            style: TextStyle(color: LC.tMuted, fontSize: 13)),
          const SizedBox(height: 20),

          // Selected date display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [
                LC.primary.withOpacity(0.2), LC.accent.withOpacity(0.1)]),
              border: Border.all(color: LC.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.calendar_today_rounded, color: LC.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                '${_dayLabel(_selectedDate)}, ${_selectedDate.day} ${_monthName(_selectedDate)} ${_selectedDate.year}',
                style: const TextStyle(
                  color: LC.tPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: filtered.isEmpty
                    ? LC.tMuted.withOpacity(0.1)
                    : LC.green.withOpacity(0.15)),
                child: Text(
                  filtered.isEmpty
                    ? 'No classes'
                    : '${filtered.length} class${filtered.length > 1 ? 'es' : ''}',
                  style: TextStyle(
                    color: filtered.isEmpty ? LC.tMuted : LC.green,
                    fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Date strip
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final day = _days[i];
                final isSelected = day.day == _selectedDate.day &&
                    day.month == _selectedDate.month &&
                    day.year == _selectedDate.year;
                final hasClass = _hasClass(day);
                final isToday = day.day == DateTime.now().day &&
                    day.month == DateTime.now().month;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: size.width > 600 ? 64 : 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: isSelected ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [LC.primary, LC.accent]) : null,
                      color: isSelected ? null : LC.glass,
                      border: Border.all(
                        color: isSelected ? Colors.transparent
                          : isToday ? LC.primary.withOpacity(0.5) : LC.glassBd,
                        width: isToday && !isSelected ? 1.5 : 1),
                      boxShadow: isSelected ? [BoxShadow(
                        color: LC.primary.withOpacity(0.45), blurRadius: 14)] : [],
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(_dayLabel(day), style: TextStyle(
                        color: isSelected ? Colors.white : LC.tMuted,
                        fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${day.day}', style: TextStyle(
                        color: isSelected ? Colors.white : LC.tPrimary,
                        fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Container(width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasClass
                            ? (isSelected ? Colors.white : LC.green)
                            : Colors.transparent)),
                    ]),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Class list
          Text(
            filtered.isEmpty ? 'No Classes Scheduled' : 'Classes on this day',
            style: const TextStyle(
              color: LC.tPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: LC.primary))
          else if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: LC.glass,
                border: Border.all(color: LC.glassBd)),
              child: const Column(children: [
                Text('📅', style: TextStyle(fontSize: 40)),
                SizedBox(height: 12),
                Text('No classes on this day',
                  style: TextStyle(color: LC.tMuted, fontSize: 14)),
              ]),
            )
          else
            ...filtered.map((c) => _classCard(c, context)),

          const SizedBox(height: 20),

          // All upcoming
          Row(children: [
            const Text('All Upcoming Classes', style: TextStyle(
              color: LC.tPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
            const Spacer(),
            GestureDetector(
              onTap: _fetchClasses,
              child: const Text('Refresh →',
                style: TextStyle(color: LC.accent, fontSize: 12,
                  fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 12),
          if (_allClasses.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: LC.glass,
                border: Border.all(color: LC.glassBd)),
              child: const Center(child: Text('No classes scheduled yet',
                style: TextStyle(color: LC.tMuted, fontSize: 13))))
          else
            ..._allClasses.map((c) => _miniClassRow(c, context)),
        ]),
      ),
    );
  }

  Widget _classCard(Map<String, dynamic> c, BuildContext context) {
    final color = c['color'] as Color;
    final isLive = c['status'] == 'live';
    final link = c['link'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: LC.glass,
        border: Border.all(
          color: isLive ? color.withOpacity(0.7) : color.withOpacity(0.25),
          width: isLive ? 1.5 : 1),
        boxShadow: isLive
          ? [BoxShadow(color: color.withOpacity(0.25), blurRadius: 24)] : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 50, height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [
                color.withOpacity(0.35), color.withOpacity(0.1)])),
            child: Icon(c['icon'] as IconData, color: color, size: 24)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['title'] as String, style: const TextStyle(
              color: LC.tPrimary, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Row(children: [
              const Icon(Icons.access_time_rounded, color: LC.tMuted, size: 12),
              const SizedBox(width: 4),
              Text('${c['time']}  •  ${c['duration']}',
                style: const TextStyle(color: LC.tMuted, fontSize: 12)),
            ]),
          ])),
          if (isLive) Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: LC.rose.withOpacity(0.2)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: LC.rose,
                  boxShadow: [BoxShadow(
                    color: LC.rose.withOpacity(0.9), blurRadius: 6)])),
              const SizedBox(width: 5),
              const Text('LIVE', style: TextStyle(
                color: LC.rose, fontSize: 10, fontWeight: FontWeight.w900)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.link_rounded, color: color, size: 15),
              const SizedBox(width: 8),
              Expanded(child: Text(link,
                style: const TextStyle(color: LC.tMuted, fontSize: 11),
                overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _copyLink(context, link, color),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: color.withOpacity(0.12),
                      border: Border.all(color: color.withOpacity(0.3))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.copy_rounded, color: color, size: 14),
                      const SizedBox(width: 6),
                      Text('Copy Link', style: TextStyle(
                        color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _copyLink(context, link, color),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(colors: isLive
                        ? [LC.rose, const Color(0xFFCC3366)]
                        : [color, color.withOpacity(0.7)]),
                      boxShadow: [BoxShadow(
                        color: (isLive ? LC.rose : color).withOpacity(0.4),
                        blurRadius: 10, offset: const Offset(0, 3))]),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(isLive
                        ? Icons.videocam_rounded : Icons.calendar_today_rounded,
                        color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(isLive ? '🔴 Join Now' : 'Upcoming',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _miniClassRow(Map<String, dynamic> c, BuildContext context) {
    final color = c['color'] as Color;
    final isLive = c['status'] == 'live';
    final dateStr = c['date'] as String;
    DateTime? date;
    try { date = DateTime.parse(dateStr); } catch (_) {}

    return GestureDetector(
      onTap: () { if (date != null) setState(() => _selectedDate = date!); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: LC.glass,
          border: Border.all(color: LC.glassBd)),
        child: Row(children: [
          Container(width: 42, height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.15)),
            child: Icon(c['icon'] as IconData, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['title'] as String, style: const TextStyle(
              color: LC.tPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('${c['date']}  •  ${c['time']}',
              style: const TextStyle(color: LC.tMuted, fontSize: 11)),
          ])),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: LC.rose.withOpacity(0.15)),
              child: const Text('LIVE', style: TextStyle(
                color: LC.rose, fontSize: 10, fontWeight: FontWeight.w900)))
          else
            const Icon(Icons.arrow_forward_ios_rounded, color: LC.tMuted, size: 13),
        ]),
      ),
    );
  }
}



