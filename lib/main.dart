import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:metris/services/auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;
import 'firebase_options.dart';
import 'blocs/score_bloc.dart';
import 'blocs/auth_bloc.dart';
import 'blocs/multiplayer_bloc.dart';
import 'screens/home_screen.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase with explicit options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
    debugPrint('Firebase app name: ${Firebase.app().name}');

    // Initialize HydratedBloc storage
    final storage = await HydratedStorage.build(
      storageDirectory: await getTemporaryDirectory(),
    );

    HydratedBloc.storage = storage;

    // Now run the app
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error during initialization: $e');
    // Show error UI if necessary
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize app: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ScoreBloc()),
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => MultiplayerBloc()),
      ],
      child: MaterialApp(
        title: 'Metris',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
