import 'package:flutter/material.dart';
import '../models/tetromino.dart';

class GameBoard extends StatelessWidget {
  final List<List<int>> board;
  final Tetromino currentPiece;

  const GameBoard({
    super.key,
    required this.board,
    required this.currentPiece,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.green,
          width: 4.0,
        ),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(30),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: board[0].length / board.length, // Width / Height
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            color: Colors.black12,
          ),
          child: CustomPaint(
            painter: _GameBoardPainter(
              board: board,
              currentPiece: currentPiece,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameBoardPainter extends CustomPainter {
  final List<List<int>> board;
  final Tetromino currentPiece;

  _GameBoardPainter({
    required this.board,
    required this.currentPiece,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / board[0].length;
    final cellHeight = size.height / board.length;

    // Draw the settled pieces
    for (int y = 0; y < board.length; y++) {
      for (int x = 0; x < board[y].length; x++) {
        if (board[y][x] != 0) {
          final rect = Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth,
            cellHeight,
          );

          // Use a specific color for garbage blocks (type 8)
          // Otherwise use the tetromino colors
          Color blockColor;
          if (board[y][x] == 8) {
            // Gray color for garbage blocks
            blockColor = Colors.grey.shade700;
          } else {
            blockColor = Tetromino.colors[board[y][x]];
          }

          canvas.drawRect(
            rect,
            Paint()..color = blockColor,
          );

          // Draw cell border
          canvas.drawRect(
            rect,
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0,
          );
        }
      }
    }

    // Draw the current moving piece
    final paint = Paint()..color = currentPiece.color;
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final point in currentPiece.positions) {
      final x = (point.dx + currentPiece.x) * cellWidth;
      final y = (point.dy + currentPiece.y) * cellHeight;

      final rect = Rect.fromLTWH(x, y, cellWidth, cellHeight);

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Vertical lines
    for (int x = 0; x <= board[0].length; x++) {
      canvas.drawLine(
        Offset(x * cellWidth, 0),
        Offset(x * cellWidth, size.height),
        gridPaint,
      );
    }

    // Horizontal lines
    for (int y = 0; y <= board.length; y++) {
      canvas.drawLine(
        Offset(0, y * cellHeight),
        Offset(size.width, y * cellHeight),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GameBoardPainter oldDelegate) {
    return true; // Always repaint for simplicity
  }
}
