import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/colors.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userName;
  final String userEmail;
  const ProfileScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _baseUrl = 'https://learnova-backend-production.up.railway.app/api';
  File? _profileImage;
  List<Map<String, dynamic>> _payments = [];
  bool _loadingPayments = false;
  bool _notificationsEnabled = true;
  bool _uploadingReceipt = false;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() => _loadingPayments = true);
    try {
      final dio = Dio();
      final email = Uri.encodeComponent(widget.userEmail.isNotEmpty
        ? widget.userEmail : widget.userName);
      final res = await dio.get('$_baseUrl/payments/student/$email');
      final list = res.data['payments'] as List;
      setState(() {
        _payments = list.map((p) => {
          'id': p['_id'] ?? '',
          'month': p['month'] ?? '',
          'amount': p['amount'] ?? 'LKR 2,500',
          'status': p['status'] ?? 'pending',
          'createdAt': p['createdAt'] ?? '',
        }).toList();
        _loadingPayments = false;
      });
    } catch (e) {
      setState(() => _loadingPayments = false);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        setState(() => _profileImage = File(picked.path));
        _showSnack('✅ Profile photo updated!', LC.green);
      }
    } catch (e) {
      _showSnack('❌ Could not pick image', LC.rose);
    }
  }

  Future<void> _uploadPaymentReceipt() async {
    final now = DateTime.now();
    final months = ['January','February','March','April','May','June',
      'July','August','September','October','November','December'];
    final currentMonth = '${months[now.month - 1]} ${now.year}';

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.first.path == null) return;

    setState(() => _uploadingReceipt = true);
    try {
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          result.files.first.path!,
          filename: result.files.first.name),
        'studentEmail': widget.userEmail.isNotEmpty
          ? widget.userEmail : widget.userName,
        'studentName': widget.userName,
        'month': currentMonth,
        'amount': 'LKR 2,500',
      });
      await dio.post('$_baseUrl/payments/upload', data: formData);
      setState(() => _uploadingReceipt = false);
      _showSnack('✅ Receipt uploaded! Waiting for teacher approval.', LC.green);
      _fetchPayments();
    } catch (e) {
      setState(() => _uploadingReceipt = false);
      _showSnack('❌ Upload failed. Check connection.', LC.rose);
    }
  }

  void _showChangePassword() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    bool hideOld = true;
    bool hideNew = true;
    bool hideConfirm = true;

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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2)))),
              const SizedBox(height: 20),
              const Text('Change Password', style: TextStyle(
                color: LC.tPrimary, fontSize: 22,
                fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              _passField('Current Password', oldPassCtrl,
                hideOld, () => setModalState(() => hideOld = !hideOld)),
              const SizedBox(height: 14),
              _passField('New Password', newPassCtrl,
                hideNew, () => setModalState(() => hideNew = !hideNew)),
              const SizedBox(height: 14),
              _passField('Confirm New Password', confirmCtrl,
                hideConfirm,
                () => setModalState(() => hideConfirm = !hideConfirm)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: loading ? null : () async {
                  if (newPassCtrl.text != confirmCtrl.text) {
                    _showSnack('Passwords do not match!', LC.rose);
                    return;
                  }
                  if (newPassCtrl.text.length < 6) {
                    _showSnack('Password must be 6+ characters', LC.rose);
                    return;
                  }
                  setModalState(() => loading = true);
                  final result = await AuthService.resetPassword(
                    email: widget.userEmail.isNotEmpty
                      ? widget.userEmail : widget.userName,
                    newPassword: newPassCtrl.text.trim(),
                  );
                  setModalState(() => loading = false);
                  if (result['success']) {
                    Navigator.pop(context);
                    _showSnack('✅ Password changed!', LC.green);
                  } else {
                    _showSnack(
                      result['message'] ?? 'Failed', LC.rose);
                  }
                },
                child: Container(
                  width: double.infinity, height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [LC.primary, LC.accent])),
                  child: Center(child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Change Password', style: TextStyle(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w900))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

 void _showHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
          MediaQuery.of(context).padding.bottom + 24),
        decoration: BoxDecoration(
          color: LC.bg2,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28)),
          border: Border.all(color: Colors.white.withOpacity(0.08))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.white.withOpacity(0.2)))),
          const SizedBox(height: 20),
          const Text('Help & Support', style: TextStyle(
            color: LC.tPrimary, fontSize: 22,
            fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          _helpRow(Icons.email_outlined, 'Email Support',
            'support@learnova.lk', LC.primary),
          _helpRow(Icons.phone_outlined, 'Call Us',
            '+94 77 000 0000', LC.green),
          _helpRow(Icons.chat_outlined, 'WhatsApp',
            '+94 77 000 0000', LC.accent),
          _helpRow(Icons.web_outlined, 'Website',
            'www.learnova.lk', LC.gold),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: LC.primary.withOpacity(0.08),
              border: Border.all(color: LC.primary.withOpacity(0.2))),
            child: const Column(children: [
              Text('📚 FAQ', style: TextStyle(
                color: LC.tPrimary, fontSize: 14,
                fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text(
                'For payment issues, contact teacher via chat.\n'
                'For technical issues, email support.\n'
                'Class schedule questions — check Schedule tab.',
                style: TextStyle(color: LC.tMuted, fontSize: 12,
                  height: 1.5),
                textAlign: TextAlign.center),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [LC.bg2, LC.bg3]),
            border: Border.all(
              color: LC.rose.withOpacity(0.3))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: LC.rose.withOpacity(0.15)),
              child: const Icon(Icons.logout_rounded,
                color: LC.rose, size: 30)),
            const SizedBox(height: 16),
            const Text('Logout?', style: TextStyle(
              color: LC.tPrimary, fontSize: 20,
              fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Are you sure you want to logout?',
              style: TextStyle(color: LC.tMuted, fontSize: 13),
              textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withOpacity(0.07),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1))),
                    child: const Center(child: Text('Cancel',
                      style: TextStyle(
                        color: LC.tMuted,
                        fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/', (route) => false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [LC.rose, Color(0xFFCC3366)])),
                    child: const Center(child: Text('Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900))),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _passField(String label, TextEditingController ctrl,
      bool hide, VoidCallback onToggle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(label, style: const TextStyle(
        color: LC.tMuted, fontSize: 12,
        fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withOpacity(0.05),
          border: Border.all(color: Colors.white.withOpacity(0.09))),
        child: TextField(
          controller: ctrl,
          obscureText: hide,
          style: const TextStyle(color: LC.tPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.lock_outline_rounded,
              color: Colors.white.withOpacity(0.3), size: 19),
            suffixIcon: IconButton(
              icon: Icon(
                hide ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
                color: Colors.white.withOpacity(0.3), size: 19),
              onPressed: onToggle),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16, horizontal: 4)),
        ),
      ),
    ]);
  }

  Widget _helpRow(IconData icon, String title, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: LC.glass,
        border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: color.withOpacity(0.15)),
          child: Icon(icon, color: color, size: 17)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
            color: LC.tPrimary, fontSize: 13,
            fontWeight: FontWeight.w700)),
          Text(value, style: const TextStyle(
            color: LC.tMuted, fontSize: 11)),
        ]),
      ]),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hPad = size.width > 600 ? size.width * 0.1 : 18.0;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad + 130),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [

        // ── Profile Card ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A3FCC),
                Color(0xFF1E6BCC),
                Color(0xFF00C9DE)]),
            boxShadow: [BoxShadow(
              color: LC.primary.withOpacity(0.4),
              blurRadius: 30, offset: const Offset(0, 8))],
          ),
          child: Column(children: [
            Stack(alignment: Alignment.bottomRight, children: [
              GestureDetector(
                onTap: _pickProfileImage,
                child: Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4), width: 3),
                    image: _profileImage != null
                      ? DecorationImage(
                          image: FileImage(_profileImage!),
                          fit: BoxFit.cover)
                      : null),
                  child: _profileImage == null
                    ? Center(child: Text(
                        widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white, fontSize: 38,
                          fontWeight: FontWeight.w900)))
                    : null),
              ),
              Container(width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: LC.green,
                  border: Border.all(color: Colors.white, width: 2)),
                child: const Icon(Icons.camera_alt_rounded,
                  color: Colors.white, size: 13)),
            ]),
            const SizedBox(height: 14),
            Text(widget.userName, style: const TextStyle(
              color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(widget.userEmail.isNotEmpty
              ? widget.userEmail : 'student@learnova.lk',
              style: TextStyle(
                color: Colors.white.withOpacity(0.75), fontSize: 13)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.18)),
              child: const Text('✅ Active Member', style: TextStyle(
                color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w700)),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Payment ──
        const Text('💳 Subscription & Payment',
          style: TextStyle(color: LC.tPrimary, fontSize: 15,
            fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(colors: [
              LC.gold.withOpacity(0.12),
              LC.rose.withOpacity(0.06)]),
            border: Border.all(color: LC.gold.withOpacity(0.3)),
          ),
          child: Column(children: [
            Row(children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(colors: [
                    LC.gold.withOpacity(0.3),
                    LC.gold.withOpacity(0.1)])),
                child: const Icon(Icons.workspace_premium_rounded,
                  color: LC.gold, size: 26)),
              const SizedBox(width: 14),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text('Premium Plan', style: TextStyle(
                  color: LC.tPrimary, fontSize: 15,
                  fontWeight: FontWeight.w800)),
                Text('Full access — sessions, notes & chat',
                  style: TextStyle(color: LC.tMuted, fontSize: 12)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: LC.green.withOpacity(0.15)),
                child: const Text('Active', style: TextStyle(
                  color: LC.green, fontSize: 12,
                  fontWeight: FontWeight.w800)),
              ),
            ]),
            const SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.07)),
            const SizedBox(height: 12),
            _payRow('Plan', 'Monthly Premium'),
            _payRow('Amount', 'LKR 2,500 / month'),
            _payRow('Status', _payments.isNotEmpty
              ? (_payments.first['status'] == 'approved'
                ? '✅ Paid' : _payments.first['status'] == 'pending'
                ? '⏳ Pending Approval' : '❌ Rejected')
              : '❌ No Payment'),
            const SizedBox(height: 16),

            // Upload receipt button
            GestureDetector(
              onTap: _uploadingReceipt ? null : _uploadPaymentReceipt,
              child: Container(
                width: double.infinity, height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [LC.gold, Color(0xFFFF9500)]),
                  boxShadow: [BoxShadow(
                    color: LC.gold.withOpacity(0.4),
                    blurRadius: 16, offset: const Offset(0, 5))],
                ),
                child: Center(child: _uploadingReceipt
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.upload_file_rounded,
                        color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Upload Payment Receipt',
                        style: TextStyle(color: Colors.white,
                          fontSize: 14, fontWeight: FontWeight.w900)),
                    ])),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        // ── My Information ──
        const Text('👤 My Information', style: TextStyle(
          color: LC.tPrimary, fontSize: 15,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        _infoRow(Icons.person_outline_rounded, 'Full Name',
          widget.userName, LC.primary),
        _infoRow(Icons.email_outlined, 'Email',
          widget.userEmail.isNotEmpty
            ? widget.userEmail : 'Not set',
          LC.accent),
        _infoRow(Icons.school_outlined, 'Class',
          'Mathematics — Grade 11', LC.gold),
        _infoRow(Icons.calendar_today_outlined, 'Joined',
          'March 2026', LC.rose),

        const SizedBox(height: 24),

        // ── Payment History ──
        const Text('🧾 Payment History', style: TextStyle(
          color: LC.tPrimary, fontSize: 15,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),

        if (_loadingPayments)
          const Center(child: CircularProgressIndicator(
            color: LC.gold))
        else if (_payments.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: LC.glass,
              border: Border.all(color: LC.glassBd)),
            child: const Center(child: Text(
              'No payment history yet.\nUpload your receipt above!',
              style: TextStyle(color: LC.tMuted, fontSize: 13),
              textAlign: TextAlign.center)))
        else
          ..._payments.map((p) {
            final status = p['status'] as String;
            final color = status == 'approved' ? LC.green
              : status == 'rejected' ? LC.rose : LC.gold;
            final statusText = status == 'approved' ? '✅ Approved'
              : status == 'rejected' ? '❌ Rejected' : '⏳ Pending';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: LC.glass,
                border: Border.all(color: color.withOpacity(0.2))),
              child: Row(children: [
                Container(width: 38, height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.15)),
                  child: Icon(Icons.receipt_outlined,
                    color: color, size: 17)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(p['month'] as String, style: const TextStyle(
                    color: LC.tPrimary, fontSize: 13,
                    fontWeight: FontWeight.w700)),
                  Text(p['amount'] as String,
                    style: const TextStyle(
                      color: LC.tMuted, fontSize: 12)),
                ])),
                Text(statusText, style: TextStyle(
                  color: color, fontSize: 12,
                  fontWeight: FontWeight.w700)),
              ]),
            );
          }),

        const SizedBox(height: 24),

        // ── Settings ──
        const Text('⚙️ Settings', style: TextStyle(
          color: LC.tPrimary, fontSize: 15,
          fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),

        // Notifications toggle
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: LC.glass,
            border: Border.all(
              color: Colors.white.withOpacity(0.06))),
          child: Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LC.primary.withOpacity(0.12)),
              child: const Icon(Icons.notifications_outlined,
                color: LC.primary, size: 17)),
            const SizedBox(width: 12),
            const Text('Notifications', style: TextStyle(
              color: LC.tPrimary, fontSize: 13,
              fontWeight: FontWeight.w600)),
            const Spacer(),
            Switch(
              value: _notificationsEnabled,
              onChanged: (v) {
                setState(() => _notificationsEnabled = v);
                _showSnack(
                  v ? '🔔 Notifications enabled'
                    : '🔕 Notifications disabled',
                  LC.primary);
              },
              activeColor: LC.primary,
            ),
          ]),
        ),

        _settingRow(Icons.lock_outline_rounded,
          'Change Password', LC.accent, _showChangePassword),
        _settingRow(Icons.help_outline_rounded,
          'Help & Support', LC.gold, _showHelp),
        _settingRow(Icons.logout_rounded,
          'Logout', LC.rose, _showLogoutConfirm),
      ]),
    );
  }

  Widget _payRow(String label, String val) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(children: [
      Text(label, style: const TextStyle(
        color: LC.tMuted, fontSize: 13)),
      const Spacer(),
      Text(val, style: const TextStyle(
        color: LC.tPrimary, fontSize: 13,
        fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _infoRow(IconData icon, String label,
      String val, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: LC.glass,
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(
          color: LC.tMuted, fontSize: 13)),
        const Spacer(),
        Flexible(child: Text(val,
          style: const TextStyle(
            color: LC.tPrimary, fontSize: 13,
            fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _settingRow(IconData icon, String label,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: LC.glass,
          border: Border.all(
            color: Colors.white.withOpacity(0.06))),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12)),
            child: Icon(icon, color: color, size: 17)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(
            color: LC.tPrimary, fontSize: 13,
            fontWeight: FontWeight.w600)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded,
            color: LC.tMuted, size: 14),
        ]),
      ),
    );
  }
}



