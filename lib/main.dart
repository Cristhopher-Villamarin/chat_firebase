import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con opciones específicas para Web
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AlzaSyCu_8XzBNPLw_gj09ejgTAZtXVOisOSly8", // Clave de API web de tu Firebase
      authDomain: "chat-tiempo-real-57fe3.firebaseapp.com",
      projectId: "chat-tiempo-real-57fe3",
      storageBucket: "chat-tiempo-real-57fe3.appspot.com",
      messagingSenderId: "999824839007",
      appId: "1:999824839007:web:xxxxxxx", // Reemplaza con el appId que aparece en tu configuración.
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Autenticación con Google',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(), // Pantalla de inicio con botón de autenticación
    );
  }
}
