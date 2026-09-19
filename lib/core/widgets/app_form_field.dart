import 'package:flutter/material.dart';

class AppFormField extends StatelessWidget {
  const AppFormField({
    required this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.autofillHints,
    this.obscureText = false,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        autofillHints: autofillHints,
        obscureText: obscureText,
        minLines: 1,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          errorText: errorText,
        ),
      ),
    );
  }
}
