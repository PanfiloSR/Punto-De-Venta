import 'package:flutter/material.dart';

import 'services/api_service.dart';

const Color _headingColor = Color(0xFF002254);
const Color _buttonColor = Color(0xFF00C0FF);
const Color _containerColor = Color(0xFFE9F1FA);
const Color _iconColor = Color(0xFFA5A5A5);

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() {
    return _ProductosScreenState();
  }
}

class _ProductosScreenState extends State<ProductosScreen> {
  List<Map<String, dynamic>> _productos = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<Map<String, dynamic>> productos =
      await ApiService.getProducts();

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
        _errorMessage = _limpiarError(error);
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
    final bool? guardado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProductFormDialog(
          producto: producto,
        );
      },
    );

    if (!mounted || guardado != true) {
      return;
    }

    await _cargarProductos();

    if (!mounted) {
      return;
    }

    _mostrarMensaje(
      producto == null
          ? 'Producto creado correctamente.'
          : 'Producto actualizado correctamente.',
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
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Eliminar producto',
            style: TextStyle(
              color: _headingColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            '¿Deseas eliminar el producto '
                '"${producto['name'] ?? ''}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: _headingColor,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
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

    if (!mounted || confirmar != true) {
      return;
    }

    try {
      await ApiService.deleteProduct(
        producto['_id'].toString(),
      );

      if (!mounted) {
        return;
      }

      await _cargarProductos();

      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        'Producto eliminado correctamente.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _mostrarMensaje(
        _limpiarError(error),
        error: true,
      );
    }
  }

  String _limpiarError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '');
  }

  void _mostrarMensaje(
      String mensaje, {
        bool error = false,
      }) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: error
              ? Colors.redAccent
              : _headingColor,
          content: Text(mensaje),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _headingColor,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Inventario',
          style: TextStyle(
            color: _headingColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _isLoading
                ? null
                : _cargarProductos,
            icon: const Icon(
              Icons.refresh_rounded,
              color: _headingColor,
            ),
          ),
        ],
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () {
          _mostrarFormulario();
        },
        backgroundColor: _buttonColor,
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
          color: _buttonColor,
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
                color: _iconColor,
                size: 58,
              ),
              const SizedBox(height: 15),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _headingColor,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _cargarProductos,
                style: FilledButton.styleFrom(
                  backgroundColor: _buttonColor,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_productos.isEmpty) {
      return RefreshIndicator(
        color: _buttonColor,
        onRefresh: _cargarProductos,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(
              Icons.inventory_2_outlined,
              color: _iconColor,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No hay productos registrados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _headingColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _buttonColor,
      onRefresh: _cargarProductos,
      child: ListView.separated(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          100,
        ),
        itemCount: _productos.length,
        separatorBuilder: (
            BuildContext context,
            int index,
            ) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          return _buildProductCard(
            _productos[index],
          );
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
      producto['sale_price']
          ?.toString() ??
          '',
    ) ??
        0;

    final int stock = int.tryParse(
      producto['stock']?.toString() ?? '',
    ) ??
        0;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _containerColor,
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
                  color: _buttonColor,
                );
              },
            )
                : const Icon(
              Icons.inventory_2_outlined,
              color: _buttonColor,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _headingColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  producto['brand']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF718197),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 14,
                  runSpacing: 5,
                  children: [
                    Text(
                      '\$${salePrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: _headingColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
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
            tooltip: 'Opciones',
            onSelected: (String value) {
              switch (value) {
                case 'edit':
                  _mostrarFormulario(
                    producto: producto,
                  );
                  break;

                case 'delete':
                  _eliminarProducto(producto);
                  break;
              }
            },
            itemBuilder: (
                BuildContext context,
                ) {
              return const [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: _headingColor,
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

class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({
    super.key,
    this.producto,
  });

  final Map<String, dynamic>? producto;

  @override
  State<ProductFormDialog> createState() {
    return _ProductFormDialogState();
  }
}

class _ProductFormDialogState
    extends State<ProductFormDialog> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  late final TextEditingController
  _nameController;

  late final TextEditingController
  _brandController;

  late final TextEditingController
  _descriptionController;

  late final TextEditingController
  _salePriceController;

  late final TextEditingController
  _purchasePriceController;

  late final TextEditingController
  _stockController;

  late final TextEditingController
  _imageUrlController;

  bool _guardando = false;
  String? _errorMessage;

  bool get _esEditar {
    return widget.producto != null;
  }

  @override
  void initState() {
    super.initState();

    final Map<String, dynamic>? producto =
        widget.producto;

    _nameController = TextEditingController(
      text: producto?['name']?.toString() ?? '',
    );

    _brandController = TextEditingController(
      text: producto?['brand']?.toString() ?? '',
    );

    _descriptionController =
        TextEditingController(
          text:
          producto?['description']?.toString() ??
              '',
        );

    _salePriceController =
        TextEditingController(
          text:
          producto?['sale_price']?.toString() ??
              '',
        );

    _purchasePriceController =
        TextEditingController(
          text: producto?['purchase_price']
              ?.toString() ??
              '',
        );

    _stockController = TextEditingController(
      text: producto?['stock']?.toString() ?? '',
    );

    _imageUrlController =
        TextEditingController(
          text:
          producto?['image_url']?.toString() ??
              '',
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();

    super.dispose();
  }

  Future<void> _guardar() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _guardando = true;
      _errorMessage = null;
    });

    final Map<String, dynamic> datosProducto = {
      'name': _nameController.text.trim(),
      'brand': _brandController.text.trim(),
      'description':
      _descriptionController.text.trim(),
      'sale_price': _parseDecimal(
        _salePriceController.text,
      ),
      'purchase_price': _parseDecimal(
        _purchasePriceController.text,
      ),
      'stock': int.parse(
        _stockController.text.trim(),
      ),
      'image_url':
      _imageUrlController.text.trim(),
      'category_id':
      widget.producto?['category_id'] ?? 1,
    };

    final String? providerId =
    _obtenerProviderId(
      widget.producto?['provider_id'],
    );

    if (providerId != null) {
      datosProducto['provider_id'] = providerId;
    }

    try {
      if (_esEditar) {
        await ApiService.updateProduct(
          widget.producto!['_id'].toString(),
          datosProducto,
        );
      } else {
        await ApiService.createProduct(
          datosProducto,
        );
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _guardando = false;
        _errorMessage = error
            .toString()
            .replaceFirst('Exception: ', '');
      });
    }
  }

  double _parseDecimal(String value) {
    return double.parse(
      value.trim().replaceAll(',', '.'),
    );
  }

  String? _obtenerProviderId(
      dynamic providerValue,
      ) {
    dynamic value = providerValue;

    if (value is Map) {
      value = value['_id'];
    }

    final String text =
        value?.toString().trim() ?? '';

    final bool isObjectId =
    RegExp(r'^[a-fA-F0-9]{24}$')
        .hasMatch(text);

    return isObjectId ? text : null;
  }

  String? _validarTextoObligatorio(
      String? value,
      String mensaje,
      ) {
    if (value == null || value.trim().isEmpty) {
      return mensaje;
    }

    return null;
  }

  String? _validarPrecio(String? value) {
    final String normalized =
        value?.trim().replaceAll(',', '.') ?? '';

    final double? price =
    double.tryParse(normalized);

    if (price == null || price < 0) {
      return 'Ingresa un precio válido.';
    }

    return null;
  }

  String? _validarStock(String? value) {
    final int? stock = int.tryParse(
      value?.trim() ?? '',
    );

    if (stock == null || stock < 0) {
      return 'Ingresa una cantidad válida.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_guardando,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          _esEditar
              ? 'Editar producto'
              : 'Agregar producto',
          style: const TextStyle(
            color: _headingColor,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: SizedBox(
          width: 430,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              autovalidateMode:
              AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildField(
                    controller: _nameController,
                    label: 'Nombre',
                    icon:
                    Icons.inventory_2_outlined,
                    textCapitalization:
                    TextCapitalization.sentences,
                    validator: (String? value) {
                      return _validarTextoObligatorio(
                        value,
                        'Ingresa el nombre.',
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _brandController,
                    label: 'Marca',
                    icon: Icons.sell_outlined,
                    textCapitalization:
                    TextCapitalization.words,
                    validator: (String? value) {
                      return _validarTextoObligatorio(
                        value,
                        'Ingresa la marca.',
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller:
                    _descriptionController,
                    label: 'Descripción',
                    icon:
                    Icons.description_outlined,
                    textCapitalization:
                    TextCapitalization.sentences,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller:
                    _purchasePriceController,
                    label: 'Precio de compra',
                    icon:
                    Icons.shopping_cart_outlined,
                    keyboardType:
                    const TextInputType
                        .numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validarPrecio,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller:
                    _salePriceController,
                    label: 'Precio de venta',
                    icon:
                    Icons.attach_money_rounded,
                    keyboardType:
                    const TextInputType
                        .numberWithOptions(
                      decimal: true,
                    ),
                    validator: _validarPrecio,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _stockController,
                    label: 'Existencias',
                    icon: Icons.numbers_outlined,
                    keyboardType:
                    TextInputType.number,
                    validator: _validarStock,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller:
                    _imageUrlController,
                    label: 'URL de imagen',
                    icon: Icons.image_outlined,
                    keyboardType: TextInputType.url,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFFFFF1F1),
                        borderRadius:
                        BorderRadius.circular(14),
                        border: Border.all(
                          color:
                          const Color(0xFFFFCCCC),
                        ),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFC62828),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _guardando
                ? null
                : () {
              Navigator.of(context).pop(false);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: _headingColor,
              ),
            ),
          ),
          FilledButton(
            onPressed:
            _guardando ? null : _guardar,
            style: FilledButton.styleFrom(
              backgroundColor: _buttonColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
              _buttonColor.withOpacity(0.45),
            ),
            child: _guardando
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
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization =
        TextCapitalization.none,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_guardando,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      cursorColor: _buttonColor,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: _iconColor,
        ),
        filled: true,
        fillColor: _containerColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _buttonColor,
            width: 1.7,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.7,
          ),
        ),
      ),
    );
  }
}