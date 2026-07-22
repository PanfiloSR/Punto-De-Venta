import 'dart:math';

import 'package:flutter/material.dart';

import 'services/api_service.dart';

double _number(dynamic value) {
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _money(dynamic value) {
  return '\$${_number(value).toStringAsFixed(2)}';
}

class CartItem {
  CartItem({
    required this.product,
    this.quantity = 1,
    this.discountPercent = 0,
  });

  final Map<String, dynamic> product;
  int quantity;
  double discountPercent;

  double get unitPrice {
    return _number(product['sale_price']);
  }

  double get subtotal {
    return unitPrice * quantity;
  }

  double get discountAmount {
    return subtotal * discountPercent / 100;
  }

  double get total {
    return subtotal - discountAmount;
  }

  int get stock {
    return int.tryParse(
      product['stock']?.toString() ?? '',
    ) ??
        0;
  }

  CartItem copy() {
    return CartItem(
      product: Map<String, dynamic>.from(
        product,
      ),
      quantity: quantity,
      discountPercent: discountPercent,
    );
  }
}

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() {
    return _VentasScreenState();
  }
}

class _VentasScreenState
    extends State<VentasScreen> {
  static const Color headingColor = Color(0xFF002254);
  static const Color buttonColor = Color(0xFF00C0FF);
  static const Color containerColor = Color(0xFFE9F1FA);

  bool _loading = true;
  String _search = '';

  List<Map<String, dynamic>> _products = [];
  final List<CartItem> _cart = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
    });

    try {
      final products =
      await ApiService.getProducts();

      if (!mounted) {
        return;
      }

      setState(() {
        _products = products;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _addProduct(
      Map<String, dynamic> product,
      ) {
    final int stock =
        int.tryParse(product['stock'].toString()) ??
            0;

    if (stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El producto no tiene existencias.',
          ),
        ),
      );
      return;
    }

    final int index = _cart.indexWhere(
          (item) =>
      item.product['_id'].toString() ==
          product['_id'].toString(),
    );

    setState(() {
      if (index >= 0) {
        if (_cart[index].quantity < stock) {
          _cart[index].quantity++;
        }
      } else {
        _cart.add(
          CartItem(product: product),
        );
      }
    });
  }

  double get _cartTotal {
    return _cart.fold(
      0,
          (sum, item) => sum + item.total,
    );
  }

  int get _cartQuantity {
    return _cart.fold(
      0,
          (sum, item) => sum + item.quantity,
    );
  }

  Future<void> _openCheckout() async {
    if (_cart.isEmpty) {
      return;
    }

    final bool? completed =
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: _cart,
        ),
      ),
    );

    if (completed == true) {
      setState(() {
        _cart.clear();
      });

      await _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((product) {
      final text =
      '${product['name']} ${product['brand']}'
          .toLowerCase();

      return text.contains(
        _search.toLowerCase(),
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Nueva venta',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            16,
          ),
          child: SizedBox(
            height: 58,
            child: FilledButton(
              onPressed: _openCheckout,
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Carrito ($_cartQuantity)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _money(_cartTotal),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              14,
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _search = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFA5A5A5),
                ),
                filled: true,
                fillColor: containerColor,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
              child:
              CircularProgressIndicator(
                color: buttonColor,
              ),
            )
                : ListView.separated(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                4,
                20,
                100,
              ),
              itemCount: filtered.length,
              separatorBuilder: (_, _) =>
              const SizedBox(height: 11),
              itemBuilder: (
                  context,
                  index,
                  ) {
                final product =
                filtered[index];

                final int stock =
                    int.tryParse(
                      product['stock']
                          .toString(),
                    ) ??
                        0;

                return Material(
                  color: containerColor,
                  borderRadius:
                  BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      _addProduct(product);
                    },
                    borderRadius:
                    BorderRadius.circular(20),
                    child: Padding(
                      padding:
                      const EdgeInsets.all(17),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration:
                            BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                              BorderRadius
                                  .circular(14),
                            ),
                            child: const Icon(
                              Icons
                                  .inventory_2_outlined,
                              color: buttonColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  product['name']
                                      ?.toString() ??
                                      '',
                                  style:
                                  const TextStyle(
                                    color:
                                    headingColor,
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight
                                        .w900,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  'Stock: $stock',
                                  style:
                                  const TextStyle(
                                    color: Color(
                                      0xFF718197,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _money(
                              product[
                              'sale_price'],
                            ),
                            style:
                            const TextStyle(
                              color: headingColor,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.add_circle,
                            color: buttonColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.items,
  });

  final List<CartItem> items;

  @override
  State<CheckoutScreen> createState() {
    return _CheckoutScreenState();
  }
}

class _CheckoutScreenState
    extends State<CheckoutScreen> {
  static const Color headingColor = Color(0xFF002254);
  static const Color buttonColor = Color(0xFF00C0FF);
  static const Color containerColor = Color(0xFFE9F1FA);

  late List<CartItem> _items;

  final TextEditingController
  _generalDiscountController =
  TextEditingController(text: '0');

  final TextEditingController
  _amountReceivedController =
  TextEditingController();

  final TextEditingController _notesController =
  TextEditingController();

  String _paymentMethod = 'efectivo';
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _items = widget.items
        .map((item) => item.copy())
        .toList();
  }

  @override
  void dispose() {
    _generalDiscountController.dispose();
    _amountReceivedController.dispose();
    _notesController.dispose();

    super.dispose();
  }

  double get _subtotal {
    return _items.fold(
      0,
          (sum, item) => sum + item.subtotal,
    );
  }

  double get _productDiscount {
    return _items.fold(
      0,
          (sum, item) =>
      sum + item.discountAmount,
    );
  }

  double get _generalDiscountPercent {
    return min(
      100,
      max(
        0,
        _number(
          _generalDiscountController.text,
        ),
      ),
    );
  }

  double get _generalDiscountAmount {
    final afterProducts =
        _subtotal - _productDiscount;

    return afterProducts *
        _generalDiscountPercent /
        100;
  }

  double get _total {
    return max(
      0,
      _subtotal -
          _productDiscount -
          _generalDiscountAmount,
    );
  }

  double get _amountReceived {
    return _number(
      _amountReceivedController.text,
    );
  }

  double get _change {
    return max(
      0,
      _amountReceived - _total,
    );
  }

  Future<void> _editDiscount(
      CartItem item,
      ) async {
    final controller = TextEditingController(
      text: item.discountPercent
          .toStringAsFixed(0),
    );

    final double? result =
    await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Descuento del producto',
          ),
          content: TextField(
            controller: controller,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Porcentaje',
              suffixText: '%',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = min(
                  100,
                  max(
                    0,
                    _number(controller.text),
                  ),
                );

                Navigator.pop(context, value);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result != null) {
      setState(() {
        item.discountPercent = result;
      });
    }
  }

  Future<void> _completeSale() async {
    if (_items.isEmpty) {
      return;
    }

    if (_paymentMethod == 'efectivo' &&
        _amountReceived < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El efectivo recibido es menor al total.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final result = await ApiService.createSale({
        'items': _items.map((item) {
          return {
            'product_id':
            item.product['_id'].toString(),
            'quantity': item.quantity,
            'discount_percent':
            item.discountPercent,
          };
        }).toList(),
        'general_discount_percent':
        _generalDiscountPercent,
        'payment_method': _paymentMethod,
        'amount_received':
        _paymentMethod == 'efectivo'
            ? _amountReceived
            : _total,
        'notes': _notesController.text.trim(),
      });

      if (!mounted) {
        return;
      }

      final sale = Map<String, dynamic>.from(
        result['venta'],
      );

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(24),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                SizedBox(width: 10),
                Text('Venta registrada'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Folio: ${sale['folio']}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${_money(sale['total'])}',
                ),
                Text(
                  'Cambio: ${_money(sale['change'])}',
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Resumen de venta',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          ..._items.map(_itemCard),
          const SizedBox(height: 18),
          _saleOptions(),
          const SizedBox(height: 18),
          _totals(),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed:
              _saving ? null : _completeSale,
              style: FilledButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
              ),
              child: _saving
                  ? const CircularProgressIndicator(
                color: Colors.white,
              )
                  : Text(
                'Cobrar ${_money(_total)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product['name']
                      ?.toString() ??
                      '',
                  style: const TextStyle(
                    color: headingColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _items.remove(item);
                  });
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          Text(
            '${_money(item.unitPrice)} c/u',
            style: const TextStyle(
              color: Color(0xFF718197),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: item.quantity <= 1
                    ? null
                    : () {
                  setState(() {
                    item.quantity--;
                  });
                },
                icon: const Icon(
                  Icons.remove_circle_outline,
                ),
              ),
              Text(
                '${item.quantity}',
                style: const TextStyle(
                  color: headingColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              IconButton(
                onPressed:
                item.quantity >= item.stock
                    ? null
                    : () {
                  setState(() {
                    item.quantity++;
                  });
                },
                icon: const Icon(
                  Icons.add_circle_outline,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                  _editDiscount(item);
                },
                icon: const Icon(
                  Icons.percent,
                ),
                label: Text(
                  '${item.discountPercent.toStringAsFixed(0)}%',
                ),
              ),
              Text(
                _money(item.total),
                style: const TextStyle(
                  color: headingColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _saleOptions() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          TextField(
            controller:
            _generalDiscountController,
            keyboardType:
            const TextInputType.numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) {
              setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Descuento general',
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _paymentMethod,
            decoration: const InputDecoration(
              labelText: 'Método de pago',
            ),
            items: const [
              DropdownMenuItem(
                value: 'efectivo',
                child: Text('Efectivo'),
              ),
              DropdownMenuItem(
                value: 'tarjeta',
                child: Text('Tarjeta'),
              ),
              DropdownMenuItem(
                value: 'transferencia',
                child: Text('Transferencia'),
              ),
              DropdownMenuItem(
                value: 'otro',
                child: Text('Otro'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _paymentMethod =
                    value ?? 'efectivo';
              });
            },
          ),
          if (_paymentMethod == 'efectivo') ...[
            const SizedBox(height: 14),
            TextField(
              controller:
              _amountReceivedController,
              keyboardType:
              const TextInputType
                  .numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                setState(() {});
              },
              decoration: const InputDecoration(
                labelText: 'Efectivo recibido',
                prefixText: '\$',
              ),
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas',
            ),
          ),
        ],
      ),
    );
  }

  Widget _totals() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE5EDF5),
        ),
      ),
      child: Column(
        children: [
          _totalRow(
            'Subtotal',
            _subtotal,
          ),
          _totalRow(
            'Descuento de productos',
            -_productDiscount,
          ),
          _totalRow(
            'Descuento general',
            -_generalDiscountAmount,
          ),
          const Divider(height: 26),
          _totalRow(
            'Total',
            _total,
            bold: true,
          ),
          if (_paymentMethod == 'efectivo')
            _totalRow(
              'Cambio',
              _change,
            ),
        ],
      ),
    );
  }

  Widget _totalRow(
      String label,
      double value, {
        bool bold = false,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: headingColor,
                fontWeight: bold
                    ? FontWeight.w900
                    : FontWeight.w500,
              ),
            ),
          ),
          Text(
            _money(value),
            style: TextStyle(
              color: headingColor,
              fontSize: bold ? 19 : 15,
              fontWeight: bold
                  ? FontWeight.w900
                  : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}