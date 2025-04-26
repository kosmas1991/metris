import 'package:flutter/material.dart';
import 'package:tetris/screens/login_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/user_bloc.dart';
import '../services/user_service.dart';
import 'tetris_screen.dart';
import 'lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Store win rate data
  double? _winRate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchWinRate();
  }

  // Fetch win rate data when the user is authenticated
  Future<void> _fetchWinRate() async {
    final userState = context.read<UserBloc>().state;
    if (userState is UserAuthenticated) {
      setState(() {
        _isLoading = true;
      });

      final winRateData = await UserService.getUserWinRate(
        userState.id,
        userState.accessToken,
      );

      if (winRateData != null) {
        setState(() {
          _winRate = winRateData['win_rate'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    String? loggedInText;
    if (userState is UserAuthenticated) {
      loggedInText = 'logged in as: ${userState.username}';
      if (_winRate != null) {
        loggedInText += ' WR: ${_winRate!.toStringAsFixed(1)}%';
      } else if (_isLoading) {
        loggedInText += ' WR: loading...';
      }
    }
    return SafeArea(
      child: Center(
        child: SizedBox(
          width: 450,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                // Stylish logged in banner at the top center
                if (loggedInText != null)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 800),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 18),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(70),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person,
                                  color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                loggedInText,
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'PressStart2P',
                                  fontSize: 5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Main content
                Center(
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
                        'ONLINE MODE',
                        onPressed: () {
                          final userState = context.read<UserBloc>().state;
                          if (userState is UserAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LobbyScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 30),
                      _buildRetroButton(
                        'SETTINGS',
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                      ),
                    ],
                  ),
                ),
              ],
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
