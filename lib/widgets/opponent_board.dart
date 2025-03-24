import 'package:flutter/material.dart';

class OpponentBoard extends StatelessWidget {
  final List<List<int>> board;

  const OpponentBoard({
    super.key,
    required this.board,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: board[0].length / board.length, // Width / Height
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.0),
          color: Colors.black12,
        ),
        child: CustomPaint(
          painter: _OpponentBoardPainter(
            board: board,
          ),
        ),
      ),
    );
  }
}

class _OpponentBoardPainter extends CustomPainter {
  final List<List<int>> board;

  _OpponentBoardPainter({
    required this.board,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / board[0].length;
    final cellHeight = size.height / board.length;

    // Draw filled cells
    for (int y = 0; y < board.length; y++) {
      for (int x = 0; x < board[y].length; x++) {
        if (board[y][x] != 0) {
          final paint = Paint()
            ..color = _getColorForCell(board[y][x])
            ..style = PaintingStyle.fill;

          final borderPaint = Paint()
            ..color = Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;

          final rect = Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth,
            cellHeight,
          );

          canvas.drawRect(rect, paint);
          canvas.drawRect(rect, borderPaint);
        }
      }
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;

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

  Color _getColorForCell(int value) {
    switch (value) {
      case 1:
        return Colors.cyan; // I piece
      case 2:
        return Colors.blue; // J piece
      case 3:
        return Colors.orange; // L piece
      case 4:
        return Colors.yellow; // O piece
      case 5:
        return Colors.green; // S piece
      case 6:
        return Colors.purple; // T piece
      case 7:
        return Colors.red; // Z piece
      case 8:
        return Colors.grey.shade700; // Garbage blocks
      default:
        return Colors.transparent;
    }
  }

  @override
  bool shouldRepaint(_OpponentBoardPainter oldDelegate) {
    return oldDelegate.board != board;
  }
}
