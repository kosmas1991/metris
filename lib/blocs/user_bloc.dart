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
  }

  String get _baseUrl {
    if (kDebugMode) {
      return dotenv.env['SERVER_URL_DEBUG'] ?? '127.0.0.1';
    } else {
      return dotenv.env['SERVER_URL_PROD'] ?? 'kog.gr';
    }
  }

  String get _serverUrl => 'http://$_baseUrl:8000';

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
    HydratedBloc.storage.delete('UserBloc'); // Remove persisted user data
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
