import 'package:flutter/material.dart';
import 'services/api_service.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _productos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  // 1. CONSULTA (Read)
  void _cargarProductos() async {
    setState(() => _isLoading = true);
    try {
      final datos = await _apiService.obtenerProductos();
      setState(() => _productos = datos);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar inventario: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. ALTA Y MODIFICACIÓN
  void _mostrarFormulario({Map<String, dynamic>? producto}) {
    final bool esEditar = producto != null;

    final nameController = TextEditingController(
      text: esEditar ? producto['name'] : '',
    );
    final brandController = TextEditingController(
      text: esEditar ? producto['brand'] : '',
    );
    final descriptionController = TextEditingController(
      text: esEditar ? producto['description'] : '',
    );
    final salePriceController = TextEditingController(
      text: esEditar ? producto['sale_price'].toString() : '',
    );
    final purchasePriceController = TextEditingController(
      text: esEditar ? producto['purchase_price'].toString() : '',
    );
    final stockController = TextEditingController(
      text: esEditar ? producto['stock'].toString() : '',
    );
    final imageUrlController = TextEditingController(
      text: esEditar ? producto['image_url'] : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(esEditar ? "Editar Producto" : "Agregar Nuevo Producto"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre (name)'),
              ),
              TextField(
                controller: brandController,
                decoration: const InputDecoration(labelText: 'Marca (brand)'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              TextField(
                controller: salePriceController,
                decoration: const InputDecoration(
                  labelText: 'Precio Venta (sale_price)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: purchasePriceController,
                decoration: const InputDecoration(
                  labelText: 'Precio Compra (purchase_price)',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad en Stock',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de Imagen (image_url)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> datosProducto = {
                "name": nameController.text.trim(),
                "brand": brandController.text.trim(),
                "description": descriptionController.text.trim(),
                "sale_price": double.tryParse(salePriceController.text) ?? 0.0,
                "purchase_price":
                    double.tryParse(purchasePriceController.text) ?? 0.0,
                "stock": int.tryParse(stockController.text) ?? 0,
                "image_url": imageUrlController.text.trim(),
                "category_id": producto != null ? producto['category_id'] : 1,
                "provider_id": producto != null ? producto['provider_id'] : 1,
              };

              bool exito;
              if (esEditar) {
                exito = await _apiService.actualizarProducto(
                  producto['_id'].toString(),
                  datosProducto,
                );
              } else {
                exito = await _apiService.crearProducto(datosProducto);
              }

              if (mounted) {
                if (exito) {
                  Navigator.pop(context);
                  _cargarProductos();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        esEditar
                            ? '¡Producto actualizado!'
                            : '¡Producto guardado exitosamente!',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Error al procesar la solicitud en el backend',
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // 3. REQUISITO R3: PROCESAR VENTA (Acción de la moneda)
  void _mostrarDialogoVenta(Map<String, dynamic> producto) {
    final cantidadController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Vender ${producto['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Stock actual: ${producto['stock']} unidades disponibles."),
            const SizedBox(height: 12),
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(
                labelText: '¿Cuántos deseas vender?',
                border: OutlineInputBorder(),
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
            onPressed: () async {
              int cantidad = int.tryParse(cantidadController.text) ?? 0;
              if (cantidad <= 0 || cantidad > producto['stock']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cantidad inválida o stock insuficiente.'),
                  ),
                );
                return;
              }

              bool exito = await _apiService.venderProducto(
                producto['_id'].toString(),
                cantidad,
              );
              if (mounted) {
                Navigator.pop(context);
                if (exito) {
                  _cargarProductos(); // Refrescar lista con el stock disminuido
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '¡Venta registrada! El inventario disminuyó.',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error al procesar la venta en el backend'),
                    ),
                  );
                }
              }
            },
            child: const Text("Confirmar Venta"),
          ),
        ],
      ),
    );
  }

  // 4. BAJA (Delete)
  void _eliminarProducto(String id) async {
    bool exito = await _apiService.eliminarProducto(id);
    if (exito) {
      _cargarProductos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado del inventario')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Módulo Inventario Seguro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarProductos,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _productos.isEmpty
          ? const Center(
              child: Text('No hay productos registrados en la base de datos.'),
            )
          : ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final prod = _productos[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading:
                        prod['image_url'] != null &&
                            prod['image_url'].toString().startsWith('http')
                        ? Image.network(
                            prod['image_url'],
                            width: 50,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.shopping_bag),
                          )
                        : const Icon(
                            Icons.shopping_bag,
                            size: 40,
                            color: Colors.blueGrey,
                          ),
                    title: Text(
                      "${prod['name']} (${prod['brand']})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Stock: ${prod['stock']} uds. | Venta: \$${prod['sale_price']}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ➔ BOTÓN EXTRA: Vender (Icono de Moneda) - Cumple R3
                        IconButton(
                          icon: const Icon(
                            Icons.monetization_on,
                            color: Colors.green,
                          ),
                          onPressed: () => _mostrarDialogoVenta(prod),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _mostrarFormulario(producto: prod),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _eliminarProducto(prod['_id'].toString()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
