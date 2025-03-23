import 'package:flutter/material.dart';
import '../models/tetromino.dart';

class NextPiece extends StatelessWidget {
  final Tetromino piece;

  const NextPiece({
    super.key,
    required this.piece,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Next Piece',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
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
