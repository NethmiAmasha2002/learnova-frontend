import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../widgets/math_background.dart';
import '../widgets/bottom_nav.dart';
import 'dashboard/dashboard_screen.dart';
import 'schedule/schedule_screen.dart';
import 'tasks/tasks_screen.dart';
import 'chat/chat_screen.dart';
import 'profile/profile_screen.dart';
import 'teacher/teacher_dashboard_screen.dart';
import 'teacher/teacher_tasks_screen.dart';
import 'teacher/teacher_chat_screen.dart';
import 'teacher/teacher_schedule_screen.dart';
import 'teacher/teacher_schedule_screen.dart';
import 'teacher/teacher_profile_screen.dart';
class HomeScreen extends StatefulWidget {
final String userName;
  final String userRole;
  final String userEmail;
  const HomeScreen({super.key, required this.userName, required this.userRole, required this.userEmail});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  int _tab = 0;
  DateTime? _lastBackPress;

  bool get isTeacher => widget.userRole == 'tutor' || widget.userRole == 'teacher';

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() { _bgCtrl.dispose(); super.dispose(); }

  void goToTab(int index) => setState(() => _tab = index);

  Future<bool> _onWillPop() async {
    if (_tab != 0) { setState(() => _tab = 0); return false; }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Press back again to exit'),
        backgroundColor: LC.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screens = isTeacher ? [
      TeacherDashboardScreen(userName: widget.userName, onNavigate: goToTab),
      TeacherScheduleScreen(),
      TeacherTasksScreen(userName: widget.userName),
      TeacherChatScreen(userName: widget.userName),
      TeacherProfileScreen(userName: widget.userName, userEmail: widget.userEmail),
    ] : [
      DashboardScreen(
        userName: widget.userName,
        userRole: widget.userRole,
        onNavigate: goToTab),
      const ScheduleScreen(),
 TasksScreen(userName: widget.userName, userEmail: widget.userEmail),
      ChatScreen(userName: widget.userName, userEmail: widget.userEmail),
      ProfileScreen(userName: widget.userName, userEmail: widget.userEmail),
    ];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: MathBackground(
          controller: _bgCtrl,
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                screens[_tab],
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: BottomNav(currentIndex: _tab, onTap: goToTab),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



