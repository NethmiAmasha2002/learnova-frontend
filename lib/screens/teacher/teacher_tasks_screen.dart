import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../utils/colors.dart';

class TeacherTasksScreen extends StatefulWidget {
  final String userName;
  const TeacherTasksScreen({super.key, required this.userName});
  @override
  State<TeacherTasksScreen> createState() => _TeacherTasksScreenState();
}

class _TeacherTasksScreenState extends State<TeacherTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';

  PlatformFile? _pickedNote;
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _uploadDone = false;
  List<Map<String, dynamic>> _notes = [];
  bool _loadingNotes = false;

  List<Map<String, dynamic>> _submissions = [];
  bool _loadingSubmissions = false;
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _downloadDone = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 0) _fetchSubmissions();
      if (_tabCtrl.index == 1) _fetchNotes();
    });
    _fetchSubmissions();
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _fetchSubmissions() async {
    setState(() => _loadingSubmissions = true);
    try {
      final dio = Dio();
      final res = await dio.get('$_baseUrl/assignments');
      final list = res.data['submissions'] as List;
      setState(() {
        _submissions = list.map((s) => {
          'id': s['_id'] ?? s['id'] ?? '',
          'filename': s['filename'] ?? '',
          'originalName': s['originalName'] ?? 'File',
          'size': s['size'] ?? '',
          'studentName': s['studentName'] ?? 'Student',
          'url': s['url'] ?? '',
          'uploadedAt': s['uploadedAt'] ?? '',
        }).toList();
        _loadingSubmissions = false;
      });
    } catch (e) {
      setState(() => _loadingSubmissions = false);
    }
  }

  Future<void> _fetchNotes() async {
    setState(() => _loadingNotes = true);
    try {
      final dio = Dio();
      final res = await dio.get('$_baseUrl/notes');
      setState(() {
        _notes = List<Map<String, dynamic>>.from(res.data['files']);
        _loadingNotes = false;
      });
    } catch (e) {
      setState(() => _loadingNotes = false);
    }
  }

  Future<void> _pickNote() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() { _pickedNote = result.files.first; _uploadDone = false; });
    }
  }

  Future<void> _uploadNote() async {
    if (_pickedNote == null || _pickedNote!.path == null) return;
    setState(() { _isUploading = true; _uploadProgress = 0; });
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          _pickedNote!.path!, filename: _pickedNote!.name),
      });
      await dio.post('$_baseUrl/notes/upload', data: formData,
        onSendProgress: (sent, total) {
          setState(() => _uploadProgress = sent / total);
        });
      setState(() {
        _isUploading = false; _uploadDone = true; _pickedNote = null;
      });
      _showSnack('✅ Note uploaded!', LC.green);
      _fetchNotes();
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnack('❌ Upload failed.', LC.rose);
    }
  }

  Future<void> _downloadSubmission(Map<String, dynamic> sub) async {
    final filename = sub['filename'] as String;
    final url = sub['url'] as String;
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
      await dio.download(url, savePath,
        onReceiveProgress: (r, t) {
          if (t != -1) setState(() => _downloadProgress[filename] = r / t);
        });
      setState(() => _downloadDone[filename] = true);
      _showSnack('✅ Downloaded: ${sub['originalName']}', LC.green);
      await OpenFilex.open(savePath);
    } catch (e) {
      setState(() {
        _downloadProgress.remove(filename);
        _downloadDone.remove(filename);
      });
      _showSnack('❌ Download failed.', LC.rose);
    }
  }

  Future<void> _deleteNote(String id) async {
    try {
      final dio = Dio();
      await dio.delete('$_baseUrl/notes/$id');
      _showSnack('🗑️ Note deleted', LC.rose);
      _fetchNotes();
    } catch (e) {
      _showSnack('❌ Delete failed', LC.rose);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFE0DEFF), LC.gold]).createShader(b),
            child: const Text('Manage Content', style: TextStyle(
              color: Colors.white, fontSize: 26,
              fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 4),
          const Text('Submissions, notes & payments',
            style: TextStyle(color: LC.tMuted, fontSize: 13)),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: LC.glass,
              border: Border.all(color: LC.glassBd)),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [LC.gold, LC.accent])),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: LC.tMuted,
              labelStyle: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: '📋 Submissions'),
                Tab(text: '📁 Notes'),
                Tab(text: '💳 Payments'),
              ],
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [

            // ── Tab 1: Submissions ──
            _loadingSubmissions
              ? const Center(child: CircularProgressIndicator(
                  color: LC.primary))
              : RefreshIndicator(
                  color: LC.gold,
                  onRefresh: _fetchSubmissions,
                  child: _submissions.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 100),
                        Center(child: Column(children: [
                          Text('📭', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('No submissions yet',
                            style: TextStyle(
                              color: LC.tMuted, fontSize: 14)),
                        ])),
                      ])
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          hPad, 0, hPad, bottomPad + 130),
                        itemCount: _submissions.length,
                        itemBuilder: (_, i) =>
                          _submissionCard(_submissions[i]),
                      ),
                ),

            // ── Tab 2: Notes ──
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                hPad, 0, hPad, bottomPad + 130),
              child: Column(children: [
                _uploadNoteBox(),
                const SizedBox(height: 20),
                if (_loadingNotes)
                  const Center(child: CircularProgressIndicator(
                    color: LC.gold))
                else if (_notes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: LC.glass,
                      border: Border.all(color: LC.glassBd)),
                    child: const Center(child: Text(
                      'No notes uploaded yet',
                      style: TextStyle(
                        color: LC.tMuted, fontSize: 13))))
                else
                  ..._notes.map((n) => _noteCard(n)),
              ]),
            ),

            // ── Tab 3: Payments ──
            _PaymentsTab(baseUrl: _baseUrl),

          ],
        ),
      ),
    ]);
  }

  Widget _submissionCard(Map<String, dynamic> sub) {
    final filename = sub['filename'] as String? ?? '';
    final isDone = _downloadDone[filename] ?? false;
    final isDownloading =
      _downloadProgress.containsKey(filename) && !isDone;
    final progress = _downloadProgress[filename] ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: LC.glass,
        border: Border.all(color: LC.primary.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: LC.primary.withOpacity(0.15)),
            child: const Icon(Icons.assignment_rounded,
              color: LC.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(sub['originalName'] ?? 'File',
              style: const TextStyle(color: LC.tPrimary,
                fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text('By: ${sub['studentName'] ?? 'Student'} • '
              '${sub['size'] ?? ''}',
              style: const TextStyle(color: LC.tMuted, fontSize: 11)),
          ])),
          GestureDetector(
            onTap: isDone ? null : () => _downloadSubmission(sub),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: isDone
                  ? LinearGradient(colors: [
                      LC.green.withOpacity(0.3),
                      LC.green.withOpacity(0.1)])
                  : const LinearGradient(
                      colors: [LC.primary, LC.accent])),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isDone
                  ? Icons.check_rounded : Icons.download_rounded,
                  color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(isDone ? 'Saved'
                  : isDownloading ? '...' : 'Open',
                  style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        if (isDownloading) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(
                LC.primary),
              minHeight: 5)),
        ],
      ]),
    );
  }

  Widget _uploadNoteBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: LC.gold.withOpacity(0.4), width: 1.5),
        color: LC.gold.withOpacity(0.04),
      ),
      child: Column(children: [
        Container(width: 56, height: 56,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [
              LC.gold.withOpacity(0.3),
              LC.accent.withOpacity(0.2)])),
          child: const Icon(Icons.upload_file_rounded,
            color: LC.gold, size: 28)),
        const SizedBox(height: 12),
        Text(
          _uploadDone ? '✅ Note Uploaded!'
            : _pickedNote != null
              ? _pickedNote!.name : 'Upload Note for Students',
          style: TextStyle(
            color: _uploadDone ? LC.green
              : _pickedNote != null ? LC.tPrimary : LC.gold,
            fontSize: 14, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          _uploadDone ? 'Students can now download this note'
            : _pickedNote != null
              ? '${(_pickedNote!.size / 1024).toStringAsFixed(1)}'
                ' KB • Tap Upload to share'
              : 'PDF, DOC, JPG • Max 20MB',
          style: const TextStyle(color: LC.tMuted, fontSize: 12),
          textAlign: TextAlign.center),
        if (_isUploading) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.white.withOpacity(0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(LC.gold),
              minHeight: 7)),
          const SizedBox(height: 6),
          Text('Uploading... ${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(color: LC.gold, fontSize: 12)),
        ],
        const SizedBox(height: 14),
        if (!_isUploading && !_uploadDone) Row(children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickNote,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: LC.gold.withOpacity(0.12),
                  border: Border.all(
                    color: LC.gold.withOpacity(0.4))),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.attach_file_rounded,
                    color: LC.gold, size: 16),
                  SizedBox(width: 6),
                  Text('Choose File', style: TextStyle(
                    color: LC.gold, fontSize: 13,
                    fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
          if (_pickedNote != null) ...[
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: _uploadNote,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [LC.gold, LC.accent]),
                    boxShadow: [BoxShadow(
                      color: LC.gold.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 4))]),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    Icon(Icons.cloud_upload_rounded,
                      color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Upload', style: TextStyle(
                      color: Colors.white, fontSize: 13,
                      fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
          ],
        ]),
        if (_uploadDone) GestureDetector(
          onTap: () => setState(() {
            _uploadDone = false; _pickedNote = null;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10, horizontal: 20),
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

  Widget _noteCard(Map<String, dynamic> note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: LC.glass,
        border: Border.all(color: LC.gold.withOpacity(0.2)),
      ),
      child: Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: [
              LC.gold.withOpacity(0.3),
              LC.gold.withOpacity(0.1)])),
          child: const Icon(Icons.picture_as_pdf_rounded,
            color: LC.gold, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(note['originalName'] ?? note['filename'] ?? '',
            style: const TextStyle(color: LC.tPrimary,
              fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(note['size'] ?? '',
            style: const TextStyle(color: LC.tMuted, fontSize: 11)),
        ])),
        GestureDetector(
          onTap: () => _deleteNote(note['id'] as String),
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
    );
  }
}

