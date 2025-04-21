import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:metris/blocs/user_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  List<dynamic> _users = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectWebSocket());
  }

  void _connectWebSocket() {
    final userState = context.read<UserBloc>().state;
    if (userState is UserAuthenticated) {
      _token = userState.accessToken;
      final url = 'ws://localhost:8000/ws/lobby?token=$_token';
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _subscription = _channel!.stream.listen((event) {
        final data = jsonDecode(event);
        setState(() {
          _users = data['users'] ?? [];
        });
      }, onError: (e) {
        // Optionally handle error
      }, onDone: () {
        // Optionally handle done
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    String? loggedInText;
    if (userState is UserAuthenticated) {
      loggedInText = 'logged in as: ${userState.username} (${userState.id})';
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Lobby Screen',
                style: TextStyle(
                  color: Colors.green,
                  fontFamily: 'PressStart2P',
                  fontSize: 24,
                ),
              ),
            ),
            if (loggedInText != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(70),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          loggedInText,
                          style: const TextStyle(
                            color: Colors.green,
                            fontFamily: 'PressStart2P',
                            fontSize: 5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: _users.isEmpty
                  ? const Center(
                      child: Text(
                        'No users in lobby',
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'PressStart2P',
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(70),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green, width: 2),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.green,
                                size: 40,
                              ),
                              title: Text(
                                maxLines: 1,
                                user['username'] ?? '',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'PressStart2P',
                                  fontSize: 10,
                                ),
                              ),
                              subtitle: Text(
                                'ID: ${user['id']}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontFamily: 'PressStart2P',
                                  fontSize: 10,
                                ),
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  side: const BorderSide(
                                      color: Colors.green, width: 2),
                                  foregroundColor: Colors.green,
                                  textStyle: const TextStyle(
                                      fontFamily: 'PressStart2P'),
                                ),
                                child: const Text('Join'),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RetroButton(
                    text: 'HOME',
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/');
                    },
                  ),
                  const SizedBox(width: 30),
                  _RetroButton(
                    text: 'LOGOUT',
                    onPressed: () {
                      context.read<UserBloc>().add(UserLogoutRequested());
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetroButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const _RetroButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: Colors.green, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withAlpha(50),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 18,
            color: Colors.green,
            fontWeight: FontWeight.normal,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
