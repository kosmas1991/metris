import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../blocs/multiplayer_bloc.dart';
import '../models/game_room.dart';
import '../models/tetromino.dart';
import '../widgets/game_board.dart';
import '../widgets/next_piece.dart';
import '../widgets/score_board.dart';
import '../widgets/opponent_board.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final GameRoom room;
  final bool isHost;
  final String initialTetrominoType;

  const MultiplayerGameScreen({
    super.key,
    required this.room,
    required this.isHost,
    required this.initialTetrominoType,
  });

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  late List<List<int>> gameBoard;
  late List<List<int>> opponentBoard;
  late Tetromino currentPiece;
  late Tetromino nextPiece;
  late Timer gameTimer;

  int score = 0;
  bool isGameOver = false;
  Timer? fastDropTimer;
  int linesCleared = 0;
  int opponentLinesCleared = 0;

  static const int boardWidth = 10;
  static const int boardHeight = 20;

  @override
  void initState() {
    super.initState();
    initGame();
  }

  @override
  void didUpdateWidget(MultiplayerGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update opponent's game state
    final opponentGameState =
        widget.isHost ? widget.room.guestGameState : widget.room.hostGameState;

    if (opponentGameState != null) {
      setState(() {
        opponentBoard = opponentGameState.board;

        // Check if opponent cleared more lines since last update
        if (opponentGameState.linesCleared > opponentLinesCleared) {
          int newLinesCleared =
              opponentGameState.linesCleared - opponentLinesCleared;
          opponentLinesCleared = opponentGameState.linesCleared;

          // Add garbage lines to our board
          _addGarbageLines(newLinesCleared);
        }

        // Check if opponent's game is over
        if (opponentGameState.isGameOver && !isGameOver) {
          _onWin();
        }
      });
    }

    // Update the next piece if room's tetromino type changed
    if (oldWidget.room.currentTetrominoType !=
        widget.room.currentTetrominoType) {
      setState(() {
        nextPiece = Tetromino(type: widget.room.currentTetrominoType);
      });
    }
  }

  void _addGarbageLines(int lineCount) {
    // Shift existing board up
    for (int y = lineCount; y < boardHeight; y++) {
      for (int x = 0; x < boardWidth; x++) {
        gameBoard[y - lineCount][x] = gameBoard[y][x];
      }
    }

    // Generate random empty space position for garbage lines
    final emptyCol = (DateTime.now().millisecondsSinceEpoch % boardWidth);

    // Add garbage lines at the bottom
    for (int y = boardHeight - lineCount; y < boardHeight; y++) {
      for (int x = 0; x < boardWidth; x++) {
        gameBoard[y][x] =
            (x == emptyCol) ? 0 : 8; // 8 represents garbage blocks
      }
    }

    // Check if the current piece is now colliding
    if (_isColliding(currentPiece)) {
      // Try to move up to avoid collision
      currentPiece.moveUp(lineCount);

      // If still colliding after moving up, game over
      if (_isColliding(currentPiece)) {
        _gameOver();
      }
    }
  }

  void initGame() {
    // Initialize empty game boards
    gameBoard =
        List.generate(boardHeight, (_) => List.generate(boardWidth, (_) => 0));

    opponentBoard =
        List.generate(boardHeight, (_) => List.generate(boardWidth, (_) => 0));

    // Use the same tetromino type for both players (from room)
    currentPiece = Tetromino(type: widget.initialTetrominoType);
    nextPiece = Tetromino(type: widget.initialTetrominoType);

    // Request next tetromino
    context.read<MultiplayerBloc>().add(GetNextTetromino());

    // Start game timer
    gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!isGameOver) {
        moveDown();
      }
    });

    // Update game state to Firebase
    _updateGameState(0);
  }

  @override
  void dispose() {
    gameTimer.cancel();
    cancelFastDrop();

    // Make sure to leave the room when exiting
    if (!isGameOver) {
      context.read<MultiplayerBloc>().add(LeaveRoom());
    }

    super.dispose();
  }

  void moveLeft() {
    if (isGameOver) return;

    setState(() {
      currentPiece.moveLeft();
      if (_isColliding(currentPiece)) {
        currentPiece.moveRight();
      }
    });
  }

  void moveRight() {
    if (isGameOver) return;

    setState(() {
      currentPiece.moveRight();
      if (_isColliding(currentPiece)) {
        currentPiece.moveLeft();
      }
    });
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

  void moveDown() {
    if (isGameOver) return;

    setState(() {
      currentPiece.moveDown();

      if (_isColliding(currentPiece)) {
        // Move piece back up
        currentPiece.moveUp();

        // Lock piece in place
        _placePiece();

        // Check for completed lines
        final newLinesCleared = _clearLines();

        if (newLinesCleared > 0) {
          // Update total lines cleared
          linesCleared += newLinesCleared;

          // Add score based on lines cleared
          score += newLinesCleared * 100;

          // Update game state to Firebase with lines cleared
          _updateGameState(newLinesCleared);
        } else {
          // Update game state to Firebase without lines cleared
          _updateGameState(0);
        }

        // Check for game over
        if (_isGameOverCondition()) {
          _gameOver();
          return;
        }

        // Get the next tetromino type from the room
        currentPiece = nextPiece;

        // Request a new next piece
        context.read<MultiplayerBloc>().add(GetNextTetromino());
      }
    });
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

    // Update game state with game over flag
    final gameState = GameState(
      board: gameBoard,
      score: score,
      isGameOver: true,
      linesCleared: linesCleared,
    );

    // Use our user ID as loser ID
    final userId = widget.isHost ? widget.room.hostId : widget.room.guestId;

    // Update opponent as winner
    final winnerId = widget.isHost ? widget.room.guestId : widget.room.hostId;

    if (winnerId != null) {
      context.read<MultiplayerBloc>().add(EndGame(winnerId));
    }

    context.read<MultiplayerBloc>().add(UpdateGameState(gameState, 0));

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
            child: const Text('Back to Lobby'),
          ),
        ],
      ),
    );
  }

  void _onWin() {
    // Show win dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('You Win!'),
        content: Text('Your score: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Lobby'),
          ),
        ],
      ),
    );
  }

  void _updateGameState(int newLinesCleared) {
    if (widget.room.id.isEmpty) return;

    final gameState = GameState(
      board: gameBoard,
      score: score,
      isGameOver: isGameOver,
      linesCleared: linesCleared,
    );

    context
        .read<MultiplayerBloc>()
        .add(UpdateGameState(gameState, newLinesCleared));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? 'Hosting Game' : 'Joined Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              if (!isGameOver) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Leave Game?'),
                    content: const Text(
                        'Are you sure you want to leave? You will forfeit the match.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _gameOver();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: BlocListener<MultiplayerBloc, MultiplayerState>(
        listener: (context, state) {
          if (state is GameEnded) {
            // Game ended by opponent or server
            if (state.winnerId ==
                (widget.isHost ? widget.room.hostId : widget.room.guestId)) {
              // We won
              _onWin();
            }
          } else if (state is InRoom) {
            // Update next piece if changed
            if (state.nextTetrominoType != nextPiece.type) {
              setState(() {
                nextPiece = Tetromino(type: state.nextTetrominoType);
              });
            }
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ScoreBoard(
                  score: score,
                  highScore: 0,
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Main game board
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text('You',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: GameBoard(
                                board: gameBoard,
                                currentPiece: currentPiece,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Opponent's board
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            const Text('Opponent',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: OpponentBoard(
                                board: opponentBoard,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    NextPiece(piece: nextPiece),
                    const SizedBox(width: 20),
                    Column(
                      children: [
                        Text(
                          'Lines: $linesCleared',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Opponent: $opponentLinesCleared',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Game controls
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
