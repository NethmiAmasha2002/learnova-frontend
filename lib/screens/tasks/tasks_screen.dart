import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../utils/colors.dart';

class TasksScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  const TasksScreen({super.key, required this.userName, required this.userEmail});
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';

  // Upload state
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _uploadDone = false;

  // Notes download state
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloadDone = {};

  final _assignments = [
    {'title': 'Quadratic Equations — Set A', 'due': 'Due Today',
     'status': 'pending', 'color': LC.rose, 'progress': 0.0,
     'desc': 'Solve problems 1–20 from page 145'},
    {'title': 'Integration Practice Sheet', 'due': 'Due Tomorrow',
     'status': 'inprogress', 'color': LC.gold, 'progress': 0.45,
     'desc': 'Complete all 15 integration problems'},
    {'title': 'Trigonometry Identities', 'due': 'Due in 3 days',
     'status': 'done', 'color': LC.green, 'progress': 1.0,
     'desc': 'Prove the 10 trig identities'},
    {'title': 'Statistics — Mean & Median', 'due': 'Due in 5 days',
     'status': 'pending', 'color': LC.accent, 'progress': 0.0,
     'desc': 'Data analysis worksheet page 201'},
  ];

  List<Map<String, dynamic>> _notes = [];
  bool _loadingNotes = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1 && _notes.isEmpty) _fetchNotes();
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  // ── Pick file ──
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _uploadDone = false;
        _uploadProgress = 0;
      });
    }
  }

  // ── Upload to backend ──
  Future<void> _uploadAssignment() async {
    if (_pickedFile == null || _pickedFile!.path == null) return;
    setState(() { _isUploading = true; _uploadProgress = 0; });

    try {
      final dio = Dio();
final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _pickedFile!.path!,
          filename: _pickedFile!.name,
        ),
        'studentName': widget.userName,
        'studentEmail': widget.userEmail,
      });

      await dio.post(
        '$_baseUrl/assignments/upload',
        data: formData,
        onSendProgress: (sent, total) {
          setState(() => _uploadProgress = sent / total);
        },
      );

      setState(() {
        _isUploading = false;
        _uploadDone = true;
        _pickedFile = null;
      });
      _showSnack('✅ Assignment submitted to teacher!', LC.green);
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnack('❌ Upload failed. Check your connection.', LC.rose);
    }
  }

  // ── Fetch notes from backend ──
  Future<void> _fetchNotes() async {
    setState(() => _loadingNotes = true);
    try {
      final dio = Dio();
      final res = await dio.get('$_baseUrl/notes');
      final files = res.data['files'] as List;
      setState(() {
        _notes = files.map((f) => {
          'title': f['originalName'] ?? f['filename'],
          'size': f['size'] ?? '—',
          'url': f['url'],
          'filename': f['filename'],
          'color': LC.primary,
        }).toList();
        _loadingNotes = false;
      });
    } catch (e) {
      setState(() {
        _loadingNotes = false;
        _notes = [
          {'title': 'Chapter 5 — Algebra Fundamentals', 'size': '2.4 MB',
           'url': 'https://learnova-backend-production.up.railway.app/uploads/notes/sample1.pdf',
           'filename': 'algebra.pdf', 'color': LC.primary},
          {'title': 'Calculus Formula Sheet', 'size': '1.1 MB',
           'url': 'https://learnova-backend-production.up.railway.app/uploads/notes/sample2.pdf',
           'filename': 'calculus.pdf', 'color': LC.accent},
          {'title': 'Trigonometry Reference Guide', 'size': '3.7 MB',
           'url': 'https://learnova-backend-production.up.railway.app/uploads/notes/sample3.pdf',
           'filename': 'trig.pdf', 'color': LC.gold},
        ];
      });
    }
  }

  // ── Download note ──
  Future<void> _downloadNote(Map<String, dynamic> note) async {
    final filename = note['filename'] as String;
    final url = note['url'] as String;

    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnack('❌ Storage permission denied', LC.rose);
        return;
      }
    }

    setState(() {
      _downloadProgress[filename] = 0;
      _downloadDone[filename] = false;
    });

    try {
      final dio = Dio();
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) dir = await getExternalStorageDirectory();
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final savePath = '${dir!.path}/$filename';

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() => _downloadProgress[filename] = received / total);
          }
        },
      );

      setState(() => _downloadDone[filename] = true);
      _showSnack('✅ Downloaded: $filename', LC.green);
      await OpenFilex.open(savePath);
    } catch (e) {
      setState(() {
        _downloadProgress.remove(filename);
        _downloadDone.remove(filename);
      });
      _showSnack('❌ Download failed. Check connection.', LC.rose);
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? size.width * 0.1 : 18.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFE0DEFF), LC.accent]).createShader(b),
            child: const Text('Tasks & Notes', style: TextStyle(
              color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 4),
          const Text('Assignments, notes & uploads',
            style: TextStyle(color: LC.tMuted, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: LC.glass,
              border: Border.all(color: LC.glassBd),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(colors: [LC.primary, LC.accent]),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: LC.tMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: const [Tab(text: '📝 Assignments'), Tab(text: '📁 Notes')],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            // ── Assignments Tab ──
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad + 130),
              child: Column(children: [
                _uploadBox(),
                const SizedBox(height: 16),
                ..._assignments.map((a) => _assignCard(a)),
              ]),
            ),
            // ── Notes Tab ──
            _loadingNotes
              ? const Center(child: CircularProgressIndicator(color: LC.primary))
              : _notes.isEmpty
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📁', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      const Text('No notes yet',
                        style: TextStyle(color: LC.tMuted, fontSize: 14)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _fetchNotes,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: const LinearGradient(
                              colors: [LC.primary, LC.accent])),
                          child: const Text('Refresh', style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)))),
                    ]))
                : RefreshIndicator(
                    color: LC.primary,
                    onRefresh: _fetchNotes,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bottomPad + 130),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Text('Pull to refresh',
                            style: TextStyle(color: LC.tMuted, fontSize: 11),
                            textAlign: TextAlign.center)),
                        ..._notes.map((n) => _noteRow(n)),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    ]);
  }

  Widget _uploadBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LC.primary.withOpacity(0.4), width: 1.5),
        color: LC.primary.withOpacity(0.04),
      ),
      child: Column(children: [
        Container(width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [
              LC.primary.withOpacity(0.3), LC.accent.withOpacity(0.2)])),
          child: const Icon(Icons.cloud_upload_rounded, color: LC.primary, size: 28)),
        const SizedBox(height: 12),
        Text(
          _uploadDone
            ? '✅ Assignment Submitted!'
            : _pickedFile != null
              ? _pickedFile!.name
              : 'Upload Assignment',
          style: TextStyle(
            color: _uploadDone ? LC.green : _pickedFile != null
              ? LC.tPrimary : LC.primary,
            fontSize: 14, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          _uploadDone
            ? 'Teacher will review your submission'
            : _pickedFile != null
              ? '${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB  •  Tap Submit to send'
              : 'PDF, DOC, JPG • Max 10MB',
          style: const TextStyle(color: LC.tMuted, fontSize: 12),
          textAlign: TextAlign.center),

        if (_isUploading) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(LC.primary),
              minHeight: 7,
            )),
          const SizedBox(height: 6),
          Text('Uploading... ${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(color: LC.primary, fontSize: 12)),
        ],

        const SizedBox(height: 14),

        if (!_isUploading && !_uploadDone) Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: LC.primary.withOpacity(0.12),
                  border: Border.all(color: LC.primary.withOpacity(0.4))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.attach_file_rounded, color: LC.primary, size: 16),
                    SizedBox(width: 6),
                    Text('Choose File', style: TextStyle(
                      color: LC.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
              ),
            ),
          ),
          if (_pickedFile != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _uploadAssignment,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: [LC.primary, LC.accent]),
                    boxShadow: [BoxShadow(
                      color: LC.primary.withOpacity(0.4),
                      blurRadius: 14, offset: const Offset(0, 4))]),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Submit', style: TextStyle(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                    ]),
                ),
              ),
            ),
          ],
        ]),

        if (_uploadDone) GestureDetector(
          onTap: () => setState(() { _uploadDone = false; _pickedFile = null; }),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: LC.glass,
              border: Border.all(color: LC.glassBd)),
            child: const Text('Upload Another',
              style: TextStyle(color: LC.tMuted, fontSize: 13,
                fontWeight: FontWeight.w600))),
        ),
      ]),
    );
  }

  Widget _assignCard(Map<String, dynamic> a) {
    final color = a['color'] as Color;
    final status = a['status'] as String;
    final progress = a['progress'] as double;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: LC.glass,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: color.withOpacity(0.15)),
            child: Icon(Icons.assignment_outlined, color: color, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a['title'] as String, style: const TextStyle(
                color: LC.tPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(a['due'] as String, style: TextStyle(
                color: status == 'pending' ? LC.rose : LC.tMuted,
                fontSize: 11.5, fontWeight: FontWeight.w600)),
            ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withOpacity(0.12)),
            child: Text(
              status == 'done' ? '✅ Done'
                : status == 'inprogress' ? '🔄 In Progress' : '⏳ Pending',
              style: TextStyle(color: color, fontSize: 10,
                fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 8),
        Text(a['desc'] as String, style: const TextStyle(
          color: LC.tMuted, fontSize: 12, height: 1.4)),
        if (status != 'done') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ))),
            const SizedBox(width: 8),
            Text('${(progress * 100).toInt()}%',
              style: TextStyle(color: color, fontSize: 11,
                fontWeight: FontWeight.w700)),
          ]),
        ],
      ]),
    );
  }

  Widget _noteRow(Map<String, dynamic> n) {
    final color = n['color'] as Color;
    final filename = n['filename'] as String;
    final isDownloading = _downloadProgress.containsKey(filename) &&
                          !(_downloadDone[filename] ?? false);
    final isDone = _downloadDone[filename] ?? false;
    final progress = _downloadProgress[filename] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: LC.glass,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 46, height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [
                color.withOpacity(0.3), color.withOpacity(0.1)])),
            child: Icon(Icons.picture_as_pdf_rounded, color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n['title'] as String, style: const TextStyle(
                color: LC.tPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(n['size'] as String, style: const TextStyle(
                color: LC.tMuted, fontSize: 11)),
            ])),
          GestureDetector(
            onTap: isDone ? null : () => _downloadNote(n),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isDone
                  ? LinearGradient(colors: [
                      LC.green.withOpacity(0.3), LC.green.withOpacity(0.1)])
                  : LinearGradient(colors: [
                      color.withOpacity(0.3), color.withOpacity(0.1)]),
                border: Border.all(color: isDone
                  ? LC.green.withOpacity(0.4) : color.withOpacity(0.4))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  isDone ? Icons.check_circle_rounded : Icons.download_rounded,
                  color: isDone ? LC.green : color, size: 14),
                const SizedBox(width: 4),
                Text(
                  isDone ? 'Saved' : isDownloading ? '...' : 'Download',
                  style: TextStyle(
                    color: isDone ? LC.green : color,
                    fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        if (isDownloading) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ))),
            const SizedBox(width: 8),
            Text('${(progress * 100).toInt()}%',
              style: TextStyle(color: color, fontSize: 11,
                fontWeight: FontWeight.w700)),
          ]),
        ],
      ]),
    );
  }
}



