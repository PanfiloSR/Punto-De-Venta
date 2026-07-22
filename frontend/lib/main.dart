import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/api_service.dart';
import 'login_screen.dart';

void main() async {
  // 1. Asegura que los canales de comunicación nativos estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa Firebase de forma asíncrona leyendo tu google-services.json
  await Firebase.initializeApp();

  // 3. Ya con Firebase encendido, arranca la interfaz
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: LoginScreen());
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final ApiService _apiService = ApiService();
  String _backendMessage = "Presiona el botón para probar la conexión";

  void _probarConexion() async {
    setState(() => _backendMessage = "Conectando...");
    final data = await _apiService.verificarTest();
    setState(() {
      if (data != null) {
        _backendMessage =
            "Respuesta de Node.js\n\nStatus: ${data['status']}\nMessage: ${data['message']}\nAuthor: ${data['author']}";
      } else {
        _backendMessage =
            "Error: No se pudo conectar al Backend. ¿Está encendido Node.js?";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Examen Parcial 2')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _backendMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _probarConexion,
                child: const Text('Verificar Backend'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
