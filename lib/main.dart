import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'screens/register_screen.dart';

void main() {
  runApp(const LearnovaApp());
}

class LearnovaApp extends StatelessWidget {
  const LearnovaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Learnova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/',
routes: {
  '/': (context) => const LoginScreen(),
},
    );
  }
}

class LearnovaColors {
  static const bg1 = Color(0xFF0A0818);
  static const bg2 = Color(0xFF12103A);
  static const bg3 = Color(0xFF1C1A4E);
  static const primary = Color(0xFF7B6FFF);
  static const primaryLight = Color(0xFF9D94FF);
  static const accent = Color(0xFF38D9F5);
  static const accentSoft = Color(0xFF48CAE4);
  static const pink = Color(0xFFFF6B9D);
  static const textPrimary = Color(0xFFEEECFF);
  static const textMuted = Color(0xFF7A78A8);
  static const glass = Color(0x14FFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
}

class OrbPainter extends CustomPainter {
  final double t;
  OrbPainter(this.t);

  void _drawOrb(Canvas c, Offset center, double r, Color color, double glow) {
    final paint = Paint()
..shader = RadialGradient(
        colors: [
          color.withOpacity(0.35),
          color.withOpacity(0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r * 1.4));
    c.drawCircle(center, r * 1.4, paint);
    final ringPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    c.drawCircle(center, r + glow, ringPaint);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final orbs = [
      (0.12, 0.14, 110.0, LearnovaColors.primary, 18.0),
      (0.88, 0.08, 85.0, LearnovaColors.accent, 14.0),
      (0.75, 0.82, 130.0, LearnovaColors.primary, 22.0),
      (0.08, 0.78, 75.0, LearnovaColors.accentSoft, 12.0),
      (0.55, 0.45, 55.0, LearnovaColors.pink, 10.0),
      (0.92, 0.55, 65.0, LearnovaColors.accent, 11.0),
    ];
    for (final (x, y, r, color, glow) in orbs) {
      final phase = x + y;
      final dy = math.sin((t + phase) * 2 * math.pi) * 20.0;
      final dx = math.cos((t * 0.7 + phase) * 2 * math.pi) * 10.0;
      _drawOrb(canvas, Offset(s.width * x + dx, s.height * y + dy), r, color, glow);
    }
  }

  @override
  bool shouldRepaint(OrbPainter o) => o.t != t;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePass = true;
  bool _loading = false;
  bool _emailFocused = false;
  bool _passFocused = false;

  late AnimationController _orbCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 150), _entryCtrl.forward);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entryCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Please fill in all fields'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.login(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    setState(() => _loading = false);

