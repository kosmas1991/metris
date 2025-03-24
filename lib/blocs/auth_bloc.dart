import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/player.dart';

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {}

class SignInAnonymously extends AuthEvent {}

class SignOut extends AuthEvent {}

class UpdatePlayerName extends AuthEvent {
  final String displayName;

  const UpdatePlayerName(this.displayName);

  @override
  List<Object?> get props => [displayName];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final Player player;

  const Authenticated(this.player);

  @override
  List<Object?> get props => [player];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService = AuthService();
  StreamSubscription? _authStateSubscription;

  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<SignInAnonymously>(_onSignInAnonymously);
    on<SignOut>(_onSignOut);
    on<UpdatePlayerName>(_onUpdatePlayerName);

    // Listen to auth state changes
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        _fetchPlayerData();
      } else {
        add(AppStarted());
      }
    });
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final user = _authService.currentUser;

      if (user != null) {
        await _fetchPlayerData();
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('Authentication error: $e'));
      emit(Unauthenticated());
    }
  }

  void _onSignInAnonymously(
      SignInAnonymously event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    try {
      final user = await _authService.signInAnonymously();

      if (user != null) {
        await _fetchPlayerData();
      } else {
        emit(AuthError('Failed to sign in anonymously'));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('Authentication error: $e'));
      emit(Unauthenticated());
    }
  }

  void _onSignOut(SignOut event, Emitter<AuthState> emit) async {
    try {
      await _authService.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError('Error signing out: $e'));
    }
  }

  void _onUpdatePlayerName(
      UpdatePlayerName event, Emitter<AuthState> emit) async {
    if (state is Authenticated) {
      try {
        await _authService.updateDisplayName(event.displayName);
        await _fetchPlayerData();
      } catch (e) {
        emit(AuthError('Error updating name: $e'));
        emit(state); // Revert to previous state
      }
    }
  }

  Future<void> _fetchPlayerData() async {
    try {
      final player = await _authService.getPlayerData();

      if (player != null) {
        emit(Authenticated(player));
      } else {
        emit(AuthError('Could not fetch player data'));
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('Error fetching player data: $e'));
      emit(Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
