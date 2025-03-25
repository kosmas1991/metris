import 'package:flutter/material.dart';
import '../models/tetromino.dart';

class NextPiece extends StatelessWidget {
  final dynamic piece;

  const NextPiece({
    super.key,
    required this.piece,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.green,
          width: 2.0,
        ),
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(30),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'NEXT',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: Colors.green,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              color: Colors.black12,
            ),
            child: CustomPaint(
              painter: _NextPiecePainter(piece: piece),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPiecePainter extends CustomPainter {
  final Tetromino piece;

  _NextPiecePainter({required this.piece});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate cell size based on the tetromino shape
    final shape = Tetromino.shapes[piece.type];
    final cellSize = size.width / shape[0].length;

    // Draw the piece in the center of the container
    final paint = Paint()..color = piece.color;
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final point in piece.positions) {
      final x =
          point.dx * cellSize + (size.width - shape[0].length * cellSize) / 2;
      final y =
          point.dy * cellSize + (size.height - shape.length * cellSize) / 2;

      final rect = Rect.fromLTWH(x, y, cellSize, cellSize);

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(_NextPiecePainter oldDelegate) {
    return oldDelegate.piece.type != piece.type ||
        oldDelegate.piece.rotation != piece.rotation;
  }
}
