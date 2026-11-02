import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'state/language_store.dart';
import 'state/locale_provider.dart';
import 'state/run_persistence.dart';
import 'ui/lifecycle_auto_save.dart';
import 'ui/main_menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  final prefs = await SharedPreferences.getInstance();
  final persistence = RunPersistence(prefs);
  runApp(
    ProviderScope(
      overrides: [
        runPersistenceProvider.overrideWithValue(persistence),
        savedRunProvider.overrideWithValue(persistence.load()),
        languageStoreProvider.overrideWithValue(LanguageStore(prefs)),
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
      // Auto-save covers every screen, including the menu.
      builder: (context, child) => LifecycleAutoSave(child: child!),
      home: const MainMenuScreen(),
    );
  }
}
