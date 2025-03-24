import 'package:flutter/material.dart';

class ScoreBoard extends StatelessWidget {
  final int score;
  final int? highScore;

  const ScoreBoard({
    super.key,
    required this.score,
    this.highScore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.green,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(30),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SCORE',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.green,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$score',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 18.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.green,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'HIGH SCORE',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 14.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.green,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${highScore ?? 0}',
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 18.0,
                  fontWeight: FontWeight.normal,
                  color: Colors.green,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
