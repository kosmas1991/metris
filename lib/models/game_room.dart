import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GameRoom extends Equatable {
  final String id;
  final String hostId;
  final String? guestId;
  final bool isActive;
  final String currentTetrominoType;
  final Timestamp createdAt;
  final GameState? hostGameState;
  final GameState? guestGameState;

  const GameRoom({
    required this.id,
    required this.hostId,
    this.guestId,
    required this.isActive,
    required this.currentTetrominoType,
    required this.createdAt,
    this.hostGameState,
    this.guestGameState,
  });

  GameRoom copyWith({
    String? id,
    String? hostId,
    String? guestId,
    bool? isActive,
    String? currentTetrominoType,
    Timestamp? createdAt,
    GameState? hostGameState,
    GameState? guestGameState,
  }) {
    return GameRoom(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      guestId: guestId ?? this.guestId,
      isActive: isActive ?? this.isActive,
      currentTetrominoType: currentTetrominoType ?? this.currentTetrominoType,
      createdAt: createdAt ?? this.createdAt,
      hostGameState: hostGameState ?? this.hostGameState,
      guestGameState: guestGameState ?? this.guestGameState,
    );
  }

  factory GameRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameRoom(
      id: doc.id,
      hostId: data['hostId'] ?? '',
      guestId: data['guestId'],
      isActive: data['isActive'] ?? true,
      currentTetrominoType: data['currentTetrominoType'] ?? 'I',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      hostGameState: data['hostGameState'] != null
          ? GameState.fromMap(data['hostGameState'])
          : null,
      guestGameState: data['guestGameState'] != null
          ? GameState.fromMap(data['guestGameState'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'guestId': guestId,
      'isActive': isActive,
      'currentTetrominoType': currentTetrominoType,
      'createdAt': createdAt,
      'hostGameState': hostGameState?.toMap(),
      'guestGameState': guestGameState?.toMap(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        hostId,
        guestId,
        isActive,
        currentTetrominoType,
        createdAt,
        hostGameState,
        guestGameState
      ];
}

class GameState extends Equatable {
  final List<List<int>> board;
  final int score;
  final bool isGameOver;
  final int linesCleared;

  const GameState({
    required this.board,
    required this.score,
    required this.isGameOver,
    required this.linesCleared,
  });

  GameState copyWith({
    List<List<int>>? board,
    int? score,
    bool? isGameOver,
    int? linesCleared,
  }) {
    return GameState(
      board: board ?? this.board,
      score: score ?? this.score,
      isGameOver: isGameOver ?? this.isGameOver,
      linesCleared: linesCleared ?? this.linesCleared,
    );
  }

  factory GameState.fromMap(Map<String, dynamic> map) {
    final List<dynamic> boardData = map['board'] ?? [];
    final List<List<int>> parsedBoard = boardData.map((row) {
      return (row as List<dynamic>).map((cell) => cell as int).toList();
    }).toList();

    return GameState(
      board: parsedBoard,
      score: map['score'] ?? 0,
      isGameOver: map['isGameOver'] ?? false,
      linesCleared: map['linesCleared'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'board': board,
      'score': score,
      'isGameOver': isGameOver,
      'linesCleared': linesCleared,
    };
  }

  @override
  List<Object?> get props => [board, score, isGameOver, linesCleared];
}
