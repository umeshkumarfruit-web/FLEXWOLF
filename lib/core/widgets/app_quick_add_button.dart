import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppQuickAddButton extends StatelessWidget {
  const AppQuickAddButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 40,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        shape: const RoundedRectangleBorder(),
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      child: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('QUICK ADD', maxLines: 1, softWrap: false),
      ),
    ),
  );
}
