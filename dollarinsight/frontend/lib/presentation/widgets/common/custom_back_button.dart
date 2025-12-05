import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

///뒤로가기 버튼
class CustomBackButton extends StatelessWidget {
  final Color iconColor;
  final VoidCallback? onPressed;

  const CustomBackButton({
    super.key,
    this.iconColor = Colors.black,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back, color: iconColor),
      onPressed: onPressed ?? () => context.pop(),
    );
  }
}
