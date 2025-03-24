import 'package:flutter/material.dart';

class Piece {
  // Assuming this class handles the piece rendering

  // Add a method to get retro style for tetrominoes
  static BoxDecoration getRetroStyle(Color color) {
    return BoxDecoration(
      color: color,
      border: Border.all(
        color: Colors.white.withAlpha(50),
        width: 1.0,
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withAlpha(70),
          color,
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: color.withAlpha(30),
          spreadRadius: 1,
          blurRadius: 1,
          offset: const Offset(1, 1),
        ),
      ],
    );
  }

  // Other existing methods and properties
  // ...existing code...
}
