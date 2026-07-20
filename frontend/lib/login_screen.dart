import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/api_service.dart'; // ➔ Importamos tu API Service
import 'productos_screen.dart';     // ➔ Importamos la futura pantalla de productos

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para capturar el texto de los inputs
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _errorMessage = "";
  bool _isLoading = false;

  void _iniciarSesion() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      // 1. Intento de autenticación nativa en Firebase
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Extracción del Token JWT firmado por Google
      String? jwtToken = await userCredential.user?.getIdToken();

      if (jwtToken != null) {
        print("¡Login Exitoso! Token JWT guardado en ApiService.");

        // 3. PASAMOS EL JWT AL API SERVICE (Cumple con el requisito del examen)
        ApiService.setToken(jwtToken);

        // 4. Mensaje de éxito e inmediatamente brincamos al módulo de productos
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Autenticación exitosa con Firebase y JWT registrado!')),
        );

        // Borra la pantalla de login del historial para que no se regrese al dar "atrás"
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ProductosScreen()),
          );
        }
      }

    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          _errorMessage = "El correo electrónico no es válido o no está registrado.";
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = "Contraseña o credenciales incorrectas.";
        } else {
          _errorMessage = e.message ?? "Error al autenticar.";
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Ocurrió un error inesperado: $e";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión - Inventario')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Correo Electrónico', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _iniciarSesion,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ),
    );
  }
}