import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/multiplayer_bloc.dart';
import '../models/game_room.dart';
import 'multiplayer_game_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MultiplayerBloc>().add(LoadLobby());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Lobby'),
      ),
      body: BlocConsumer<MultiplayerBloc, MultiplayerState>(
        listener: (context, state) {
          if (state is MultiplayerError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is InRoom) {
            // Navigate to the game screen when in a room
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiplayerGameScreen(
                    room: state.room,
                    isHost: state.isHost,
                    initialTetrominoType: state.nextTetrominoType,
                  ),
                ),
              );
            });
          }
        },
        builder: (context, state) {
          if (state is MultiplayerLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is InLobby) {
            return _buildLobbyContent(context, state.availableRooms);
          } else {
            return const Center(
              child: Text('Something went wrong. Please try again.'),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<MultiplayerBloc>().add(CreateRoom());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLobbyContent(BuildContext context, List<GameRoom> rooms) {
    if (rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No active game rooms',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<MultiplayerBloc>().add(CreateRoom());
              },
              child: const Text('Create a Room'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Available Rooms (${rooms.length})',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Room #${room.id.substring(0, 8)}'),
                  subtitle:
                      Text('Created ${_timeAgo(room.createdAt.toDate())} ago'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      context.read<MultiplayerBloc>().add(JoinRoom(room.id));
                    },
                    child: const Text('Join'),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else {
      return '${difference.inHours} hours';
    }
  }
}
