import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:metris/firebase_options.dart';

import 'package:path_provider/path_provider.dart';
import 'blocs/score_bloc.dart';
import 'blocs/rotation_bloc.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final HydratedStorage storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory // Correct storage for web
        : await getTemporaryDirectory(), // Correct storage for other platforms
  );

  HydratedBloc.storage = storage;

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set the system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black, // Change the status bar color
      systemNavigationBarColor: Colors.black, // Change the navigation bar color
      systemNavigationBarIconBrightness:
          Brightness.light, // Change icon brightness
    ));
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ScoreBloc(),
        ),
        BlocProvider(
          create: (_) => RotationBloc(),
        ),
      ],
      child: MaterialApp(
        
        title: 'TETRIS',
        theme: ThemeData(
          useMaterial3: false,
          scaffoldBackgroundColor: Colors.black,
          fontFamily: 'PressStart2P',
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              color: Colors.green,
              fontFamily: 'PressStart2P',
            ),
            bodyMedium: TextStyle(
              color: Colors.green,
              fontFamily: 'PressStart2P',
            ),
            titleLarge: TextStyle(
              color: Colors.green,
              fontFamily: 'PressStart2P',
              fontWeight: FontWeight.bold,
            ),
          ),
          colorScheme: ColorScheme.dark(
            primary: Colors.green,
            secondary: Colors.green.shade700,
            surface: Colors.black,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.green,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green, width: 3),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
              textStyle: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 14, // Reduced because pixel fonts are usually larger
                fontWeight: FontWeight
                    .normal, // Pixel fonts often look better without bold
                letterSpacing: 1,
              ),
              shadowColor: Colors.green.withAlpha(50),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.all(Colors.green),
              overlayColor: WidgetStateProperty.all(Colors.green.withAlpha(20)),
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
