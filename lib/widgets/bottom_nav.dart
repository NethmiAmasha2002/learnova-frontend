import 'package:flutter/material.dart';
import '../utils/colors.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad + 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [LC.bg1.withOpacity(0), LC.bg1],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: LC.bg3.withOpacity(0.95),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navBtn(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
            _navBtn(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Schedule'),
            _navBtn(2, Icons.assignment_rounded, Icons.assignment_outlined, 'Tasks'),
            _navBtn(3, Icons.chat_rounded, Icons.chat_outlined, 'Chat'),
            _navBtn(4, Icons.person_rounded, Icons.person_outlined, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(int index, IconData active, IconData inactive, String label) {
    final sel = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: sel ? LinearGradient(colors: [
              LC.primary.withOpacity(0.3), LC.accent.withOpacity(0.12)]) : null,
            border: sel ? Border.all(color: LC.primary.withOpacity(0.35)) : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(sel ? active : inactive,
                color: sel ? LC.primary : Colors.white.withOpacity(0.3), size: 22),
              const SizedBox(height: 3),
              Text(label, style: TextStyle(
                color: sel ? LC.primary : Colors.white.withOpacity(0.3),
                fontSize: 9.5,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
              )),
            ],
          ),
        ),
      ),
    );
  }
}