// ── Payments Tab Widget ──────────────────────────────────────────────────────
class _PaymentsTab extends StatefulWidget {
  final String baseUrl;
  const _PaymentsTab({required this.baseUrl});
  @override
  State<_PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<_PaymentsTab> {
  List<Map<String, dynamic>> _payments = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _loading = true);
    try {
      final dio = Dio();
      final res = await dio.get('${widget.baseUrl}/payments');
      final list = res.data['payments'] as List;
      setState(() {
        _payments = list.map((p) => {
          'id': p['_id'] ?? '',
          'studentName': p['studentName'] ?? 'Student',
          'studentEmail': p['studentEmail'] ?? '',
          'month': p['month'] ?? '',
          'amount': p['amount'] ?? 'LKR 2,500',
          'status': p['status'] ?? 'pending',
          'url': p['url'] ?? '',
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      final dio = Dio();
      await dio.put('${widget.baseUrl}/payments/$id',
        data: {'status': status});
      _fetchPayments();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == 'approved'
          ? '✅ Payment approved!' : '❌ Payment rejected'),
        backgroundColor: status == 'approved' ? LC.green : LC.rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to update'),
        backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.of(context).size.width > 600
      ? MediaQuery.of(context).size.width * 0.1 : 18.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: LC.gold));
    }

    return RefreshIndicator(
      color: LC.gold,
      onRefresh: _fetchPayments,
      child: _payments.isEmpty
        ? ListView(children: const [
            SizedBox(height: 80),
            Center(child: Column(children: [
              Text('💳', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text('No payment receipts yet',
                style: TextStyle(color: LC.tMuted, fontSize: 14)),
            ])),
          ])
        : ListView.builder(
            padding: EdgeInsets.fromLTRB(
              hPad, 12, hPad, bottomPad + 130),
            itemCount: _payments.length,
            itemBuilder: (_, i) {
              final p = _payments[i];
              final status = p['status'] as String;
              final color = status == 'approved' ? LC.green
                : status == 'rejected' ? LC.rose : LC.gold;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: LC.glass,
                  border: Border.all(
                    color: color.withOpacity(0.25))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.15)),
                      child: Icon(Icons.receipt_rounded,
                        color: color, size: 22)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Text(p['studentName'] as String,
                        style: const TextStyle(
                          color: LC.tPrimary, fontSize: 13,
                          fontWeight: FontWeight.w700)),
                      Text('${p['month']} • ${p['amount']}',
                        style: const TextStyle(
                          color: LC.tMuted, fontSize: 11)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: color.withOpacity(0.12)),
                      child: Text(
                        status == 'approved' ? '✅ Approved'
                          : status == 'rejected' ? '❌ Rejected'
                          : '⏳ Pending',
                        style: TextStyle(color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  if (status == 'pending') ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _updateStatus(
                            p['id'] as String, 'rejected'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: LC.rose.withOpacity(0.12),
                              border: Border.all(
                                color: LC.rose.withOpacity(0.4))),
                            child: const Row(
                              mainAxisAlignment:
                                MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded,
                                  color: LC.rose, size: 16),
                                SizedBox(width: 6),
                                Text('Reject', style: TextStyle(
                                  color: LC.rose, fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                              ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _updateStatus(
                            p['id'] as String, 'approved'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [LC.green, LC.accent])),
                            child: const Row(
                              mainAxisAlignment:
                                MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text('Approve', style: TextStyle(
                                  color: Colors.white, fontSize: 13,
                                  fontWeight: FontWeight.w800)),
                              ]),
                          ),
                        ),
                      ),
                    ]),
                  ],
                ]),
              );
            },
          ),
    );
  }
}



