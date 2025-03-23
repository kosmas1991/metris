import 'dart:math';
import 'package:flutter/material.dart';

class Tetromino {
  int type;
  int rotation = 0;
  int x;
  int y;
  List<Offset> positions = [];

  static const List<Color> colors = [
    Colors.transparent,
    Colors.cyan,
    Colors.blue,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.purple,
    Colors.red,
  ];

  static const List<List<List<int>>> shapes = [
    [],
    [
      [0, 0, 0, 0],
      [1, 1, 1, 1],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ],
    [
      [2, 0, 0],
      [2, 2, 2],
      [0, 0, 0],
    ],
    [
      [0, 0, 3],
      [3, 3, 3],
      [0, 0, 0],
    ],
    [
      [4, 4],
      [4, 4],
    ],
    [
      [0, 5, 5],
      [5, 5, 0],
      [0, 0, 0],
    ],
    [
      [0, 6, 0],
      [6, 6, 6],
      [0, 0, 0],
    ],
    [
      [7, 7, 0],
      [0, 7, 7],
      [0, 0, 0],
    ],
  ];

  Tetromino({required this.type, this.rotation = 0})
      : x = 3,
        y = _calculateInitialY(type) {
    _updatePositions();
  }

  // Calculate the initial y position based on the piece type
  static int _calculateInitialY(int type) {
    // Get the shape height based on the type
    final shape = shapes[type];
    // Start with the piece just above the visible board
    // This negative position will make the piece gradually appear from the top
    return -shape.length + 1;
  }

  static Tetromino getRandom() {
    final random = Random();
    final type = random.nextInt(7) + 1;
    return Tetromino(type: type);
  }

  Color get color => colors[type];

  void _updatePositions() {
    positions = [];
    final shape = _rotateMatrix(shapes[type], rotation);

    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == type) {
          positions.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }
  }

  List<List<int>> _rotateMatrix(List<List<int>> matrix, int rotation) {
    // Deep copy the matrix to avoid modifying the original
    List<List<int>> rotated = matrix.map((row) => row.toList()).toList();

    // Special case for "I", "Z", and reverse "Z" shapes
    bool isSpecialShape =
        (matrix == shapes[1] || matrix == shapes[5] || matrix == shapes[7]);
    if (isSpecialShape) {
      rotation %= 2; // Only allow two unique rotations (0 and 1)
    }

    for (int i = 0; i < rotation; i++) {
      rotated = List.generate(
          rotated[0].length,
          (x) => List.generate(
              rotated.length, (y) => rotated[rotated.length - y - 1][x]));
    }

    return rotated;
  }

  void rotate() {
    int prevRotation = rotation;
    rotation = (rotation + 1) % 4;
    _updatePositions();

    if (!isValidPosition()) {
      rotation = prevRotation;
      _updatePositions();
    }
  }

  bool canRotate(List<List<int>> board) {
    int nextRotation = (rotation + 1) % 4;
    List<Offset> newPositions = [];
    final shape = _rotateMatrix(shapes[type], nextRotation);

    for (int y = 0; y < shape.length; y++) {
      for (int x = 0; x < shape[y].length; x++) {
        if (shape[y][x] == type) {
          newPositions.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }

    for (final point in newPositions) {
      final newX = point.dx.toInt() + x;
      final newY = point.dy.toInt() + y;
      if (newX < 0 ||
          newX >= board[0].length ||
          newY >= board.length ||
          (newY >= 0 && board[newY][newX] != 0)) {
        return false;
      }
    }
    return true;
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

  bool canMoveLeft(List<List<int>> board) {
    for (final point in positions) {
      final newX = point.dx.toInt() + x - 1;
      final newY = point.dy.toInt() + y;
      if (newX < 0 || (newY >= 0 && board[newY][newX] != 0)) {
        return false;
      }
    }
    return true;
  }

  bool canMoveRight(List<List<int>> board) {
    for (final point in positions) {
      final newX = point.dx.toInt() + x + 1;
      final newY = point.dy.toInt() + y;
      if (newX >= board[0].length || (newY >= 0 && board[newY][newX] != 0)) {
        return false;
      }
    }
    return true;
  }

  bool canMoveDown(List<List<int>> board) {
    for (final point in positions) {
      final newX = point.dx.toInt() + x;
      final newY = point.dy.toInt() + y + 1;
      if (newY >= board.length || (newY >= 0 && board[newY][newX] != 0)) {
        return false;
      }
    }
    return true;
  }

  bool isValidPosition() {
    for (final point in positions) {
      final newX = point.dx.toInt() + x;
      final newY = point.dy.toInt() + y;
      if (newX < 0 || newX >= 10 || newY >= 20) {
        return false;
      }
    }
    return true;
  }
}
