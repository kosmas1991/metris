import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tetris/blocs/user_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../screens/online_tetris_screen.dart';
import '../config/server_config.dart';
import '../services/user_service.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  WebSocketChannel? _channel;
  WebSocketChannel? _roomChannel;
  StreamSubscription? _subscription;
  StreamSubscription? _roomSubscription;
  List<dynamic> _users = [];
  String? _token;
  String? _userId;
  String? _username;

  // Win rate data
  final Map<int, double> _userWinRates = {};
  final Set<int> _loadingWinRates = {};

  // Room data
  String? _roomOwnerUsername;
  List<dynamic> _roomUsers = [];
  bool _isReady = false;
  bool _isInOwnRoom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectWebSocket());
  }

  void _connectWebSocket() {
    final userState = context.read<UserBloc>().state;
    if (userState is UserAuthenticated) {
      _token = userState.accessToken;
      _userId = userState.id.toString();
      _username = userState.username;

      // Connect to lobby websocket
      final url = '${ServerConfig.wsUrl}/ws/lobby?token=$_token';
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _subscription = _channel!.stream.listen((event) {
        final data = jsonDecode(event);
        setState(() {
          _users = data['users'] ?? [];
        });

        // Fetch win rates for all users
        _fetchWinRatesForUsers();
      }, onError: (e) {
        // Optionally handle error
      }, onDone: () {
        // Optionally handle done
      });

      // Connect to own room automatically
      _joinRoom(_userId!);
    }
  }

  // Fetch win rates for all users
  void _fetchWinRatesForUsers() {
    final userState = context.read<UserBloc>().state;
    if (userState is UserAuthenticated) {
      for (var user in _users) {
        final userId = user['id'] as int;

        // Only load win rate if we don't have it and aren't already loading it
        if (!_userWinRates.containsKey(userId) &&
            !_loadingWinRates.contains(userId)) {
          _loadingWinRates.add(userId);

          UserService.getUserWinRate(userId, userState.accessToken)
              .then((winRateData) {
            if (winRateData != null && mounted) {
              setState(() {
                _userWinRates[userId] = winRateData['win_rate'];
                _loadingWinRates.remove(userId);
              });
            }
          });
        }
      }
    }
  }

  void _joinRoom(String roomId, {String? ownerUsername}) {
    // Close previous room connection if exists
    _roomSubscription?.cancel();
    _roomChannel?.sink.close();

    final url = '${ServerConfig.wsUrl}/ws/room/$roomId?token=$_token';
    _roomChannel = WebSocketChannel.connect(Uri.parse(url));

    setState(() {
      _roomOwnerUsername = ownerUsername ?? _username;
      _isInOwnRoom = ownerUsername == null;
      _isReady = false;
      _roomUsers = [];
    });

    _roomSubscription = _roomChannel!.stream.listen((event) {
      final data = jsonDecode(event);

      if (data['event'] == 'user joined' ||
          data['event'] == 'user ready' ||
          data['event'] == 'user not ready' ||
          data['event'] == 'room full' ||
          data['event'] == 'user disconnected') {
        setState(() {
          _roomUsers = data['users'] ?? [];
        });
      } else if (data['event'] == 'game_starting') {
        _handleGameStarting(data);
      } else if (data['event'] == 'game started') {
        setState(() {
          _roomUsers = data['users'] ?? [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Game started!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }, onError: (e) {
      // Handle error
    }, onDone: () {
      // Handle done
    });
  }

  void _handleGameStarting(Map<String, dynamic> data) {
    // Extract the game UID from the message
    final gameUid = data['gameUid'];
    // final message = data['message'];

    // Show a snackbar message
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(
    //     content: Text(message),
    //     backgroundColor: Colors.green,
    //     duration: const Duration(seconds: 3),
    //   ),
    // );

    // Close the room connection as we'll be moving to the game screen
    _roomSubscription?.cancel();
    _roomChannel?.sink.close();

    // Navigate to the online tetris screen with the game UID
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        // Add mounted check before using context
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OnlineTetrisScreen(gameUid: gameUid),
          ),
        );
      }
    });
  }

  void _toggleReady() {
    if (_roomChannel != null) {
      _roomChannel!.sink.add(_isReady ? 'not ready' : 'ready');
      setState(() {
        _isReady = !_isReady;
      });
    }
  }

  void _leaveRoom() {
    _roomSubscription?.cancel();
    _roomChannel?.sink.close();

    setState(() {
      _roomOwnerUsername = null;
      _roomUsers = [];
      _isReady = false;
      _isInOwnRoom = false;
    });

    // Rejoin own room
    _joinRoom(_userId!);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _roomSubscription?.cancel();
    _roomChannel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    String? loggedInText;
    if (userState is UserAuthenticated) {
      loggedInText = 'logged in as: ${userState.username} (${userState.id})';
    }
    return Center(
      child: SizedBox(
        width: 450,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Lobby',
                        style: TextStyle(
                          color: Colors.green,
                          fontFamily: 'PressStart2P',
                          fontSize: 24,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.people,
                        color: Colors.green,
                      )
                    ],
                  ),
                ),
                if (loggedInText != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(70),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person,
                                color: Colors.green, size: 18),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Online Users Section
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border:
                                      Border.all(color: Colors.green, width: 2),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Online Users',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontFamily: 'PressStart2P',
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                        color: Colors.green, width: 2),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
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
                                          padding: const EdgeInsets.all(8.0),
                                          itemBuilder: (context, index) {
                                            final user = _users[index];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withAlpha(70),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                      color: Colors.green,
                                                      width: 2),
                                                ),
                                                child: ListTile(
                                                  leading: const Icon(
                                                    Icons.person,
                                                    color: Colors.green,
                                                    size: 40,
                                                  ),
                                                  title: Text(
                                                    user['username'] ?? '',
                                                    maxLines: 1,
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontFamily:
                                                          'PressStart2P',
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                  subtitle: Row(
                                                    children: [
                                                      Text(
                                                        'ID: ${user['id']}',
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontFamily:
                                                              'PressStart2P',
                                                          fontSize: 8,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        _userWinRates
                                                                .containsKey(
                                                                    user['id'])
                                                            ? 'WR: ${_userWinRates[user['id']]!.toStringAsFixed(1)}%'
                                                            : _loadingWinRates
                                                                    .contains(
                                                                        user[
                                                                            'id'])
                                                                ? 'WR: loading...'
                                                                : 'WR: --',
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontFamily:
                                                              'PressStart2P',
                                                          fontSize: 8,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: ElevatedButton(
                                                    onPressed: () {
                                                      _joinRoom(
                                                        user['id'].toString(),
                                                        ownerUsername:
                                                            user['username'],
                                                      );
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.black,
                                                      side: const BorderSide(
                                                          color: Colors.green,
                                                          width: 2),
                                                      foregroundColor:
                                                          Colors.green,
                                                      textStyle: const TextStyle(
                                                          fontFamily:
                                                              'PressStart2P',
                                                          fontSize: 8),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 10,
                                                          vertical: 6),
                                                      minimumSize:
                                                          const Size(60, 30),
                                                    ),
                                                    child: const Text('Join'),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Room Data Section
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  border:
                                      Border.all(color: Colors.green, width: 2),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _roomOwnerUsername != null
                                        ? '${_isInOwnRoom ? 'My' : '$_roomOwnerUsername\'s'} Room'
                                        : 'Room Data',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontFamily: 'PressStart2P',
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    border: Border.all(
                                        color: Colors.green, width: 2),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: _roomUsers.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No active room',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontFamily: 'PressStart2P',
                                              fontSize: 12,
                                            ),
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: ListView.builder(
                                                  itemCount: _roomUsers.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final user =
                                                        _roomUsers[index];
                                                    final isReady =
                                                        user['status'] ==
                                                            'ready';
                                                    return ListTile(
                                                      leading: const Icon(
                                                        Icons.person,
                                                        color: Colors.green,
                                                        size: 30,
                                                      ),
                                                      title: Text(
                                                        user['username'] ?? '',
                                                        maxLines: 1,
                                                        style: const TextStyle(
                                                          color: Colors.green,
                                                          fontFamily:
                                                              'PressStart2P',
                                                          fontSize: 10,
                                                        ),
                                                      ),
                                                      trailing: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: isReady
                                                              ? Colors.green
                                                                  .withAlpha(30)
                                                              : Colors.red
                                                                  .withAlpha(
                                                                      30),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          border: Border.all(
                                                            color: isReady
                                                                ? Colors.green
                                                                : Colors.red,
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          isReady
                                                              ? 'READY'
                                                              : 'NOT READY',
                                                          style: TextStyle(
                                                            color: isReady
                                                                ? Colors.green
                                                                : Colors.red,
                                                            fontFamily:
                                                                'PressStart2P',
                                                            fontSize: 8,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: _toggleReady,
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.black,
                                                      side: BorderSide(
                                                        color: _isReady
                                                            ? Colors.red
                                                            : Colors.green,
                                                        width: 2,
                                                      ),
                                                      foregroundColor: _isReady
                                                          ? Colors.red
                                                          : Colors.green,
                                                      textStyle:
                                                          const TextStyle(
                                                        fontFamily:
                                                            'PressStart2P',
                                                        fontSize: 6,
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      minimumSize:
                                                          const Size(55, 25),
                                                    ),
                                                    child: Text(_isReady
                                                        ? 'NOT READY'
                                                        : 'READY'),
                                                  ),
                                                  if (!_isInOwnRoom) ...[
                                                    const SizedBox(width: 10),
                                                    ElevatedButton(
                                                      onPressed: _leaveRoom,
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.black,
                                                        side: const BorderSide(
                                                          color: Colors.red,
                                                          width: 2,
                                                        ),
                                                        foregroundColor:
                                                            Colors.red,
                                                        textStyle:
                                                            const TextStyle(
                                                          fontFamily:
                                                              'PressStart2P',
                                                          fontSize: 6,
                                                        ),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        minimumSize:
                                                            const Size(55, 25),
                                                      ),
                                                      child:
                                                          const Text('LEAVE'),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
