import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_room.dart';
import '../models/tetromino.dart';

class MultiplayerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new game room
  Future<GameRoom?> createRoom() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      // Generate a random tetromino type for both players to start with
      final initialType = Tetromino.getRandomType();

      final roomData = {
        'hostId': currentUser.uid,
        'guestId': null,
        'isActive': true,
        'currentTetrominoType': initialType,
        'createdAt': FieldValue.serverTimestamp(),
        'hostGameState': null,
        'guestGameState': null,
      };

      final docRef = await _firestore.collection('gameRooms').add(roomData);
      final doc = await docRef.get();

      return GameRoom.fromFirestore(doc);
    } catch (e) {
      print('Error creating room: $e');
      return null;
    }
  }

  // Join an existing game room
  Future<bool> joinRoom(String roomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final roomDoc =
          await _firestore.collection('gameRooms').doc(roomId).get();

      if (!roomDoc.exists) return false;

      final roomData = roomDoc.data() as Map<String, dynamic>;

      // Check if room is already full or if player is the host
      if (roomData['guestId'] != null ||
          roomData['hostId'] == currentUser.uid) {
        return false;
      }

      // Join the room
      await _firestore
          .collection('gameRooms')
          .doc(roomId)
          .update({'guestId': currentUser.uid});

      return true;
    } catch (e) {
      print('Error joining room: $e');
      return false;
    }
  }

  // Leave a game room
  Future<void> leaveRoom(String roomId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final roomDoc =
          await _firestore.collection('gameRooms').doc(roomId).get();

      if (!roomDoc.exists) return;

      final roomData = roomDoc.data() as Map<String, dynamic>;

      if (roomData['hostId'] == currentUser.uid) {
        // If host leaves, delete the room
        await _firestore.collection('gameRooms').doc(roomId).delete();
      } else if (roomData['guestId'] == currentUser.uid) {
        // If guest leaves, remove guest from room
        await _firestore
            .collection('gameRooms')
            .doc(roomId)
            .update({'guestId': null});
      }
    } catch (e) {
      print('Error leaving room: $e');
    }
  }

  // Get available game rooms (for lobby)
  Stream<List<GameRoom>> getAvailableRooms() {
    return _firestore
        .collection('gameRooms')
        .where('isActive', isEqualTo: true)
        .where('guestId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => GameRoom.fromFirestore(doc)).toList();
    });
  }

  // Get a specific game room
  Stream<GameRoom?> getRoomById(String roomId) {
    return _firestore
        .collection('gameRooms')
        .doc(roomId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return GameRoom.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update game state for a player
  Future<void> updateGameState(
      String roomId, GameState gameState, bool isHost, int linesCleared) async {
    try {
      final field = isHost ? 'hostGameState' : 'guestGameState';

      await _firestore.collection('gameRooms').doc(roomId).update({
        field: gameState.toMap(),
      });

      // If lines were cleared, send them to opponent
      if (linesCleared > 0) {
        await sendLinesToOpponent(roomId, linesCleared, isHost);
      }
    } catch (e) {
      print('Error updating game state: $e');
    }
  }

  // Send cleared lines to opponent (as "garbage")
  Future<void> sendLinesToOpponent(
      String roomId, int linesCleared, bool isHost) async {
    try {
      final roomDoc =
          await _firestore.collection('gameRooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final room = GameRoom.fromFirestore(roomDoc);

      // Get opponent game state
      final opponentGameState =
          isHost ? room.guestGameState : room.hostGameState;
      if (opponentGameState == null) return;

      // Add garbage lines to opponent's board
      final updatedBoard =
          _addGarbageLines(opponentGameState.board, linesCleared);

      // Update opponent's game state
      final updatedGameState = opponentGameState.copyWith(board: updatedBoard);

      final field = isHost ? 'guestGameState' : 'hostGameState';
      await _firestore.collection('gameRooms').doc(roomId).update({
        field: updatedGameState.toMap(),
      });
    } catch (e) {
      print('Error sending lines to opponent: $e');
    }
  }

  // Helper method to add garbage lines to board
  List<List<int>> _addGarbageLines(List<List<int>> board, int linesCount) {
    final boardHeight = board.length;
    final boardWidth = board[0].length;

    // Create a new board with the same dimensions
    final newBoard = List<List<int>>.from(board);

    // Move existing rows up
    for (int y = linesCount; y < boardHeight; y++) {
      newBoard[y - linesCount] = List<int>.from(board[y]);
    }

    // Generate random empty space position for garbage lines
    final emptyCol = (DateTime.now().millisecondsSinceEpoch % boardWidth);

    // Fill bottom rows with garbage lines
    for (int y = boardHeight - linesCount; y < boardHeight; y++) {
      newBoard[y] = List<int>.filled(
          boardWidth, 8); // Using a special value (8) for garbage blocks
      newBoard[y][emptyCol] = 0; // Leave one empty space
    }

    return newBoard;
  }

  // Get next tetromino for both players
  Future<String> updateNextTetromino(String roomId) async {
    try {
      final nextType = Tetromino.getRandomType();

      await _firestore
          .collection('gameRooms')
          .doc(roomId)
          .update({'currentTetrominoType': nextType});

      return nextType;
    } catch (e) {
      print('Error updating next tetromino: $e');
      return Tetromino.getRandomType(); // Fallback
    }
  }

  // End the game and update scores
  Future<void> endGame(String roomId, String winnerId) async {
    try {
      await _firestore
          .collection('gameRooms')
          .doc(roomId)
          .update({'isActive': false, 'winnerId': winnerId});

      // Update player stats
      final roomDoc =
          await _firestore.collection('gameRooms').doc(roomId).get();
      if (!roomDoc.exists) return;

      final room = GameRoom.fromFirestore(roomDoc);

      // Update host stats
      await _firestore.collection('players').doc(room.hostId).update({
        'totalGames': FieldValue.increment(1),
        'wins': room.hostId == winnerId
            ? FieldValue.increment(1)
            : FieldValue.increment(0)
      });

      // Update guest stats if there was a guest
      if (room.guestId != null) {
        await _firestore.collection('players').doc(room.guestId!).update({
          'totalGames': FieldValue.increment(1),
          'wins': room.guestId == winnerId
              ? FieldValue.increment(1)
              : FieldValue.increment(0)
        });
      }
    } catch (e) {
      print('Error ending game: $e');
    }
  }
}
