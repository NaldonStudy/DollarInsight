import 'package:flutter/material.dart';

class ScrollFabButton extends StatelessWidget {
  final bool showFab;
  final double w;
  final VoidCallback? onTap;

  const ScrollFabButton({
    super.key,
    required this.showFab,
    required this.w,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: showFab ? 1 : 0,
      duration: const Duration(milliseconds: 230),
      child: AnimatedOpacity(
        opacity: showFab ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: w * 0.15,
            height: w * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEFF8FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                "assets/images/main8.webp",
                width: w * 0.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
