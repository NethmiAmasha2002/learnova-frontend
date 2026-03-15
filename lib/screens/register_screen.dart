import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/auth_service.dart';

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

class OrbPainterReg extends CustomPainter {
  final double t;
  OrbPainterReg(this.t);

  void _drawOrb(Canvas c, Offset center, double r, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.06),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: center, radius: r * 1.4));
    c.drawCircle(center, r * 1.4, paint);
  }

  @override
  void paint(Canvas canvas, Size s) {
    final orbs = [
      (0.9, 0.05, 100.0, LearnovaColors.accent),
      (0.1, 0.15, 90.0, LearnovaColors.primary),
      (0.8, 0.9, 120.0, LearnovaColors.primary),
      (0.05, 0.85, 70.0, LearnovaColors.pink),
    ];
    for (final (x, y, r, color) in orbs) {
      final dy = math.sin((t + x) * 2 * math.pi) * 18.0;
      final dx = math.cos((t * 0.6 + y) * 2 * math.pi) * 10.0;
      _drawOrb(canvas, Offset(s.width * x + dx, s.height * y + dy), r, color);
    }
  }

  @override
  bool shouldRepaint(OrbPainterReg o) => o.t != t;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _hidePass = true;
  bool _hideConfirmPass = true;
  bool _loading = false;
  String _selectedRole = 'student';

  bool _nameFocused = false;
  bool _emailFocused = false;
  bool _passFocused = false;
  bool _confirmFocused = false;

  late AnimationController _orbCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 100), _entryCtrl.forward);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    // ── Validation ──
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty ||
        _confirmPassCtrl.text.isEmpty) {
      _showSnack('Please fill in all fields', Colors.red);
      return;
    }
    if (!_emailCtrl.text.contains('@')) {
      _showSnack('Please enter a valid email', Colors.orange);
      return;
    }
    if (_passCtrl.text.length < 6) {
      _showSnack('Password must be at least 6 characters', Colors.orange);
      return;
    }
    if (_passCtrl.text != _confirmPassCtrl.text) {
      _showSnack('Passwords do not match! ❌', Colors.red);
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      role: _selectedRole,
    );

    setState(() => _loading = false);

    if (result['success']) {
      _showSnack('Account created! Welcome to Learnova 🎉', const Color(0xFF6C63FF));
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      _showSnack(result['message'] ?? 'Registration failed', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final hPad = isWide ? size.width * 0.2 : 24.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Background ──
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

          // ── Stars ──
          ...List.generate(18, (i) {
            final rng = math.Random(i * 53);
            return Positioned(
              left: rng.nextDouble() * size.width,
              top: rng.nextDouble() * size.height,
              child: AnimatedBuilder(
                animation: _orbCtrl,
                builder: (_, __) {
                  final blink = (math.sin((_orbCtrl.value * 2 * math.pi) + i * 1.1) + 1) / 2;
                  return Container(
                    width: rng.nextDouble() * 2.2 + 0.8,
                    height: rng.nextDouble() * 2.2 + 0.8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1 + blink * 0.5),
                    ),
                  );
                },
              ),
            );
          }),

          // ── Orbs ──
          AnimatedBuilder(
            animation: _orbCtrl,
            builder: (_, __) => CustomPaint(
              painter: OrbPainterReg(_orbCtrl.value),
              size: size,
            ),
          ),

          // ── Content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── Back + Title ──
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.07),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [Color(0xFFB8B5FF), Color(0xFF38D9F5)],
                                ).createShader(b),
                                child: const Text(
                                  "Create Account",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const Text(
                                "Join thousands of learners today",
                                style: TextStyle(
                                    color: LearnovaColors.textMuted, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Glass Card ──
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: LearnovaColors.glass,
                          border: Border.all(color: LearnovaColors.glassBorder, width: 1.2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 50),
                            BoxShadow(color: LearnovaColors.primary.withOpacity(0.07), blurRadius: 80),
                          ],
                        ),
                        padding: EdgeInsets.all(isWide ? 36 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // ── Role Selector ──
                            _buildLabel("I am a..."),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: _buildRoleCard(
                                  role: 'student',
                                  icon: Icons.school_rounded,
                                  label: 'Student',
                                  subtitle: 'I want to learn',
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: _buildRoleCard(
                                  role: 'tutor',
                                  icon: Icons.cast_for_education_rounded,
                                  label: 'Tutor',
                                  subtitle: 'I want to teach',
                                )),
                              ],
                            ),

                            const SizedBox(height: 22),

                            // ── Full Name ──
                            _buildLabel("Full Name"),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _nameCtrl,
                              hint: "Your full name",
                              icon: Icons.person_outline_rounded,
                              focused: _nameFocused,
                              onFocusChange: (v) => setState(() => _nameFocused = v),
                            ),

                            const SizedBox(height: 16),

                            // ── Email ──
                            _buildLabel("Email Address"),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _emailCtrl,
                              hint: "you@example.com",
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              focused: _emailFocused,
                              onFocusChange: (v) => setState(() => _emailFocused = v),
                            ),

                            const SizedBox(height: 16),

                            // ── Password ──
                            _buildLabel("Password"),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _passCtrl,
                              hint: "Min. 6 characters",
                              icon: Icons.shield_outlined,
                              isPassword: true,
                              hidePass: _hidePass,
                              onTogglePass: () => setState(() => _hidePass = !_hidePass),
                              focused: _passFocused,
                              onFocusChange: (v) => setState(() => _passFocused = v),
                            ),

                            const SizedBox(height: 16),

                            // ── Confirm Password ──
                            _buildLabel("Confirm Password"),
                            const SizedBox(height: 8),
                            _buildField(
                              controller: _confirmPassCtrl,
                              hint: "Repeat your password",
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              hidePass: _hideConfirmPass,
                              onTogglePass: () => setState(() => _hideConfirmPass = !_hideConfirmPass),
                              focused: _confirmFocused,
                              onFocusChange: (v) => setState(() => _confirmFocused = v),
                            ),

                            const SizedBox(height: 28),

                            // ── Register Button ──
                            GestureDetector(
                              onTap: _loading ? null : _handleRegister,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: double.infinity,
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: _loading
                                        ? [LearnovaColors.primary.withOpacity(0.5), LearnovaColors.accent.withOpacity(0.5)]
                                        : [LearnovaColors.primary, const Color(0xFF5A4FFF), LearnovaColors.accent],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  boxShadow: _loading ? [] : [
                                    BoxShadow(
                                      color: LearnovaColors.primary.withOpacity(0.5),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _loading
                                      ? const SizedBox(width: 22, height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("CREATE ACCOUNT",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2,
                                              )),
                                            SizedBox(width: 10),
                                            Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Sign In Link ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account? ",
                            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14)),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: ShaderMask(
                              shaderCallback: (b) => const LinearGradient(
                                colors: [LearnovaColors.primaryLight, LearnovaColors.accent],
                              ).createShader(b),
                              child: const Text("Sign In →",
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

  Widget _buildRoleCard({
    required String role,
    required IconData icon,
    required String label,
    required String subtitle,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? LinearGradient(colors: [
                  LearnovaColors.primary.withOpacity(0.25),
                  LearnovaColors.accent.withOpacity(0.15),
                ])
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected
                ? LearnovaColors.primary.withOpacity(0.7)
                : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: LearnovaColors.primary.withOpacity(0.2), blurRadius: 16)]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon,
              color: isSelected ? LearnovaColors.primary : Colors.white.withOpacity(0.4),
              size: 28),
            const SizedBox(height: 8),
            Text(label,
              style: TextStyle(
                color: isSelected ? LearnovaColors.textPrimary : LearnovaColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              )),
            const SizedBox(height: 2),
            Text(subtitle,
              style: TextStyle(
                color: isSelected ? LearnovaColors.accent : Colors.white.withOpacity(0.25),
                fontSize: 11,
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
      style: const TextStyle(
        color: LearnovaColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ));
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool hidePass = true,
    VoidCallback? onTogglePass,
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
          color: focused
              ? LearnovaColors.primary.withOpacity(0.1)
              : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: focused
                ? LearnovaColors.primary.withOpacity(0.6)
                : Colors.white.withOpacity(0.09),
            width: focused ? 1.5 : 1.0,
          ),
          boxShadow: focused
              ? [BoxShadow(color: LearnovaColors.primary.withOpacity(0.15), blurRadius: 20)]
              : [],
        ),
        child: TextField(
          controller: controller,
          obscureText: isPassword ? hidePass : false,
          keyboardType: keyboardType,
          style: const TextStyle(color: LearnovaColors.textPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.28), fontSize: 14),
            prefixIcon: Icon(icon,
              color: focused ? LearnovaColors.primary : Colors.white.withOpacity(0.3),
              size: 19),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      hidePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white.withOpacity(0.3), size: 19),
                    onPressed: onTogglePass,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          ),
        ),
      ),
    );
  }
}



