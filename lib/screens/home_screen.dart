import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth_bloc.dart';
import 'tetris_screen.dart';
import 'lobby_screen.dart';
import 'profile_screen.dart';
import '../services/debug_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (state is Authenticated) {
          return _buildAuthenticatedScreen(context, state);
        } else {
          return _buildAuthenticationScreen(context);
        }
      },
    );
  }

  Widget _buildAuthenticatedScreen(BuildContext context, Authenticated state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, ${state.player.displayName}!',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TetrisScreen()),
                );
              },
              child: const Text('Single Player'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                textStyle: const TextStyle(fontSize: 20),
                backgroundColor: Colors.green,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LobbyScreen()),
                );
              },
              child: const Text('Multiplayer'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(SignOut());
              },
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Metris',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                context.read<AuthBloc>().add(SignInAnonymously());
              },
              child: const Text('Play as Guest'),
            ),
            // Add debug button in development
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                DebugService.printFirebaseStatus();
                DebugService.checkAnonymousAuthEnabled();
              },
              child: const Text('Debug Firebase'),
            ),
          ],
        ),
      ),
    );
  }
}
