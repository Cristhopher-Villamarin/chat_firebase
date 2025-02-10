import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con las opciones específicas para Web
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAkszrljWkqHHaXKR6cNWt6umOH5ir4c6I", // Clave de API web
      authDomain: "mensajeria-94b04.firebaseapp.com", // authDomain del proyecto
      projectId: "mensajeria-94b04", // ID del proyecto
      storageBucket: "mensajeria-94b04.appspot.com", // Storage bucket
      messagingSenderId: "274663628481", // Sender ID del proyecto
      appId: "1:274663628481:android:6f94704aa3e361f6f73e40", // App ID del proyecto
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: LoginScreen(),
    );
  }
}