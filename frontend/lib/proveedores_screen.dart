import 'package:flutter/material.dart';

import 'services/api_service.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() {
    return _ProveedoresScreenState();
  }
}

class _ProveedoresScreenState
    extends State<ProveedoresScreen> {
  static const Color headingColor = Color(0xFF002254);
  static const Color buttonColor = Color(0xFF00C0FF);
  static const Color containerColor = Color(0xFFE9F1FA);

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _providers = [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final providers =
      await ApiService.getProviders();

      if (!mounted) {
        return;
      }

      setState(() {
        _providers = providers;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _showProviderForm({
    Map<String, dynamic>? provider,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: provider?['name']?.toString() ?? '',
    );

    final phoneController = TextEditingController(
      text: provider?['phone']?.toString() ?? '',
    );

    final emailController = TextEditingController(
      text: provider?['email']?.toString() ?? '',
    );

    final notesController = TextEditingController(
      text: provider?['notes']?.toString() ?? '',
    );

    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(24),
              ),
              title: Text(
                provider == null
                    ? 'Nuevo proveedor'
                    : 'Editar proveedor',
                style: const TextStyle(
                  color: headingColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _field(
                        controller: nameController,
                        label: 'Nombre',
                        icon: Icons.business_outlined,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Ingresa el nombre.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: phoneController,
                        label: 'Número telefónico',
                        icon: Icons.phone_outlined,
                        keyboardType:
                        TextInputType.phone,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'Ingresa el teléfono.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: emailController,
                        label: 'Correo electrónico',
                        icon: Icons.email_outlined,
                        keyboardType:
                        TextInputType.emailAddress,
                        validator: (value) {
                          final email =
                              value?.trim() ?? '';

                          if (email.isEmpty ||
                              !email.contains('@')) {
                            return 'Ingresa un correo válido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _field(
                        controller: notesController,
                        label: 'Notas',
                        icon: Icons.notes_outlined,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    setDialogState(() {
                      saving = true;
                    });

                    final data = {
                      'name':
                      nameController.text.trim(),
                      'phone':
                      phoneController.text.trim(),
                      'email':
                      emailController.text.trim(),
                      'notes':
                      notesController.text.trim(),
                    };

                    try {
                      if (provider == null) {
                        await ApiService
                            .createProvider(data);
                      } else {
                        await ApiService
                            .updateProvider(
                          provider['_id'].toString(),
                          data,
                        );
                      }

                      if (dialogContext.mounted) {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      }
                    } catch (error) {
                      setDialogState(() {
                        saving = false;
                      });

                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString(),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();

    if (saved == true) {
      await _loadProviders();
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      cursorColor: buttonColor,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFFA5A5A5),
        ),
        filled: true,
        fillColor: containerColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: buttonColor,
            width: 1.6,
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProvider(
      Map<String, dynamic> provider,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar proveedor',
          ),
          content: Text(
            '¿Deseas eliminar a ${provider['name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await ApiService.deleteProvider(
      provider['_id'].toString(),
    );

    await _loadProviders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Proveedores',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () {
          _showProviderForm();
        },
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: buttonColor,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!),
      );
    }

    if (_providers.isEmpty) {
      return const Center(
        child: Text(
          'No hay proveedores registrados.',
        ),
      );
    }

    return RefreshIndicator(
      color: buttonColor,
      onRefresh: _loadProviders,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          20,
          14,
          20,
          100,
        ),
        itemCount: _providers.length,
        separatorBuilder: (_, _) =>
        const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final provider = _providers[index];

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: containerColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: buttonColor,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider['name']
                            ?.toString() ??
                            '',
                        style: const TextStyle(
                          color: headingColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider['phone']
                            ?.toString() ??
                            '',
                        style: const TextStyle(
                          color: Color(0xFF687A90),
                        ),
                      ),
                      Text(
                        provider['email']
                            ?.toString() ??
                            '',
                        style: const TextStyle(
                          color: Color(0xFF687A90),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showProviderForm(
                        provider: provider,
                      );
                    }

                    if (value == 'delete') {
                      _deleteProvider(provider);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Editar'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}