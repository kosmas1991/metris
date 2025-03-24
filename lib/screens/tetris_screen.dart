import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../blocs/score_bloc.dart';
import '../models/tetromino.dart';
import '../widgets/game_board.dart';
import '../widgets/next_piece.dart';
import '../widgets/score_board.dart';

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({super.key});

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  late List<List<int>> gameBoard;
  late Tetromino currentPiece;
  late Tetromino nextPiece;
  late Timer gameTimer;

  int score = 0;
  bool isGameOver = false;
  Timer? fastDropTimer;

  static const int boardWidth = 10;
  static const int boardHeight = 20;

  @override
  void initState() {
    super.initState();
    initGame();

    // Listen for keyboard events
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        moveLeft();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        moveRight();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        rotate();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        startFastDrop();
      } else if (event.logicalKey == LogicalKeyboardKey.space) {
        hardDrop();
      }
    } else if (event is RawKeyUpEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        cancelFastDrop();
      }
    }
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
    RawKeyboard.instance.removeListener(_handleKeyEvent);
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

    setState(() {
      currentPiece.rotate();
      if (_isColliding(currentPiece)) {
        // Try wall kicks
        currentPiece.moveLeft();
        if (_isColliding(currentPiece)) {
          currentPiece.moveRight();
          currentPiece.moveRight();
          if (_isColliding(currentPiece)) {
            currentPiece.moveLeft();
            currentPiece.rotateBack();
          }
        }
      }
    });
  }

  void startFastDrop() {
    if (isGameOver) return;

    cancelFastDrop();
    fastDropTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      moveDown();
    });
  }

  void cancelFastDrop() {
    fastDropTimer?.cancel();
    fastDropTimer = null;
  }

  void hardDrop() {
    if (isGameOver) return;

    setState(() {
      while (true) {
        currentPiece.moveDown();
        if (_isColliding(currentPiece)) {
          currentPiece.moveUp();
          _placePiece();
          _checkGameState();
          break;
        }
      }
    });
  }

  void moveDown() {
    if (isGameOver) return;

    setState(() {
      currentPiece.moveDown();

      if (_isColliding(currentPiece)) {
        // Move piece back up
        currentPiece.moveUp();

        // Lock piece in place
        _placePiece();

        // Check for game over or prepare for next piece
        _checkGameState();
      }
    });
  }

  void _checkGameState() {
    // Check for completed lines
    final linesCleared = _clearLines();
    if (linesCleared > 0) {
      // Add score based on lines cleared
      score += linesCleared * 100;
    }

    // Check for game over
    if (_isGameOverCondition()) {
      _gameOver();
      return;
    }

    // Create next piece
    currentPiece = nextPiece;
    nextPiece = Tetromino.getRandom();
  }

  void _placePiece() {
    for (final point in currentPiece.positions) {
      final x = point.dx.toInt() + currentPiece.x;
      final y = point.dy.toInt() + currentPiece.y;

      if (x >= 0 && x < boardWidth && y >= 0 && y < boardHeight) {
        gameBoard[y][x] = currentPiece.typeToInt();
      }
    }
  }

  int _clearLines() {
    int linesCleared = 0;

    for (int y = boardHeight - 1; y >= 0; y--) {
      bool isLineComplete = true;

      for (int x = 0; x < boardWidth; x++) {
        if (gameBoard[y][x] == 0) {
          isLineComplete = false;
          break;
        }
      }

      if (isLineComplete) {
        linesCleared++;

        // Shift all lines above down
        for (int y2 = y; y2 > 0; y2--) {
          for (int x = 0; x < boardWidth; x++) {
            gameBoard[y2][x] = gameBoard[y2 - 1][x];
          }
        }

        // Create a new empty line at the top
        for (int x = 0; x < boardWidth; x++) {
          gameBoard[0][x] = 0;
        }

        // Since the line is now removed, check the same y index again
        y++;
      }
    }

    return linesCleared;
  }

  bool _isColliding(Tetromino piece) {
    for (final point in piece.positions) {
      final x = point.dx.toInt() + piece.x;
      final y = point.dy.toInt() + piece.y;

      // Check boundaries
      if (x < 0 || x >= boardWidth || y >= boardHeight) {
        return true;
      }

      // Check collision with locked pieces (only if piece is within the board)
      if (y >= 0 && gameBoard[y][x] != 0) {
        return true;
      }
    }

    return false;
  }

  bool _isGameOverCondition() {
    // Check if any blocks in the top row are filled
    for (int x = 0; x < boardWidth; x++) {
      if (gameBoard[0][x] != 0) {
        return true;
      }
    }

    // Also check if the new piece would collide immediately
    return _isColliding(nextPiece);
  }

  void _gameOver() {
    setState(() {
      isGameOver = true;
    });

    gameTimer.cancel();
    cancelFastDrop();
    _saveHighScore();

    // Show game over dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Your score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Main Menu'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      isGameOver = false;
      score = 0;
      gameBoard = List.generate(
          boardHeight, (_) => List.generate(boardWidth, (_) => 0));
      currentPiece = Tetromino.getRandom();
      nextPiece = Tetromino.getRandom();
    });

    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!isGameOver) {
        moveDown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isGameOver
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Restart Game?'),
                        content: const Text(
                            'Are you sure you want to restart? Your current progress will be lost.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _restartGame();
                            },
                            child: const Text('Restart'),
                          ),
                        ],
                      ),
                    );
                  },
          ),
        ],
      ),
      body: BlocBuilder<ScoreBloc, ScoreState>(
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ScoreBoard(
                    score: score,
                    highScore: state.highScore,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: GameBoard(
                      board: gameBoard,
                      currentPiece: currentPiece,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NextPiece(piece: nextPiece),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: moveLeft,
                        child: const Icon(Icons.arrow_left),
                      ),
                      ElevatedButton(
                        onPressed: rotate,
                        child: const Icon(Icons.rotate_right),
                      ),
                      ElevatedButton(
                        onPressed: moveRight,
                        child: const Icon(Icons.arrow_right),
                      ),
                      GestureDetector(
                        onTapDown: (_) => startFastDrop(),
                        onTapUp: (_) => cancelFastDrop(),
                        onTapCancel: cancelFastDrop,
                        child: ElevatedButton(
                          onPressed: null,
                          child: const Icon(Icons.arrow_drop_down),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: hardDrop,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Icon(Icons.arrow_downward),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
