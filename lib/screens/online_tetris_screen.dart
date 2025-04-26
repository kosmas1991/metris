import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/tetromino.dart';
import '../widgets/game_board.dart';
import '../widgets/next_piece.dart';
import '../blocs/rotation_bloc.dart';
import '../blocs/user_bloc.dart';
import '../config/server_config.dart';

class OnlineTetrisScreen extends StatefulWidget {
  final String gameUid;

  const OnlineTetrisScreen({super.key, required this.gameUid});

  @override
  State<OnlineTetrisScreen> createState() => _OnlineTetrisScreenState();
}

class _OnlineTetrisScreenState extends State<OnlineTetrisScreen> {
  // Focus node to handle keyboard inputs
  final FocusNode _focusNode = FocusNode();

  static const int boardWidth = 10;
  static const int boardHeight = 20;

  // Game data
  late List<List<int>> gameBoard;
  late Tetromino currentPiece;
  late Tetromino nextPiece;
  late Timer gameTimer;
  bool isGameOver = false;
  String? gameResult;

  // WebSocket and opponent data
  WebSocketChannel? _gameChannel;
  StreamSubscription? _gameSubscription;
  String? _token;
  String? _opponentUsername;
  List<List<int>>? _opponentBoard; // Opponent's game board
  bool _bothPlayersConnected = false;
  bool _gameStarted = false;

  // Game parameters from server
  List<int>? _pieceSequence;
  int _currentPieceIndex = 0;
  int _garbageColumn = 0;
  int _garbageQueue = 0;
  int _linesCleared = 0; // Counter for lines cleared by the player

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
    // Initialize with empty game board until we get data from server
    gameBoard =
        List.generate(boardHeight, (_) => List.generate(boardWidth, (_) => 0));
    // Create empty initial pieces
    currentPiece = Tetromino(type: 1); // Will be replaced with server data
    nextPiece = Tetromino(type: 1); // Will be replaced with server data

