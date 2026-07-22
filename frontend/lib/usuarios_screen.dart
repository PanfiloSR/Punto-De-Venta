import 'package:flutter/material.dart';
import 'services/api_service.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _usuarios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  // 1. CONSULTA (Read de Usuarios)
  void _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      // MOCK/SIMULACIÓN temporal si solo manejas el usuario actual de Firebase:
      setState(() {
        _usuarios = [
          {
            "id": 1,
            "name": "Enrique Quique",
            "email": "test@example.com",
            "role_id": 1, // 1 = Admin, 2 = Empleado
          },
        ];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. MODIFICACIÓN / REGISTRO (Mapeado a tu BD: image_fa9d0.png)
  void _mostrarFormularioUsuario({Map<String, dynamic>? usuario}) {
    final bool esEditar = usuario != null;

    final nameController = TextEditingController(
      text: esEditar ? usuario['name'] : '',
    );
    final emailController = TextEditingController(
      text: esEditar ? usuario['email'] : '',
    );
    final passwordController =
        TextEditingController(); // La contraseña se digita limpia
    final roleIdController = TextEditingController(
      text: esEditar ? usuario['role_id'].toString() : '1',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esEditar ? "Modificar Usuario" : "Registrar Usuario"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo (name)',
              ),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo (email)'),
              enabled: !esEditar,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña (password)',
              ),
              obscureText: true,
            ),
            TextField(
              controller: roleIdController,
              decoration: const InputDecoration(
                labelText: 'ID de Rol (role_id)',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              // Estructura JSON exacta de tu tabla 'Users'
              final Map<String, dynamic> datosUsuario = {
                "name": nameController.text.trim(),
                "email": emailController.text.trim(),
                "password": passwordController.text.isNotEmpty
                    ? passwordController.text
                    : null,
                "role_id": int.tryParse(roleIdController.text) ?? 1,
              };

              print("Datos listos para enviar al backend: $datosUsuario");
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Usuarios (JWT)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _usuarios.length,
              itemBuilder: (context, index) {
                final user = _usuarios[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      user['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "${user['email']}\nRol ID: ${user['role_id']}",
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _mostrarFormularioUsuario(usuario: user),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
