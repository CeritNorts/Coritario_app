import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:coritario_app/firebase_options.dart';
import 'package:coritario_app/screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Condicionar para forzar las opciones web en Linux escritorio
  final FirebaseOptions options = (!kIsWeb && defaultTargetPlatform == TargetPlatform.linux)
      ? DefaultFirebaseOptions.web
      : DefaultFirebaseOptions.currentPlatform;

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: options,
  );

  // Configurar persistencia sin conexión ilimitada en Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

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
