import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state/run_persistence.dart';
import 'ui/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  final persistence = RunPersistence(await SharedPreferences.getInstance());
  runApp(
    ProviderScope(
      overrides: [
        runPersistenceProvider.overrideWithValue(persistence),
        savedRunProvider.overrideWithValue(persistence.load()),
      ],
      child: const BlastroApp(),
    ),
  );
}

class BlastroApp extends StatelessWidget {
  const BlastroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLASTRO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const GameScreen(),
    );
  }
}
