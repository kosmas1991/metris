import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/multiplayer_service.dart';
import '../models/game_room.dart';

// Events
abstract class MultiplayerEvent extends Equatable {
  const MultiplayerEvent();

  @override
  List<Object?> get props => [];
}

class LoadLobby extends MultiplayerEvent {}

class CreateRoom extends MultiplayerEvent {}

class JoinRoom extends MultiplayerEvent {
  final String roomId;

  const JoinRoom(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

class LeaveRoom extends MultiplayerEvent {}

class UpdateGameState extends MultiplayerEvent {
  final GameState gameState;
  final int linesCleared;

  const UpdateGameState(this.gameState, this.linesCleared);

  @override
  List<Object?> get props => [gameState, linesCleared];
}

class GetNextTetromino extends MultiplayerEvent {}

class EndGame extends MultiplayerEvent {
  final String winnerId;

  const EndGame(this.winnerId);

  @override
  List<Object?> get props => [winnerId];
}

// States
abstract class MultiplayerState extends Equatable {
  const MultiplayerState();

  @override
  List<Object?> get props => [];
}

class MultiplayerInitial extends MultiplayerState {}

class MultiplayerLoading extends MultiplayerState {}

class InLobby extends MultiplayerState {
  final List<GameRoom> availableRooms;

  const InLobby(this.availableRooms);

  @override
  List<Object?> get props => [availableRooms];
}

class InRoom extends MultiplayerState {
  final GameRoom room;
  final bool isHost;
  final String nextTetrominoType;

  const InRoom(this.room, this.isHost, this.nextTetrominoType);

  @override
  List<Object?> get props => [room, isHost, nextTetrominoType];
}

class GameEnded extends MultiplayerState {
  final String winnerId;
  final GameRoom room;

  const GameEnded(this.winnerId, this.room);

  @override
  List<Object?> get props => [winnerId, room];
}

class MultiplayerError extends MultiplayerState {
  final String message;

  const MultiplayerError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class MultiplayerBloc extends Bloc<MultiplayerEvent, MultiplayerState> {
  final MultiplayerService _multiplayerService = MultiplayerService();
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _currentRoomSubscription;
  String? _currentRoomId;
  bool _isHost = false;

  MultiplayerBloc() : super(MultiplayerInitial()) {
    on<LoadLobby>(_onLoadLobby);
    on<CreateRoom>(_onCreateRoom);
    on<JoinRoom>(_onJoinRoom);
    on<LeaveRoom>(_onLeaveRoom);
    on<UpdateGameState>(_onUpdateGameState);
    on<GetNextTetromino>(_onGetNextTetromino);
    on<EndGame>(_onEndGame);
  }

  void _onLoadLobby(LoadLobby event, Emitter<MultiplayerState> emit) {
    emit(MultiplayerLoading());

    // Cancel any existing subscriptions
    _roomsSubscription?.cancel();
    _currentRoomSubscription?.cancel();

    // Subscribe to available rooms
    _roomsSubscription =
        _multiplayerService.getAvailableRooms().listen((rooms) {
      emit(InLobby(rooms));
    }, onError: (error) {
      emit(MultiplayerError('Error loading rooms: $error'));
      emit(MultiplayerInitial());
    });
  }

  void _onCreateRoom(CreateRoom event, Emitter<MultiplayerState> emit) async {
    emit(MultiplayerLoading());

    try {
      final room = await _multiplayerService.createRoom();

      if (room != null) {
        _currentRoomId = room.id;
        _isHost = true;

        _subscribeToRoom(room.id);

        emit(InRoom(room, true, room.currentTetrominoType));
      } else {
        emit(MultiplayerError('Failed to create room'));
        add(LoadLobby());
      }
    } catch (e) {
      emit(MultiplayerError('Error creating room: $e'));
      add(LoadLobby());
    }
  }

  void _onJoinRoom(JoinRoom event, Emitter<MultiplayerState> emit) async {
    emit(MultiplayerLoading());

    try {
      final success = await _multiplayerService.joinRoom(event.roomId);

      if (success) {
        _currentRoomId = event.roomId;
        _isHost = false;

        _subscribeToRoom(event.roomId);
      } else {
        emit(MultiplayerError('Failed to join room'));
        add(LoadLobby());
      }
    } catch (e) {
      emit(MultiplayerError('Error joining room: $e'));
      add(LoadLobby());
    }
  }

  void _onLeaveRoom(LeaveRoom event, Emitter<MultiplayerState> emit) async {
    if (_currentRoomId != null) {
      try {
        await _multiplayerService.leaveRoom(_currentRoomId!);

        _currentRoomSubscription?.cancel();
        _currentRoomId = null;
        _isHost = false;

        add(LoadLobby());
      } catch (e) {
        emit(MultiplayerError('Error leaving room: $e'));
      }
    } else {
      add(LoadLobby());
    }
  }

  void _onUpdateGameState(
      UpdateGameState event, Emitter<MultiplayerState> emit) async {
    if (_currentRoomId == null || !(state is InRoom)) return;

    try {
      final currentState = state as InRoom;

      await _multiplayerService.updateGameState(
          _currentRoomId!, event.gameState, _isHost, event.linesCleared);

      // Don't emit a new state as the subscription will handle it
    } catch (e) {
      emit(MultiplayerError('Error updating game state: $e'));
      emit(state); // Revert to previous state
    }
  }

  void _onGetNextTetromino(
      GetNextTetromino event, Emitter<MultiplayerState> emit) async {
    if (_currentRoomId == null || !(state is InRoom)) return;

    try {
      final currentState = state as InRoom;
      final nextType =
          await _multiplayerService.updateNextTetromino(_currentRoomId!);

      emit(InRoom(currentState.room, _isHost, nextType));
    } catch (e) {
      emit(MultiplayerError('Error getting next tetromino: $e'));
      emit(state); // Revert to previous state
    }
  }

  void _onEndGame(EndGame event, Emitter<MultiplayerState> emit) async {
    if (_currentRoomId == null || !(state is InRoom)) return;

    try {
      final currentState = state as InRoom;

      await _multiplayerService.endGame(_currentRoomId!, event.winnerId);

      emit(GameEnded(event.winnerId, currentState.room));
    } catch (e) {
      emit(MultiplayerError('Error ending game: $e'));
      emit(state); // Revert to previous state
    }
  }

  void _subscribeToRoom(String roomId) {
    // Cancel any existing subscription
    _currentRoomSubscription?.cancel();

    // Subscribe to room updates
    _currentRoomSubscription =
        _multiplayerService.getRoomById(roomId).listen((room) {
      if (room != null) {
        if (state is InRoom) {
          final currentState = state as InRoom;
          emit(InRoom(room, _isHost, currentState.nextTetrominoType));
        } else {
          emit(InRoom(room, _isHost, room.currentTetrominoType));
        }
      } else {
        // Room was deleted or doesn't exist
        _currentRoomId = null;
        add(LoadLobby());
      }
    }, onError: (error) {
      emit(MultiplayerError('Error listening to room: $error'));
      add(LoadLobby());
    });
  }

  @override
  Future<void> close() {
    _roomsSubscription?.cancel();
    _currentRoomSubscription?.cancel();
    return super.close();
  }
}
