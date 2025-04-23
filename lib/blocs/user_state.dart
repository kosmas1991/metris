part of 'user_bloc.dart';

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserRegisterSuccess extends UserState {}

/// State to store user credentials for auto login
class UserCredentials extends UserState {
  final String username;
  final String password;

  const UserCredentials({
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [username, password];
}

class UserAuthenticated extends UserState {
  final String accessToken;
  final String tokenType;
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String role;
  final bool isActive;
  // hashed_password is intentionally omitted for security

  const UserAuthenticated({
    required this.accessToken,
    required this.tokenType,
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.role,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        accessToken,
        tokenType,
        id,
        firstName,
        lastName,
        email,
        username,
        role,
        isActive,
      ];
}

class UserFailure extends UserState {
  final String message;
  const UserFailure({required this.message});
  @override
  List<Object?> get props => [message];
}
