import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Importa tu archivo de servicio de autenticación
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inicio de Sesión con Google'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Botón de Google Sign-In
            ElevatedButton.icon(
              icon: Icon(Icons.login),
              label: Text('Iniciar sesión con Google'),
              onPressed: () async {
                User? user = await _authService.signInWithGoogle();
                if (user != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Inicio de sesión exitoso: ${user.displayName}'),
                    ),
                  );
                  // Navega a la pantalla principal o realiza otras acciones
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El inicio de sesión fue cancelado.'),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            // Botón de Cerrar Sesión
            ElevatedButton.icon(
              icon: Icon(Icons.logout),
              label: Text('Cerrar sesión'),
              onPressed: () async {
                await _authService.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sesión cerrada exitosamente.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
