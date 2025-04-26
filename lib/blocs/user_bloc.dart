import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends HydratedBloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<UserRegisterRequested>(_onRegisterRequested);
    on<UserLoginRequested>(_onLoginRequested);
    on<UserLogoutRequested>(_onLogoutRequested);
    on<UserAutoLoginRequested>(_onAutoLoginRequested);

    // Automatically try to log in when bloc is created
    add(UserAutoLoginRequested());
  }

  String get _baseUrl {
    if (kDebugMode) {
      return dotenv.env['SERVER_URL_DEBUG'] ?? '127.0.0.1';
    } else {
      return dotenv.env['SERVER_URL_PROD'] ?? 'kog.gr';
    }
  }

  String get _serverUrl => 'http://$_baseUrl:7000';

  // Handle automatic login using stored credentials
  Future<void> _onAutoLoginRequested(
      UserAutoLoginRequested event, Emitter<UserState> emit) async {
    // Check if we have stored credentials
    final currentState = state;

    if (currentState is UserCredentials) {
      // We have credentials, let's log in
      add(UserLoginRequested(
          username: currentState.username, password: currentState.password));
    }
    // If we're already authenticated, refresh the token anyway
    else if (currentState is UserAuthenticated) {
      // Attempt to get credentials from storage directly
      final json = await HydratedBloc.storage.read('credentials');
      if (json != null) {
        final credentials = jsonDecode(json);
        if (credentials['username'] != null &&
            credentials['password'] != null) {
          add(UserLoginRequested(
              username: credentials['username'],
              password: credentials['password']));
        }
      }
    }
  }

  Future<void> _onRegisterRequested(
      UserRegisterRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());
    final url = Uri.parse('$_serverUrl/auth/');
    final body = jsonEncode({
      'username': event.username,
      'email': event.email,
      'first_name': event.firstName,
      'last_name': event.lastName,
      'password': event.password,
    });
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'accept': 'application/json'
        },
        body: body,
      );
      if (response.statusCode == 201) {
        emit(UserRegisterSuccess());
      } else {
        emit(UserFailure(message: 'Registration failed: \n${response.body}'));
      }
    } catch (e) {
      emit(UserFailure(message: e.toString()));
    }
  }

  Future<void> _onLoginRequested(
      UserLoginRequested event, Emitter<UserState> emit) async {
    emit(UserLoading());

    // Store credentials for future auto-login (separate from state)
    final credentials = jsonEncode({
      'username': event.username,
      'password': event.password,
    });
    await HydratedBloc.storage.write('credentials', credentials);

    final url = Uri.parse('$_serverUrl/auth/token');
    final body = {
      'grant_type': 'password',
      'username': event.username,
      'password': event.password,
      'scope': '',
      'client_id': 'string',
      'client_secret': 'string',
    };
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'accept': 'application/json'
        },
        body: body,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        final tokenType = data['token_type'];
        // Fetch user data
        final userResponse = await http.get(
          Uri.parse('$_serverUrl/user/'),
          headers: {
            'accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );
        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);

          // Store user credentials state (will be hydrated)
          emit(UserCredentials(
            username: event.username,
            password: event.password,
          ));

          // Then emit authenticated state with user data
          emit(UserAuthenticated(
            accessToken: accessToken,
            tokenType: tokenType,
            id: userData['id'],
            firstName: userData['first_name'],
            lastName: userData['last_name'],
            email: userData['email'],
            username: userData['username'],
            role: userData['role'],
            isActive: userData['is_active'],
          ));
        } else {
          emit(UserFailure(
              message: 'Failed to fetch user data: ${userResponse.body}'));
        }
      } else {
        emit(UserFailure(message: 'Login failed: \n${response.body}'));
      }
    } catch (e) {
      emit(UserFailure(message: e.toString()));
    }
  }

  void _onLogoutRequested(UserLogoutRequested event, Emitter<UserState> emit) {
    emit(UserInitial());
    // Delete both the UserBloc state and the credentials
    HydratedBloc.storage.delete('UserBloc');
    HydratedBloc.storage.delete('credentials');
  }

  @override
  UserState? fromJson(Map<String, dynamic> json) {
    try {
      if (json['accessToken'] != null) {
        return UserAuthenticated(
          accessToken: json['accessToken'],
          tokenType: json['tokenType'],
          id: json['id'],
          firstName: json['firstName'],
          lastName: json['lastName'],
          email: json['email'],
          username: json['username'],
          role: json['role'],
          isActive: json['isActive'],
        );
      }
      return UserInitial();
    } catch (_) {
      return UserInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(UserState state) {
    if (state is UserAuthenticated) {
      return {
        'accessToken': state.accessToken,
        'tokenType': state.tokenType,
        'id': state.id,
        'firstName': state.firstName,
        'lastName': state.lastName,
        'email': state.email,
        'username': state.username,
        'role': state.role,
        'isActive': state.isActive,
      };
    }
    return null;
  }
}