    if (result['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
builder: (context) => HomeScreen(
            userName: result['data']['user']['name'],
            userRole: result['data']['user']['role'],
            userEmail: result['data']['user']['email'] ?? '',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Login failed'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool loading = false;
    bool emailVerified = false;
    bool hidePass = true;
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
            color: LearnovaColors.bg2,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.08))),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Handle
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: Colors.white.withOpacity(0.2)))),
              const SizedBox(height: 20),

              // Icon
              Center(child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    LearnovaColors.primary.withOpacity(0.3),
                    LearnovaColors.accent.withOpacity(0.2)])),
                child: const Icon(Icons.lock_reset_rounded,
                  color: LearnovaColors.primary, size: 32))),
              const SizedBox(height: 16),

              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFB8B5FF), Color(0xFF38D9F5)],
                ).createShader(b),
                child: const Text('Reset Password', style: TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.w900))),
              const SizedBox(height: 6),
              Text(
                emailVerified
                  ? 'Create your new password'
                  : 'Enter your registered email to continue',
                style: const TextStyle(
                  color: LearnovaColors.textMuted, fontSize: 13)),
              const SizedBox(height: 24),

              if (!emailVerified) ...[
                // Step 1 — Email
                const Text('Email Address', style: TextStyle(
                  color: LearnovaColors.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.09))),
                  child: TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: LearnovaColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.28), fontSize: 14),
                      prefixIcon: Icon(Icons.alternate_email_rounded,
                        color: Colors.white.withOpacity(0.3), size: 19),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 4)),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: loading ? null : () async {
                    if (emailCtrl.text.isEmpty ||
                        !emailCtrl.text.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid email'),
                          backgroundColor: Colors.red));
                      return;
                    }
                    setModalState(() => loading = true);
                    // Check if email exists
                    try {
                      final result = await AuthService.checkEmail(
                        email: emailCtrl.text.trim());
                      setModalState(() => loading = false);
                      if (result['success']) {
                        setModalState(() => emailVerified = true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(result['message'] ?? 'Email not found'),
                          backgroundColor: Colors.red));
                      }
                    } catch (e) {
                      setModalState(() => loading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connection error'),
                          backgroundColor: Colors.red));
                    }
                  },
                  child: Container(
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [LearnovaColors.primary,
                          Color(0xFF5A4FFF), LearnovaColors.accent],
                        stops: [0.0, 0.5, 1.0]),
                      boxShadow: [BoxShadow(
                        color: LearnovaColors.primary.withOpacity(0.4),
                        blurRadius: 20, offset: const Offset(0, 6))]),
                    child: Center(child: loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                      : const Row(mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_rounded,
                              color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('VERIFY EMAIL', style: TextStyle(
                              color: Colors.white, fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2)),
                          ])),
                  ),
                ),
              ] else ...[
                // Step 2 — New password
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: LearnovaColors.primary.withOpacity(0.1),
                    border: Border.all(
                      color: LearnovaColors.primary.withOpacity(0.3))),
                  child: Row(children: [
                    const Icon(Icons.check_circle_rounded,
                      color: LearnovaColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      '✅ Account found: ${emailCtrl.text.trim()}',
                      style: const TextStyle(
                        color: LearnovaColors.textPrimary,
                        fontSize: 12, fontWeight: FontWeight.w600))),
                  ]),
                ),
                const SizedBox(height: 20),

                const Text('New Password', style: TextStyle(
                  color: LearnovaColors.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.09))),
                  child: TextField(
                    controller: passCtrl,
                    obscureText: hidePass,
                    style: const TextStyle(
                      color: LearnovaColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Min. 6 characters',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.28), fontSize: 14),
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: Colors.white.withOpacity(0.3), size: 19),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hidePass ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                          color: Colors.white.withOpacity(0.3), size: 19),
                        onPressed: () =>
                          setModalState(() => hidePass = !hidePass)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 4)),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Confirm New Password', style: TextStyle(
                  color: LearnovaColors.textMuted, fontSize: 12,
                  fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(color: Colors.white.withOpacity(0.09))),
                  child: TextField(
                    controller: confirmCtrl,
                    obscureText: hideConfirm,
                    style: const TextStyle(
                      color: LearnovaColors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Repeat new password',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.28), fontSize: 14),
                      prefixIcon: Icon(Icons.lock_outline_rounded,
                        color: Colors.white.withOpacity(0.3), size: 19),
                      suffixIcon: IconButton(
                        icon: Icon(
                          hideConfirm ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                          color: Colors.white.withOpacity(0.3), size: 19),
                        onPressed: () =>
                          setModalState(() => hideConfirm = !hideConfirm)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 4)),
                  ),
                ),

                // Password strength indicator
                const SizedBox(height: 12),
                ValueListenableBuilder(
                  valueListenable: passCtrl,
                  builder: (_, val, __) {
                    final len = passCtrl.text.length;
                    final strength = len == 0 ? 0
                      : len < 6 ? 1 : len < 10 ? 2 : 3;
 final colors = [Colors.transparent, const Color(0xFFFF4D6D),
                      const Color(0xFFFFB347), const Color(0xFF43D98C)];
                    final labels = ['', 'Weak', 'Medium', 'Strong'];
                    return Row(children: [
                      ...List.generate(3, (i) => Expanded(child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: i < strength
                            ? colors[strength] : Colors.white.withOpacity(0.1)),
                      ))),
                      const SizedBox(width: 8),
                      Text(labels[strength], style: TextStyle(
                        color: colors[strength], fontSize: 11,
                        fontWeight: FontWeight.w600)),
                    ]);
                  },
                ),

                const SizedBox(height: 24),
                GestureDetector(
                  onTap: loading ? null : () async {
                    if (passCtrl.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password must be at least 6 characters'),
                          backgroundColor: Colors.orange));
                      return;
                    }
                    if (passCtrl.text != confirmCtrl.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match!'),
                          backgroundColor: Colors.red));
                      return;
                    }
                    setModalState(() => loading = true);
                    final result = await AuthService.resetPassword(
                      email: emailCtrl.text.trim(),
                      newPassword: passCtrl.text.trim(),
                    );
                    setModalState(() => loading = false);
                    if (result['success']) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text(
                          '✅ Password reset! Please login with new password.'),
                        backgroundColor: const Color(0xFF6C63FF),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result['message'] ?? 'Failed'),
                        backgroundColor: Colors.red));
                    }
                  },
                  child: Container(
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [LearnovaColors.primary,
                          Color(0xFF5A4FFF), LearnovaColors.accent],
                        stops: [0.0, 0.5, 1.0]),
                      boxShadow: [BoxShadow(
                        color: LearnovaColors.primary.withOpacity(0.4),
                        blurRadius: 20, offset: const Offset(0, 6))]),
                    child: Center(child: loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                      : const Row(mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lock_reset_rounded,
                              color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('RESET PASSWORD', style: TextStyle(
                              color: Colors.white, fontSize: 14,
                              fontWeight: FontWeight.w900, letterSpacing: 2)),
                          ])),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final hPad = isWide ? size.width * 0.2 : 24.0;
    final logoSize = isWide ? 110.0 : size.width * 0.22;
    final titleSize = isWide ? 44.0 : size.width * 0.09;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [LearnovaColors.bg1, LearnovaColors.bg2, LearnovaColors.bg3],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          ...List.generate(22, (i) {
            final rng = math.Random(i * 37);
            return Positioned(
              left: rng.nextDouble() * size.width,
              top: rng.nextDouble() * size.height,
              child: AnimatedBuilder(
                animation: _orbCtrl,
                builder: (_, __) {
                  final blink = (math.sin((_orbCtrl.value * 2 * math.pi) + i * 0.8) + 1) / 2;
                  return Container(
                    width: rng.nextDouble() * 2.5 + 1,
                    height: rng.nextDouble() * 2.5 + 1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15 + blink * 0.5),
                    ),
                  );
                },
              ),
            );
          }),
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) => CustomPaint(
              painter: OrbPainter(_orbCtrl.value),
              size: size,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      SizedBox(height: size.height * 0.04),
                      ScaleTransition(
                        scale: _logoScale,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: logoSize + 28,
                              height: logoSize + 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
gradient: const RadialGradient(
                                  colors: [
                                    Color(0x4D7B6FFF),
                                    Colors.transparent,
                                  ],
                                  stops: [0.0, 1.0],
                                ),
                              ),
                            ),
                            Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Color(0xFF9D94FF), Color(0xFF6C63FF), Color(0xFF38D9F5)],
                                ),
                                boxShadow: [
                                  BoxShadow(color: LearnovaColors.primary.withOpacity(0.55), blurRadius: 36, spreadRadius: 4),
                                  BoxShadow(color: LearnovaColors.accent.withOpacity(0.25), blurRadius: 60, spreadRadius: 8),
                                ],
                              ),
                              child: Icon(Icons.rocket_launch_rounded, size: logoSize * 0.48, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.022),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFB8B5FF), Color(0xFF7B6FFF), Color(0xFF38D9F5)],
                          stops: [0.0, 0.5, 1.0],
                        ).createShader(b),
                        child: Text("Learnova",
                          style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.0)),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(colors: [
                            LearnovaColors.primary.withOpacity(0.18),
                            LearnovaColors.accent.withOpacity(0.18),
                          ]),
                          border: Border.all(color: LearnovaColors.primary.withOpacity(0.38)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7, height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: LearnovaColors.accent,
                                boxShadow: [BoxShadow(color: LearnovaColors.accent.withOpacity(0.9), blurRadius: 7, spreadRadius: 1)],
                              ),
                            ),
                            const SizedBox(width: 9),
                            ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [Color(0xFFCECBFF), Color(0xFF38D9F5)],
                              ).createShader(b),
                              child: const Text("Your gateway to smarter learning",
                                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 9),
                            const Icon(Icons.auto_awesome_rounded, color: LearnovaColors.accent, size: 13),
                          ],
                        ),
                      ),
                      SizedBox(height: size.height * 0.04),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: LearnovaColors.glass,
                          border: Border.all(color: LearnovaColors.glassBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 50, spreadRadius: 2),
                          ],
                        ),
                        padding: EdgeInsets.all(isWide ? 36 : 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4, height: 28,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [LearnovaColors.primary, LearnovaColors.accent],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Welcome Back 👋",
                                      style: TextStyle(color: LearnovaColors.textPrimary, fontSize: isWide ? 22 : 19, fontWeight: FontWeight.w800)),
                                    const Text("Sign in to continue your journey",
                                      style: TextStyle(color: LearnovaColors.textMuted, fontSize: 12.5)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            const Text("Email Address",
                              style: TextStyle(color: LearnovaColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                            const SizedBox(height: 8),
                            _buildField(controller: _emailCtrl, hint: "you@example.com",
                              icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress,
                              focused: _emailFocused, onFocusChange: (v) => setState(() => _emailFocused = v)),
                            const SizedBox(height: 18),
                            const Text("Password",
                              style: TextStyle(color: LearnovaColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                            const SizedBox(height: 8),
                            _buildField(controller: _passCtrl, hint: "Enter your password",
                              icon: Icons.shield_outlined, isPassword: true,
                              focused: _passFocused, onFocusChange: (v) => setState(() => _passFocused = v)),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => _showForgotPassword(),
                                child: const Text("Forgot password?",
                                  style: TextStyle(color: LearnovaColors.accent, fontSize: 12.5, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 26),
                            GestureDetector(
                              onTap: _loading ? null : _handleLogin,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity, height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
gradient: _loading
                                    ? LinearGradient(colors: [
                                        LearnovaColors.primary.withOpacity(0.5),
                                        LearnovaColors.accent.withOpacity(0.5),
                                      ])
                                    : const LinearGradient(colors: [
                                        LearnovaColors.primary,
                                        Color(0xFF5A4FFF),
                                        LearnovaColors.accent,
                                      ], stops: [0.0, 0.5, 1.0]),
                                  boxShadow: _loading ? [] : [
                                    BoxShadow(color: LearnovaColors.primary.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8)),
                                  ],
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(width: 22, height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("SIGN IN", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                                            SizedBox(width: 10),
                                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
 const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("New to Learnova? ", style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context,
                                MaterialPageRoute(builder: (context) => const RegisterScreen()));
                            },
                            child: ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [LearnovaColors.primaryLight, LearnovaColors.accent],
                              ).createShader(b),
                              child: const Text("Create Account →",
                                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    required bool focused,
    required ValueChanged<bool> onFocusChange,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: focused ? LearnovaColors.primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: focused ? LearnovaColors.primary.withOpacity(0.6) : Colors.white.withOpacity(0.09),
            width: focused ? 1.5 : 1.0,
          ),
          boxShadow: focused ? [BoxShadow(color: LearnovaColors.primary.withOpacity(0.15), blurRadius: 20)] : [],
        ),
        child: TextField(
          controller: controller,
          obscureText: isPassword ? _hidePass : false,
          keyboardType: keyboardType,
          style: const TextStyle(color: LearnovaColors.textPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 14),
            prefixIcon: Icon(icon, color: focused ? LearnovaColors.primary : Colors.white.withOpacity(0.3), size: 19),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white.withOpacity(0.3), size: 19),
                    onPressed: () => setState(() => _hidePass = !_hidePass),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialBtn(String label, Color c1, Color c2) {
    return Container(
      width: 64, height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Center(
        child: ShaderMask(
          shaderCallback: (b) => LinearGradient(colors: [c1, c2]).createShader(b),
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}



