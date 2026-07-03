import 'package:flutter/material.dart';
import 'package:coritario_app/screens/main_navigation.dart';

void main() {
  runApp(const CoritarioApp());
}

class CoritarioApp extends StatelessWidget {
  const CoritarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coritario Digital',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainNavigation(), // Apuntamos a la nueva navegación principal
      debugShowCheckedModeBanner: false,
    );
  }
}
