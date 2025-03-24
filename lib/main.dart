import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'blocs/score_bloc.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await HydratedStorage.build(
    storageDirectory: await getTemporaryDirectory(),
  );

  HydratedBloc.storage = storage;
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScoreBloc(),
      child: MaterialApp(
        title: 'Metris',
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
              overlayColor:
                  WidgetStateProperty.all(Colors.green.withAlpha(20)),
            ),
          ),
        ),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
