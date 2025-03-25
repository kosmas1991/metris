
import 'package:flutter/material.dart';
import 'tetris_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 450,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [Color.fromARGB(255, 18, 158, 42), Colors.black],
                radius: 1.0,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green,
                        width: 4,
                      ),
                      color: Colors.black,
                    ),
                    child: Text(
                      'TETRIS',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 40,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.green.shade700,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                  _buildRetroButton(
                    'PLAY',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TetrisScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  _buildRetroButton(
                    'SETTINGS',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroButton(String text, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.green, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withAlpha(50),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 18,
            color: Colors.green,
            fontWeight: FontWeight.normal,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
