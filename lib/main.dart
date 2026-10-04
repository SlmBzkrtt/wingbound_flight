import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/services/game_services.dart';
import 'game/wingbound_game.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ekran yönünü dikey (Portrait) olarak sabitle
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Tam ekran / Edge-to-Edge sistem barı yapılandırması
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Yerel depolama ve ses servislerini başlat
  await GameStorageService.instance.init();
  await GameAudioService.instance.init();

  runApp(const WingBoundApp());
}

class WingBoundApp extends StatelessWidget {
  const WingBoundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WingBound: Multi Realms',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF100C22),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00F3FF),
          brightness: Brightness.dark,
        ),
      ),
      home: const WingBoundGame(),
    );
  }
}
