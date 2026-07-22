import 'package:flutter/material.dart';

import 'services/api_service.dart';

double _number(dynamic value) {
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _money(dynamic value) {
  return '\$${_number(value).toStringAsFixed(2)}';
}

String _date(dynamic value) {
  final parsed = DateTime.tryParse(
    value?.toString() ?? '',
  )?.toLocal();

  if (parsed == null) {
    return '';
  }

  String two(int number) {
    return number.toString().padLeft(2, '0');
  }

  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} '
      '${two(parsed.hour)}:${two(parsed.minute)}';
}

class HistorialVentasScreen
    extends StatefulWidget {
  const HistorialVentasScreen({super.key});

  @override
  State<HistorialVentasScreen> createState() {
    return _HistorialVentasScreenState();
  }
}

class _HistorialVentasScreenState
    extends State<HistorialVentasScreen> {
  static const Color headingColor = Color(0xFF002254);
  static const Color buttonColor = Color(0xFF00C0FF);
  static const Color containerColor = Color(0xFFE9F1FA);

  bool _loading = true;
  List<Map<String, dynamic>> _sales = [];

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() {
      _loading = true;
    });

    try {
      final sales = await ApiService.getSales();

      if (mounted) {
        setState(() {
          _sales = sales;
        });
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
          _loading = false;
        });
      }
    }
  }

  void _showDetails(
      Map<String, dynamic> sale,
      ) {
    final items = List<Map<String, dynamic>>.from(
      (sale['items'] as List? ?? []).map(
            (item) =>
        Map<String, dynamic>.from(item),
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  sale['folio']?.toString() ?? '',
                  style: const TextStyle(
                    color: headingColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _date(sale['createdAt']),
                  style: const TextStyle(
                    color: Color(0xFF718197),
                  ),
                ),
                const SizedBox(height: 22),
                ...items.map((item) {
                  return Container(
                    margin:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),
                    padding:
                    const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius:
                      BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                item['name']
                                    ?.toString() ??
                                    '',
                                style:
                                const TextStyle(
                                  color: headingColor,
                                  fontWeight:
                                  FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${item['quantity']} × ${_money(item['unit_price'])}',
                              ),
                              Text(
                                'Descuento: ${_money(item['discount_amount'])}',
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
                            item['line_total'],
                          ),
                          style: const TextStyle(
                            color: headingColor,
                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 30),
                _detailRow(
                  'Subtotal',
                  sale['subtotal'],
                ),
                _detailRow(
                  'Descuento total',
                  sale['total_discount'],
                ),
                _detailRow(
                  'Total',
                  sale['total'],
                  bold: true,
                ),
                _detailRow(
                  'Recibido',
                  sale['amount_received'],
                ),
                _detailRow(
                  'Cambio',
                  sale['change'],
                ),
                const SizedBox(height: 12),
                Text(
                  'Método de pago: ${sale['payment_method']}',
                  style: const TextStyle(
                    color: headingColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailRow(
      String label,
      dynamic value, {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Historial de ventas',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: buttonColor,
        ),
      )
          : RefreshIndicator(
        color: buttonColor,
        onRefresh: _loadSales,
        child: _sales.isEmpty
            ? const Center(
          child: Text(
            'No hay ventas registradas.',
          ),
        )
            : ListView.separated(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          itemCount: _sales.length,
          separatorBuilder: (_, _) =>
          const SizedBox(
            height: 11,
          ),
          itemBuilder: (
              context,
              index,
              ) {
            final sale =
            _sales[index];

            final items =
                sale['items'] as List? ??
                    [];

            return Material(
              color: containerColor,
              borderRadius:
              BorderRadius.circular(
                21,
              ),
              child: InkWell(
                onTap: () {
                  _showDetails(sale);
                },
                borderRadius:
                BorderRadius.circular(
                  21,
                ),
                child: Padding(
                  padding:
                  const EdgeInsets.all(
                    18,
                  ),
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
                              .circular(
                            14,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .receipt_long_outlined,
                          color:
                          buttonColor,
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            Text(
                              sale['folio']
                                  ?.toString() ??
                                  '',
                              style:
                              const TextStyle(
                                color:
                                headingColor,
                                fontWeight:
                                FontWeight
                                    .w900,
                              ),
                            ),
                            Text(
                              _date(
                                sale[
                                'createdAt'],
                              ),
                              style:
                              const TextStyle(
                                color: Color(
                                  0xFF718197,
                                ),
                              ),
                            ),
                            Text(
                              '${items.length} productos · ${sale['payment_method']}',
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
                          sale['total'],
                        ),
                        style:
                        const TextStyle(
                          color:
                          headingColor,
                          fontSize: 17,
                          fontWeight:
                          FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}