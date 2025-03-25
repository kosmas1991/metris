import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for key handling
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/tetromino.dart';
import '../widgets/game_board.dart';
import '../widgets/next_piece.dart';
import '../widgets/score_board.dart';
import '../blocs/score_bloc.dart';
import '../blocs/rotation_bloc.dart';

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  // Focus node to handle keyboard inputs
  final FocusNode _focusNode = FocusNode();

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

  // New variables for continuous left/right movement
  Timer? moveLeftTimer;
  Timer? moveRightTimer;
  bool isMovingLeft = false;
  bool isMovingRight = false;

  @override
  void initState() {
    super.initState();
    initGame();
    // Load the current high score from the bloc
    highScore = context.read<ScoreBloc>().state.highScore;
    // Just update the current score on init
    context.read<ScoreBloc>().add(UpdateScore(score));
  }

  void _saveHighScore() {
    // Check if current score is higher than high score
    if (score > highScore) {
      highScore = score;
      // Update both score and high score using the existing UpdateScore event
      context.read<ScoreBloc>().add(UpdateScore(highScore));
    } else {
      // Still update the current score
      context.read<ScoreBloc>().add(UpdateScore(score));
    }
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
    // _saveHighScore();
    gameTimer.cancel();
    fastDropTimer?.cancel();
    moveLeftTimer?.cancel();
    moveRightTimer?.cancel();
    _focusNode.dispose(); // Dispose the focus node
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

    final rotationState = context.read<RotationBloc>().state;
    if (currentPiece.canRotate(gameBoard)) {
      setState(() {
        currentPiece.rotate(rotationState);
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
        _saveHighScore(); // Save high score when game is over
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

  // New method to start continuous left movement
  void startMoveLeft() {
    if (isGameOver || isMovingLeft) return;

    setState(() {
      isMovingLeft = true;
    });

    // Move once immediately
    moveLeft();

    // Create a timer that moves the piece left quickly
    moveLeftTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      moveLeft();
    });
  }

  // New method to cancel continuous left movement
  void cancelMoveLeft() {
    moveLeftTimer?.cancel();
    moveLeftTimer = null;

    setState(() {
      isMovingLeft = false;
    });
  }

  // New method to start continuous right movement
  void startMoveRight() {
    if (isGameOver || isMovingRight) return;

    setState(() {
      isMovingRight = true;
    });

    // Move once immediately
    moveRight();

    // Create a timer that moves the piece right quickly
    moveRightTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      moveRight();
    });
  }

  // New method to cancel continuous right movement
  void cancelMoveRight() {
    moveRightTimer?.cancel();
    moveRightTimer = null;

    setState(() {
      isMovingRight = false;
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

        // Check if we need to update high score
        if (score > highScore) {
          highScore = score;
          context.read<ScoreBloc>().add(UpdateHighScore(highScore));
        }
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

  // Handle keyboard input
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          moveLeft();
          break;
        case LogicalKeyboardKey.arrowRight:
          moveRight();
          break;
        case LogicalKeyboardKey.arrowDown:
          moveDown();
          break;
        case LogicalKeyboardKey.arrowUp:
        case LogicalKeyboardKey.space:
          rotate();
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 450,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('BACK'),
          ),
          body: RawKeyboardListener(
            focusNode: _focusNode,
            onKey: _handleKeyEvent,
            autofocus: true,
            child: GestureDetector(
              // Make sure we keep focus when tapping anywhere on the screen
              onTap: () {
                if (!_focusNode.hasFocus) {
                  FocusScope.of(context).requestFocus(_focusNode);
                }
              },
              child: Column(
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
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.green,
                                width: 4.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withAlpha(30),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: GameBoard(
                              board: gameBoard,
                              currentPiece: currentPiece,
                            ),
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
                              _buildRetroButton(
                                'NEW GAME',
                                onPressed: resetGame,
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
                      _buildRetroSpecialButton(
                        Icons.arrow_left,
                        onPressed: moveLeft,
                        onLongPress: startMoveLeft,
                        onLongPressUp: cancelMoveLeft,
                      ),

                      // Move Right Button
                      _buildRetroSpecialButton(
                        Icons.arrow_right,
                        onPressed: moveRight,
                        onLongPress: startMoveRight,
                        onLongPressUp: cancelMoveRight,
                      ),

                      // Rotate Button
                      _buildRetroControlButton(
                        Icons.rotate_right,
                        onPressed: rotate,
                      ),

                      // Move Down Button
                      _buildRetroSpecialButton(
                        Icons.keyboard_double_arrow_down,
                        onPressed: moveDown,
                        onLongPress: startFastDrop,
                        onLongPressUp: cancelFastDrop,
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  // Add a small text hint about keyboard controls
                  kIsWeb
                      ? const Padding(
                          padding: EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'USE ARROW KEYS OR SPACE TO PLAY',
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              fontSize: 8,
                              color: Colors.green,
                              letterSpacing: 1,
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroControlButton(IconData icon,
      {required VoidCallback onPressed}) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.green,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(50),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTapDown: (_) => onPressed(), // Execute on press down instead of tap
          child: Icon(
            icon,
            color: Colors.green,
            size: 40,
          ),
        ),
      ),
    );
  }

  Widget _buildRetroSpecialButton(
    IconData icon, {
    required VoidCallback onPressed,
    required VoidCallback onLongPress,
    required VoidCallback onLongPressUp,
  }) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: Colors.green,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withAlpha(70),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: onLongPress,
        onLongPressUp: onLongPressUp,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) =>
                onPressed(), // Execute on press down instead of tap
            child: Icon(
              icon,
              color: Colors.green,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRetroButton(String text, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed, // Keep this as onTap since it's for menu buttons
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.normal,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
