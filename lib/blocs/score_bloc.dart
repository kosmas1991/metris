import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class ScoreEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class UpdateScore extends ScoreEvent {
  final int score;

  UpdateScore(this.score);

  @override
  List<Object> get props => [score];
}

class UpdateHighScore extends ScoreEvent {
  final int highScore;

  UpdateHighScore(this.highScore);

  @override
  List<Object> get props => [highScore];
}

class ResetScore extends ScoreEvent {}

// State
class ScoreState extends Equatable {
  final int currentScore;
  final int highScore;

  const ScoreState({
    this.currentScore = 0,
    this.highScore = 0,
  });

  ScoreState copyWith({
    int? currentScore,
    int? highScore,
  }) {
    return ScoreState(
      currentScore: currentScore ?? this.currentScore,
      highScore: highScore ?? this.highScore,
    );
  }

  @override
  List<Object> get props => [currentScore, highScore];

  Map<String, dynamic> toJson() {
    return {
      'currentScore': currentScore,
      'highScore': highScore,
    };
  }

  factory ScoreState.fromJson(Map<String, dynamic> json) {
    return ScoreState(
      currentScore: json['currentScore'] as int? ?? 0,
      highScore: json['highScore'] as int? ?? 0,
    );
  }
}

class ScoreBloc extends HydratedBloc<ScoreEvent, ScoreState> {
  ScoreBloc() : super(const ScoreState()) {
    on<UpdateScore>(_onUpdateScore);
    on<ResetScore>(_onResetScore);
    on<UpdateHighScore>(_onUpdateHighScore);
  }

  void _onUpdateScore(UpdateScore event, Emitter<ScoreState> emit) {
    final newHighScore =
        event.score > state.highScore ? event.score : state.highScore;
    emit(state.copyWith(
      currentScore: event.score,
      highScore: newHighScore,
    ));
  }

  void _onResetScore(ResetScore event, Emitter<ScoreState> emit) {
    emit(state.copyWith(currentScore: 0));
  }

  void _onUpdateHighScore(UpdateHighScore event, Emitter<ScoreState> emit) {
    emit(state.copyWith(highScore: event.highScore));
  }

  @override
  ScoreState? fromJson(Map<String, dynamic> json) {
    return ScoreState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(ScoreState state) {
    return state.toJson();
  }
}
