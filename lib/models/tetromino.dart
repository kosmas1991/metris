import 'dart:math';
import 'package:flutter/material.dart';

class Tetromino {
  String type;
  int rotationState = 0;
  int x = 0;
  int y = 0;
  late List<Offset> positions;

  static final Map<String, List<List<List<int>>>> shapes = {
    'I': [
      [
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
        [0, 0, 0, 0],
      ],
      [
        [0, 0, 1, 0],
        [0, 0, 1, 0],
        [0, 0, 1, 0],
        [0, 0, 1, 0],
      ],
      [
        [0, 0, 0, 0],
        [0, 0, 0, 0],
        [1, 1, 1, 1],
        [0, 0, 0, 0],
      ],
      [
        [0, 1, 0, 0],
        [0, 1, 0, 0],
        [0, 1, 0, 0],
        [0, 1, 0, 0],
      ],
    ],
    'J': [
      [
        [1, 0, 0],
        [1, 1, 1],
        [0, 0, 0],
      ],
      [
        [0, 1, 1],
        [0, 1, 0],
        [0, 1, 0],
      ],
      [
        [0, 0, 0],
        [1, 1, 1],
        [0, 0, 1],
      ],
      [
        [0, 1, 0],
        [0, 1, 0],
        [1, 1, 0],
      ],
    ],
    'L': [
      [
        [0, 0, 1],
        [1, 1, 1],
        [0, 0, 0],
      ],
      [
        [0, 1, 0],
        [0, 1, 0],
        [0, 1, 1],
      ],
      [
        [0, 0, 0],
        [1, 1, 1],
        [1, 0, 0],
      ],
      [
        [1, 1, 0],
        [0, 1, 0],
        [0, 1, 0],
      ],
    ],
    'O': [
      [
        [0, 0, 0, 0],
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
      ],
      [
        [0, 0, 0, 0],
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
      ],
      [
        [0, 0, 0, 0],
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
      ],
      [
        [0, 0, 0, 0],
        [0, 1, 1, 0],
        [0, 1, 1, 0],
        [0, 0, 0, 0],
      ],
    ],
    'S': [
      [
        [0, 1, 1],
        [1, 1, 0],
        [0, 0, 0],
      ],
      [
        [0, 1, 0],
        [0, 1, 1],
        [0, 0, 1],
      ],
      [
        [0, 0, 0],
        [0, 1, 1],
        [1, 1, 0],
      ],
      [
        [1, 0, 0],
        [1, 1, 0],
        [0, 1, 0],
      ],
    ],
    'T': [
      [
        [0, 1, 0],
        [1, 1, 1],
        [0, 0, 0],
      ],
      [
        [0, 1, 0],
        [0, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 0, 0],
        [1, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 1, 0],
        [1, 1, 0],
        [0, 1, 0],
      ],
    ],
    'Z': [
      [
        [1, 1, 0],
        [0, 1, 1],
        [0, 0, 0],
      ],
      [
        [0, 0, 1],
        [0, 1, 1],
        [0, 1, 0],
      ],
      [
        [0, 0, 0],
        [1, 1, 0],
        [0, 1, 1],
      ],
      [
        [0, 1, 0],
        [1, 1, 0],
        [1, 0, 0],
      ],
    ],
  };

  static final List<Color> colors = [
    Colors.cyan, // I
    Colors.blue, // J
    Colors.orange, // L
    Colors.yellow, // O
    Colors.green, // S
    Colors.purple, // T
    Colors.red, // Z
  ];

  static final List<String> types = ['I', 'J', 'L', 'O', 'S', 'T', 'Z'];

  Tetromino({required this.type}) {
    positions = _calculatePositions();

    // Center the piece horizontally
    x = 3;

    // Start higher for I piece to avoid immediate collision
    y = type == 'I' ? -2 : -1;
  }

  static Tetromino getRandom() {
    final random = Random();
    final randomType = types[random.nextInt(types.length)];
    return Tetromino(type: randomType);
  }

  static String getRandomType() {
    final random = Random();
    return types[random.nextInt(types.length)];
  }

  List<Offset> _calculatePositions() {
    final positions = <Offset>[];
    final shape = shapes[type]![rotationState];

    for (var row = 0; row < shape.length; row++) {
      for (var col = 0; col < shape[row].length; col++) {
        if (shape[row][col] == 1) {
          positions.add(Offset(col.toDouble(), row.toDouble()));
        }
      }
    }

    return positions;
  }

  void rotate() {
    rotationState = (rotationState + 1) % 4;
    positions = _calculatePositions();
  }

  void rotateBack() {
    rotationState = (rotationState - 1) % 4;
    if (rotationState < 0) rotationState += 4;
    positions = _calculatePositions();
  }

  void moveLeft() {
    x--;
  }

  void moveRight() {
    x++;
  }

  void moveDown() {
    y++;
  }

  void moveUp([int steps = 1]) {
    y -= steps;
  }

  bool canMoveLeft(List<List<int>> board) {
    for (final position in positions) {
      final newX = (position.dx + x - 1).toInt();
      final newY = (position.dy + y).toInt();

      // Check boundary
      if (newX < 0) return false;

      // Check collision with placed pieces
      if (newY >= 0 && newY < board.length && newX < board[newY].length) {
        if (board[newY][newX] != 0) return false;
      }
    }

    return true;
  }

  bool canMoveRight(List<List<int>> board) {
    for (final position in positions) {
      final newX = (position.dx + x + 1).toInt();
      final newY = (position.dy + y).toInt();

      // Check boundary
      if (newX >= board[0].length) return false;

      // Check collision with placed pieces
      if (newY >= 0 && newY < board.length) {
        if (board[newY][newX] != 0) return false;
      }
    }

    return true;
  }

  bool canMoveDown(List<List<int>> board) {
    for (final position in positions) {
      final newX = (position.dx + x).toInt();
      final newY = (position.dy + y + 1).toInt();

      // Check boundary
      if (newY >= board.length) return false;

      // Check collision with placed pieces
      if (newY >= 0 && newX >= 0 && newX < board[0].length) {
        if (board[newY][newX] != 0) return false;
      }
    }

    return true;
  }

  Color get color {
    switch (type) {
      case 'I':
        return colors[0];
      case 'J':
        return colors[1];
      case 'L':
        return colors[2];
      case 'O':
        return colors[3];
      case 'S':
        return colors[4];
      case 'T':
        return colors[5];
      case 'Z':
        return colors[6];
      default:
        return Colors.grey;
    }
  }

  int typeToInt() {
    switch (type) {
      case 'I':
        return 1;
      case 'J':
        return 2;
      case 'L':
        return 3;
      case 'O':
        return 4;
      case 'S':
        return 5;
      case 'T':
        return 6;
      case 'Z':
        return 7;
      default:
        return 0;
    }
  }
}
