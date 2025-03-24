import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String displayName;
  final int totalGames;
  final int wins;
  final int highScore;
  final bool isOnline;

  const Player({
    required this.id,
    required this.displayName,
    this.totalGames = 0,
    this.wins = 0,
    this.highScore = 0,
    this.isOnline = false,
  });

  Player copyWith({
    String? id,
    String? displayName,
    int? totalGames,
    int? wins,
    int? highScore,
    bool? isOnline,
  }) {
    return Player(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      totalGames: totalGames ?? this.totalGames,
      wins: wins ?? this.wins,
      highScore: highScore ?? this.highScore,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  factory Player.fromMap(Map<String, dynamic> map, String docId) {
    return Player(
      id: docId,
      displayName: map['displayName'] ?? 'Player',
      totalGames: map['totalGames'] ?? 0,
      wins: map['wins'] ?? 0,
      highScore: map['highScore'] ?? 0,
      isOnline: map['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'totalGames': totalGames,
      'wins': wins,
      'highScore': highScore,
      'isOnline': isOnline,
    };
  }

  @override
  List<Object?> get props =>
      [id, displayName, totalGames, wins, highScore, isOnline];
}
