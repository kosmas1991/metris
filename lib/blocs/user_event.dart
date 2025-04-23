part of 'user_bloc.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

class UserRegisterRequested extends UserEvent {
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String password;

  const UserRegisterRequested({
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.password,
  });

  @override
  List<Object?> get props => [username, email, firstName, lastName, password];
}

class UserLoginRequested extends UserEvent {
  final String username;
  final String password;

  const UserLoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class UserAutoLoginRequested extends UserEvent {}

class UserLogoutRequested extends UserEvent {}