    // Connect to the game WebSocket
    _connectGameWebSocket();
  }

  void _connectGameWebSocket() {
    final userState = context.read<UserBloc>().state;
    if (userState is UserAuthenticated) {
      _token = userState.accessToken;

      // Connect to game websocket using the ServerConfig
      final url =
          '${ServerConfig.wsUrl}/ws/game/${widget.gameUid}?token=$_token';
      _gameChannel = WebSocketChannel.connect(Uri.parse(url));

      _gameSubscription = _gameChannel!.stream.listen((event) {
        final data = jsonDecode(event);

        if (data['event'] == 'game_start') {
          _handleGameStart(data);
        } else if (data['event'] == 'both_players_connected') {
          _handleBothPlayersConnected();
        } else if (data['event'] == 'opponent_board_update') {
          _handleOpponentBoardUpdate(data);
        } else if (data['event'] == 'receive_garbage') {
          _handleReceiveGarbage(data);
        } else if (data['event'] == 'game_over') {
          _handleGameOver(data);
        } else if (data['event'] == 'opponent_disconnected') {
          _handleOpponentDisconnected(data);
        } else if (data['error'] != null) {
          _showError(data['error']);
        }
      }, onError: (e) {
        _showError("Connection error: $e");
      }, onDone: () {
        if (!isGameOver) {
          _showError("Connection closed unexpectedly");
        }
      });
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _handleGameStart(Map<String, dynamic> data) {
    final gameData = data['gameData'];
    setState(() {
      _pieceSequence = List<int>.from(gameData['pieces']);
      _garbageColumn = gameData['garbageColumn'];
      _opponentUsername = gameData['opponent'];
      _gameStarted = true;

      // Initialize first and next pieces from the sequence
      currentPiece = Tetromino(type: _pieceSequence![_currentPieceIndex]);
      _currentPieceIndex++;
      nextPiece = Tetromino(type: _pieceSequence![_currentPieceIndex]);

      // Start the game timer
      gameTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!isGameOver) {
          moveDown();
        }
      });
    });
  }

  void _handleBothPlayersConnected() {
    setState(() {
      _bothPlayersConnected = true;
    });

    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(
    //         'Both players connected. Game starting with $_opponentUsername!'),
    //     backgroundColor: Colors.green,
    //     duration: const Duration(seconds: 3),
    //   ),
    // );
  }

  void _handleOpponentBoardUpdate(Map<String, dynamic> data) {
    setState(() {
      _opponentBoard =
          List<List<int>>.from(data['board'].map((row) => List<int>.from(row)));
    });
  }

  void _handleReceiveGarbage(Map<String, dynamic> data) {
    setState(() {
      _garbageQueue += (data['lines'] as num).toInt();
    });

    // Add the garbage on next piece placement
    // The actual garbage addition happens in the moveDown() method when a piece is placed
  }

  void _handleGameOver(Map<String, dynamic> data) {
    final winner = data['winner'];
    final loser = data['loser'];
    final userState = context.read<UserBloc>().state;
    String username = '';

    if (userState is UserAuthenticated) {
      username = userState.username;
    }

    setState(() {
      isGameOver = true;
      gameResult = (username == winner) ? 'You Win!' : 'You Lose!';
    });

    gameTimer.cancel();

    // Show game over dialog
    _showGameOverDialog(winner, loser);
  }

  void _handleOpponentDisconnected(Map<String, dynamic> data) {
    final username = data['username'];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$username disconnected!'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );

    // Automatically return to lobby after opponent disconnects
    Future.delayed(const Duration(seconds: 3), () {
      _returnToLobby();
    });
  }

  void _showError(String errorMessage) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showGameOverDialog(String winner, String loser) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text(
          'Game Over',
          style: TextStyle(
            color: Colors.green,
            fontFamily: 'PressStart2P',
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              winner == loser ? 'Draw!' : '$winner wins!',
              style: const TextStyle(
                color: Colors.green,
                fontFamily: 'PressStart2P',
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildRetroButton(
              'RETURN TO LOBBY',
              onPressed: () {
                Navigator.of(context).pop();
                _returnToLobby();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _returnToLobby() {
    Navigator.of(context).pushReplacementNamed('/lobby');
  }

  @override
  void dispose() {
    gameTimer.cancel();
    fastDropTimer?.cancel();
    moveLeftTimer?.cancel();
    moveRightTimer?.cancel();
    _focusNode.dispose();
    _gameSubscription?.cancel();
    _gameChannel?.sink.close();
    super.dispose();
  }

  void moveLeft() {
    if (isGameOver || !_gameStarted) return;

    if (currentPiece.canMoveLeft(gameBoard)) {
      setState(() {
        currentPiece.moveLeft();
      });
      // Send board state update after moving left
      _sendBoardState();
    }
  }

  void moveRight() {
    if (isGameOver || !_gameStarted) return;

    if (currentPiece.canMoveRight(gameBoard)) {
      setState(() {
        currentPiece.moveRight();
      });
      // Send board state update after moving right
      _sendBoardState();
    }
  }

  void rotate() {
    if (isGameOver || !_gameStarted) return;

    final rotationState = context.read<RotationBloc>().state;
    if (currentPiece.canRotate(gameBoard)) {
      setState(() {
        currentPiece.rotate(rotationState);
      });
      // Send board state update after rotation
      _sendBoardState();
    }
  }

  void moveDown() {
    if (isGameOver || !_gameStarted) return;

    if (currentPiece.canMoveDown(gameBoard)) {
      setState(() {
        currentPiece.moveDown();
      });
      // Send board state update after moving down
      _sendBoardState();
    } else {
      // Lock the piece in place
      placePiece();

      // First, check for completed lines
      checkLines();

      // Then add garbage lines if there are any queued, now with proper neutralization
      addGarbageLines();

      // Send current board state to opponent
      _sendBoardState();

      // Get next piece from the sequence
      _currentPieceIndex++;
      if (_currentPieceIndex < _pieceSequence!.length - 1) {
        currentPiece = nextPiece;
        nextPiece = Tetromino(type: _pieceSequence![_currentPieceIndex + 1]);
      } else {
        // In the unlikely case we run out of pieces in the sequence, just use random ones
        currentPiece = nextPiece;
        nextPiece = Tetromino.getRandom();
      }

      // Check for game over
      if (!currentPiece.canMoveDown(gameBoard)) {
        setState(() {
          isGameOver = true;
        });

        // Send game lost message to server
        _gameChannel?.sink.add(jsonEncode({"lost": true}));

        gameTimer.cancel();
        cancelFastDrop();
      }
    }
  }

  // New method to start fast dropping
  void startFastDrop() {
    if (isGameOver || isHoldingDown || !_gameStarted) return;

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
    if (isGameOver || isMovingLeft || !_gameStarted) return;

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
    if (isGameOver || isMovingRight || !_gameStarted) return;

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
        // Remove completed lines
        for (final line in linesToRemove) {
          gameBoard.removeAt(line);
          gameBoard.insert(0, List.generate(boardWidth, (_) => 0));
        }

        // Set the lines cleared count for garbage neutralization
        _linesCleared = linesToRemove.length;
      });

      // Send board state update after lines are cleared
      _sendBoardState();

      // Calculate garbage lines to send based on how many lines were cleared
      int garbageLines = 0;
      switch (linesToRemove.length) {
        case 1:
          garbageLines = 1;
          break;
        case 2:
          garbageLines = 2;
          break;
        case 3:
          garbageLines = 3;
          break;
        case 4:
          garbageLines = 4;
          break;
      }

      // If we have incoming garbage, it will be neutralized in addGarbageLines
      // If we have no incoming garbage, send the attack to opponent right away
      if (_garbageQueue <= 0 && garbageLines > 0) {
        _sendGarbageLines(garbageLines);
      }
    }
  }

  void _sendBoardState() {
    if (_gameChannel != null && _bothPlayersConnected) {
      // Create a copy of the game board to add the current piece
      List<List<int>> boardWithPiece = List.generate(
        boardHeight,
        (y) => List.generate(boardWidth, (x) => gameBoard[y][x]),
      );

      // Add current piece to the board copy
      for (final point in currentPiece.positions) {
        final x = point.dx.toInt() + currentPiece.x;
        final y = point.dy.toInt() + currentPiece.y;

        if (x >= 0 && x < boardWidth && y >= 0 && y < boardHeight) {
          boardWithPiece[y][x] = currentPiece.type;
        }
      }

      _gameChannel!.sink.add(jsonEncode({"board": boardWithPiece}));
    }
  }

  void _sendGarbageLines(int lines) {
    if (_gameChannel != null && _bothPlayersConnected) {
      _gameChannel!.sink.add(jsonEncode({"garbage": lines}));
    }
  }

  // Add garbage lines function with neutralization logic
  void addGarbageLines() {
    if (_garbageQueue <= 0) return;

    // Get the count of lines that were just cleared
    int linesJustCleared = _linesCleared;
    // Reset the counter for next time
    _linesCleared = 0;

    // Apply neutralization logic
    int netGarbageLines = _garbageQueue - linesJustCleared;

    if (netGarbageLines <= 0) {
      // Player cleared more or equal lines than garbage - no garbage added

      // If player cleared more lines than garbage, send the difference as attack
      // Only send if they cleared MORE than their garbage (not equal)
      if (netGarbageLines < 0) {
        // Convert negative net garbage to positive attack garbage
        int attackLines = -netGarbageLines;
        _sendGarbageLines(attackLines);
      }
      // If equal (netGarbageLines == 0), player just neutralizes and doesn't send any attack

      // Reset the garbage queue since it's been fully neutralized
      setState(() {
        _garbageQueue = 0;
      });

      return;
    }

    // If we get here, player still has some garbage to receive after neutralization
    setState(() {
      // Update the garbage queue to the neutralized amount
      _garbageQueue = netGarbageLines;

      // How many garbage lines to add this turn
      int linesToAdd = netGarbageLines;

      // Remove rows from the top to make room for garbage
      for (int i = 0; i < linesToAdd; i++) {
        gameBoard.removeAt(0);
      }

      // Add garbage lines at the bottom
      for (int i = 0; i < linesToAdd; i++) {
        List<int> garbageLine = List.generate(
            boardWidth,
            (index) =>
                index == _garbageColumn ? 0 : 8 // Use 8 as garbage block type
            );
        gameBoard.add(garbageLine);
      }

      // Reset the garbage queue after adding
      _garbageQueue = 0;
    });

    // Send board state update after adding garbage lines
    _sendBoardState();
  }

  // Queue garbage lines (called when garbage buttons are pressed)
  void queueGarbageLines(int lines) {
    if (isGameOver || !_gameStarted) return;

    setState(() {
      _garbageQueue += lines;
    });
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
    return SafeArea(
      child: WillPopScope(
        // Prevent going back with the back button
        onWillPop: () async => false,
        child: Center(
          child: SizedBox(
            width: 450,
            child: Scaffold(
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
                  child: _gameStarted
                      ? _buildGameContent()
                      : _buildLoadingScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'WAITING FOR OPPONENT',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 16,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 30),
          if (_opponentUsername != null)
            Text(
              'Playing against: $_opponentUsername',
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 12,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Game info instead of scoreboard
        _buildGameInfo(),
        Expanded(
          child: Row(
            children: [
              const SizedBox(width: 10),
              // Main game board
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
              // Side panel with next piece, opponent's board, and garbage buttons
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Next piece display
                    NextPiece(piece: nextPiece),
                    const SizedBox(height: 20),
                    // Opponent's board display
                    _buildOpponentBoard(),
                    // const SizedBox(height: 20),
                    // // Garbage buttons
                    // _buildGarbageButtons(),
                  ],
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
        // Control buttons
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
        const SizedBox(height: 10),
        // Keyboard controls hint
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
    );
  }

  Widget _buildGameInfo() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'VS $_opponentUsername',
            style: const TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: Colors.green,
            ),
          ),
          // if (isGameOver && gameResult != null)
          //   Column(
          //     children: [
          //       SizedBox(
          //         height: 10,
          //       ),
          //       Text(
          //         gameResult!,
          //         style: TextStyle(
          //           fontFamily: 'PressStart2P',
          //           fontSize: 12,
          //           color: gameResult == 'You Win!' ? Colors.green : Colors.red,
          //         ),
          //       ),
          //     ],
          //   ),
          if (_garbageQueue > 0)
            Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'Garbage: $_garbageQueue',
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),

          Text("garbage column: ${_garbageColumn + 1}")
        ],
      ),
    );
  }

  Widget _buildOpponentBoard() {
    if (_opponentBoard == null) {
      return Container(
        height: 200,
        width: 100,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.green,
            width: 2.0,
          ),
          color: Colors.black,
        ),
        child: const Center(
          child: Text(
            'WAITING\nFOR\nOPPONENT',
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 12,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.green,
          width: 2.0,
        ),
      ),
      width: 100,
      height: 200,
      child: CustomPaint(
        painter: _OpponentBoardPainter(board: _opponentBoard!),
        child: Container(),
      ),
    );
  }

  Widget _buildRetroButton(String text, {required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
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
          onTapDown: (_) => onPressed(),
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
            onTapDown: (_) => onPressed(),
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
}

// Custom painter for the opponent's board
class _OpponentBoardPainter extends CustomPainter {
  final List<List<int>> board;

  _OpponentBoardPainter({required this.board});

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / board[0].length;
    final cellHeight = size.height / board.length;

    // Draw the opponent's pieces
    for (int y = 0; y < board.length; y++) {
      for (int x = 0; x < board[y].length; x++) {
        if (board[y][x] != 0) {
          final rect = Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth,
            cellHeight,
          );

          // Use a specific color for garbage blocks (type 8)
          // Otherwise use the tetromino colors
          Color blockColor;
          if (board[y][x] == 8) {
            // Gray color for garbage blocks
            blockColor = Colors.grey.shade700;
          } else {
            blockColor = Tetromino.colors[board[y][x]];
          }

          canvas.drawRect(
            rect,
            Paint()..color = blockColor,
          );

          // Draw cell border
          canvas.drawRect(
            rect,
            Paint()
              ..color = Colors.black
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.5,
          );
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
