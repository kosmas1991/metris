import 'imports/app_imports.dart';
import 'screens/online_tetris_screen.dart';
import 'services/audio_service.dart';

//adb reverse tcp:7000 tcp:7000

//!    L E T ' S     G O    :-)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize audio service
  final audioService = AudioService();
  await audioService.initialize();

  Bloc.observer = SimpleBlocObserver();
  final HydratedStorage storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory((await getTemporaryDirectory()).path),
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
        BlocProvider(
          create: (_) => UserBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'TETRIS',
        theme: appTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/lobby': (context) => const LobbyScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/online_tetris': (context) => const OnlineTetrisScreen(gameUid: ''),
        },
      ),
    );
  }
}
