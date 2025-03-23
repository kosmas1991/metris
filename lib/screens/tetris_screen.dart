import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/tetromino.dart';
import '../widgets/game_board.dart';
import '../widgets/next_piece.dart';
import '../widgets/score_board.dart';
import '../blocs/score_bloc.dart';

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  static const int boardWidth = 10;
  static const int boardHeight = 20;

  late List<List<int>> gameBoard;
  late Tetromino currentPiece;
  late Tetromino nextPiece;
  late Timer gameTimer;
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;

  // New variables for fast drop functionality
  Timer? fastDropTimer;
  bool isHoldingDown = false;

  @override
  void initState() {
    super.initState();
    initGame();
    context.read<ScoreBloc>().add(UpdateScore(score));
  }

  void _saveHighScore() {
    context.read<ScoreBloc>().add(UpdateScore(score));
  }

  void initGame() {
    // Initialize empty game board
    gameBoard =
        List.generate(boardHeight, (_) => List.generate(boardWidth, (_) => 0));

    // Create initial pieces
    currentPiece = Tetromino.getRandom();
    nextPiece = Tetromino.getRandom();

    // Start game timer
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!isGameOver) {
        moveDown();
      }
    });
  }

  @override
  void dispose() {
    _saveHighScore();
    gameTimer.cancel();
    cancelFastDrop();
    super.dispose();
  }

  void moveLeft() {
    if (isGameOver) return;

    if (currentPiece.canMoveLeft(gameBoard)) {
      setState(() {
        currentPiece.moveLeft();
      });
    }
  }

  void moveRight() {
    if (isGameOver) return;

    if (currentPiece.canMoveRight(gameBoard)) {
      setState(() {
        currentPiece.moveRight();
      });
    }
  }

  void rotate() {
    if (isGameOver) return;

    if (currentPiece.canRotate(gameBoard)) {
      setState(() {
        currentPiece.rotate();
      });
    }
  }

  void moveDown() {
    if (isGameOver) return;

    if (currentPiece.canMoveDown(gameBoard)) {
      setState(() {
        currentPiece.moveDown();
      });
    } else {
      // Lock the piece in place
      placePiece();

      // Check for completed lines
      checkLines();

      // Get next piece
      currentPiece = nextPiece;
      nextPiece = Tetromino.getRandom();

      // Check for game over
      if (!currentPiece.canMoveDown(gameBoard)) {
        setState(() {
          isGameOver = true;
        });
        gameTimer.cancel();
        cancelFastDrop();
      }
    }
  }

  // New method to start fast dropping
  void startFastDrop() {
    if (isGameOver || isHoldingDown) return;

    setState(() {
      isHoldingDown = true;
    });

    // Create a timer that moves the piece down quickly
    fastDropTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      moveDown();
    });
  }

  // New method to cancel fast dropping
  void cancelFastDrop() {
    fastDropTimer?.cancel();
    fastDropTimer = null;

    setState(() {
      isHoldingDown = false;
    });
  }

  void placePiece() {
    for (final point in currentPiece.positions) {
      final x = point.dx.toInt() + currentPiece.x;
      final y = point.dy.toInt() + currentPiece.y;

      if (x >= 0 && x < boardWidth && y >= 0 && y < boardHeight) {
        gameBoard[y][x] = currentPiece.type;
      }
    }
  }

  void checkLines() {
    List<int> linesToRemove = [];

    for (int y = 0; y < boardHeight; y++) {
      bool isComplete = true;
      for (int x = 0; x < boardWidth; x++) {
        if (gameBoard[y][x] == 0) {
          isComplete = false;
          break;
        }
      }
      if (isComplete) {
        linesToRemove.add(y);
      }
    }

    if (linesToRemove.isNotEmpty) {
      setState(() {
        // Award points based on number of lines cleared
        switch (linesToRemove.length) {
          case 1:
            score += 100;
            break;
          case 2:
            score += 300;
            break;
          case 3:
            score += 500;
            break;
          case 4:
            score += 800; // Tetris!
            break;
        }

        // Remove completed lines
        for (final line in linesToRemove) {
          gameBoard.removeAt(line);
          gameBoard.insert(0, List.generate(boardWidth, (_) => 0));
        }

        // Update the score in the bloc
        context.read<ScoreBloc>().add(UpdateScore(score));
      });
    }
  }

  void resetGame() {
    // Save high score before resetting
    _saveHighScore();

    // Cancel the current timer before initializing a new game
    gameTimer.cancel();

    setState(() {
      initGame();
      score = 0;
      isGameOver = false;
    });

    // Reset current score in bloc but keep high score
    context.read<ScoreBloc>().add(ResetScore());
  }

  @override
  Widget build(BuildContext context) {
    // Get the high score from the bloc
    final scoreState = context.watch<ScoreBloc>().state;
    final highScore = scoreState.highScore;

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Flutter Tetris'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.refresh),
      //       onPressed: resetGame,
      //     ),
      //   ],
      // ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          ScoreBoard(score: score, highScore: highScore),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: GameBoard(
                    board: gameBoard,
                    currentPiece: currentPiece,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NextPiece(piece: nextPiece),
                      const SizedBox(height: 20),
                      // if (isGameOver)
                      ElevatedButton(
                        onPressed: resetGame,
                        style: ButtonStyle(
                            backgroundColor:
                                const WidgetStatePropertyAll(Colors.cyan),
                            shape: WidgetStateProperty.all<LinearBorder>(
                              const LinearBorder(),
                            )),
                        child: const Text(
                          'New Game',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Move Left Button
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_left, color: Colors.white),
                  onPressed: moveLeft,
                  iconSize: 60,
                ),
              ),

              // Move Right Button
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_right, color: Colors.white),
                  onPressed: moveRight,
                  iconSize: 60,
                ),
              ),

              // Rotate Button
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: IconButton(
                  icon: const Icon(Icons.rotate_right, color: Colors.white),
                  onPressed: rotate,
                  iconSize: 60,
                ),
              ),

              // Move Down Button - Fancy Style
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange, Colors.red],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onLongPress: startFastDrop,
                  onLongPressUp: cancelFastDrop,
                  child: IconButton(
                    icon: const Icon(
                      Icons.keyboard_double_arrow_down,
                      color: Colors.white,
                    ),
                    onPressed: moveDown,
                    iconSize: 65,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }
}
