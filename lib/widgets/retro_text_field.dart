import 'package:flutter/material.dart';

class RetroTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;

  const RetroTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      style: const TextStyle(
        color: Colors.green,
        fontFamily: 'PressStart2P',
        fontSize: 12,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.green,
          fontFamily: 'PressStart2P',
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green, width: 2),
        ),
        fillColor: Colors.black,
        filled: true,
      ),
    );
  }
}
