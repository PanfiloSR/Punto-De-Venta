import 'package:flutter/material.dart';

import 'services/api_service.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() {
    return _ProductosScreenState();
  }
}

class _ProductosScreenState extends State<ProductosScreen> {
  static const Color headingColor = Color(0xFF002254);
  static const Color buttonColor = Color(0xFF00C0FF);
  static const Color containerColor = Color(0xFFE9F1FA);
  static const Color iconColor = Color(0xFFA5A5A5);

  List<Map<String, dynamic>> _productos = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productos = await ApiService.getProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _productos = productos;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _mostrarFormulario({
    Map<String, dynamic>? producto,
  }) async {
    final bool esEditar = producto != null;

    final GlobalKey<FormState> formKey =
    GlobalKey<FormState>();

    final TextEditingController nameController =
    TextEditingController(
      text: producto?['name']?.toString() ?? '',
    );

    final TextEditingController brandController =
    TextEditingController(
      text: producto?['brand']?.toString() ?? '',
    );

    final TextEditingController descriptionController =
    TextEditingController(
      text: producto?['description']?.toString() ?? '',
    );

    final TextEditingController salePriceController =
    TextEditingController(
      text: producto?['sale_price']?.toString() ?? '',
    );

    final TextEditingController purchasePriceController =
    TextEditingController(
      text: producto?['purchase_price']?.toString() ?? '',
    );

    final TextEditingController stockController =
    TextEditingController(
      text: producto?['stock']?.toString() ?? '',
    );

    final TextEditingController imageUrlController =
    TextEditingController(
      text: producto?['image_url']?.toString() ?? '',
    );

    final bool? guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        bool guardando = false;

        return StatefulBuilder(
          builder: (
              BuildContext context,
              void Function(void Function()) setDialogState,
              ) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                esEditar
                    ? 'Editar producto'
                    : 'Agregar producto',
                style: const TextStyle(
                  color: headingColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SizedBox(
                width: 430,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildField(
                          controller: nameController,
                          label: 'Nombre',
                          icon: Icons.inventory_2_outlined,
                          validator: (String? value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Ingresa el nombre.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: brandController,
                          label: 'Marca',
                          icon: Icons.sell_outlined,
                          validator: (String? value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Ingresa la marca.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller:
                          descriptionController,
                          label: 'Descripción',
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: purchasePriceController,
                          label: 'Precio de compra',
                          icon: Icons.shopping_cart_outlined,
                          keyboardType:
                          const TextInputType
                              .numberWithOptions(
                            decimal: true,
                          ),
                          validator: _validatePrice,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: salePriceController,
                          label: 'Precio de venta',
                          icon:
                          Icons.attach_money_rounded,
                          keyboardType:
                          const TextInputType
                              .numberWithOptions(
                            decimal: true,
                          ),
                          validator: _validatePrice,
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: stockController,
                          label: 'Existencias',
                          icon: Icons.numbers_outlined,
                          keyboardType:
                          TextInputType.number,
                          validator: (String? value) {
                            final int? stock =
                            int.tryParse(
                              value?.trim() ?? '',
                            );

                            if (stock == null || stock < 0) {
                              return 'Ingresa una cantidad válida.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildField(
                          controller: imageUrlController,
                          label: 'URL de imagen',
                          icon: Icons.image_outlined,
                          keyboardType:
                          TextInputType.url,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                      false,
                    );
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: headingColor,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                    if (!formKey.currentState!
                        .validate()) {
                      return;
                    }

                    setDialogState(() {
                      guardando = true;
                    });

                    final Map<String, dynamic>
                    datosProducto = {
                      'name':
                      nameController.text.trim(),
                      'brand':
                      brandController.text.trim(),
                      'description':
                      descriptionController.text
                          .trim(),
                      'sale_price':
                      double.parse(
                        salePriceController.text
                            .trim(),
                      ),
                      'purchase_price':
                      double.parse(
                        purchasePriceController.text
                            .trim(),
                      ),
                      'stock': int.parse(
                        stockController.text.trim(),
                      ),
                      'image_url':
                      imageUrlController.text
                          .trim(),
                      'category_id':
                      producto?['category_id'] ??
                          1,
                    };

                    final dynamic providerId =
                    producto?['provider_id'];

                    if (providerId != null &&
                        providerId
                            .toString()
                            .isNotEmpty) {
                      datosProducto['provider_id'] =
                      providerId is Map
                          ? providerId['_id']
                          : providerId;
                    }

                    try {
                      if (esEditar) {
                        await ApiService.updateProduct(
                          producto['_id'].toString(),
                          datosProducto,
                        );
                      } else {
                        await ApiService.createProduct(
                          datosProducto,
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
                        guardando = false;
                      });

                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(
                          SnackBar(
                            content: Text(
                              error
                                  .toString()
                                  .replaceFirst(
                                'Exception: ',
                                '',
                              ),
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
                  child: guardando
                      ? const SizedBox(
                    width: 21,
                    height: 21,
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
    brandController.dispose();
    descriptionController.dispose();
    salePriceController.dispose();
    purchasePriceController.dispose();
    stockController.dispose();
    imageUrlController.dispose();

    if (guardado == true) {
      await _cargarProductos();

      if (mounted) {
        _mostrarMensaje(
          esEditar
              ? 'Producto actualizado correctamente.'
              : 'Producto creado correctamente.',
        );
      }
    }
  }

  String? _validatePrice(String? value) {
    final double? price = double.tryParse(
      value?.trim() ?? '',
    );

    if (price == null || price < 0) {
      return 'Ingresa un precio válido.';
    }

    return null;
  }

  Widget _buildField({
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
          color: iconColor,
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
            width: 1.7,
          ),
        ),
      ),
    );
  }

  Future<void> _eliminarProducto(
      Map<String, dynamic> producto,
      ) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Eliminar producto',
            style: TextStyle(
              color: headingColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '¿Deseas eliminar el producto '
                '"${producto['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) {
      return;
    }

    try {
      await ApiService.deleteProduct(
        producto['_id'].toString(),
      );

      await _cargarProductos();

      if (mounted) {
        _mostrarMensaje(
          'Producto eliminado correctamente.',
        );
      }
    } catch (error) {
      if (mounted) {
        _mostrarMensaje(
          error
              .toString()
              .replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    }
  }

  void _mostrarMensaje(
      String message, {
        bool error = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
        error ? Colors.redAccent : headingColor,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Inventario',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _cargarProductos,
            icon: const Icon(
              Icons.refresh_rounded,
              color: headingColor,
            ),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () {
          _mostrarFormulario();
        },
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Agregar',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: buttonColor,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                color: iconColor,
                size: 58,
              ),
              const SizedBox(height: 15),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: headingColor,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _cargarProductos,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Reintentar',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_productos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: iconColor,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'No hay productos registrados.',
                style: TextStyle(
                  color: headingColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: buttonColor,
      onRefresh: _cargarProductos,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          100,
        ),
        itemCount: _productos.length,
        separatorBuilder: (_, _) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          final Map<String, dynamic> producto =
          _productos[index];

          return _buildProductCard(producto);
        },
      ),
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> producto,
      ) {
    final String imageUrl =
        producto['image_url']?.toString() ?? '';

    final double salePrice = double.tryParse(
      producto['sale_price']?.toString() ?? '',
    ) ??
        0;

    final int stock = int.tryParse(
      producto['stock']?.toString() ?? '',
    ) ??
        0;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: imageUrl.startsWith('http')
                ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                  ) {
                return const Icon(
                  Icons.inventory_2_outlined,
                  color: buttonColor,
                );
              },
            )
                : const Icon(
              Icons.inventory_2_outlined,
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
                  producto['name']?.toString() ?? '',
                  style: const TextStyle(
                    color: headingColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  producto['brand']?.toString() ?? '',
                  style: const TextStyle(
                    color: Color(0xFF718197),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Text(
                      '\$${salePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: headingColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Stock: $stock',
                      style: TextStyle(
                        color: stock <= 5
                            ? Colors.redAccent
                            : const Color(0xFF718197),
                        fontWeight: stock <= 5
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: Colors.white,
            onSelected: (String value) {
              if (value == 'edit') {
                _mostrarFormulario(
                  producto: producto,
                );
              }

              if (value == 'delete') {
                _eliminarProducto(producto);
              }
            },
            itemBuilder: (BuildContext context) {
              return const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: headingColor,
                      ),
                      SizedBox(width: 10),
                      Text('Editar'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      SizedBox(width: 10),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}