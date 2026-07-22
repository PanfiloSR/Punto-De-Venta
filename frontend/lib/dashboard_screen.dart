import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'historial_ventas_screen.dart';
import 'login_screen.dart';
import 'productos_screen.dart';
import 'proveedores_screen.dart';
import 'services/api_service.dart';
import 'ventas_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() {
    return _DashboardScreenState();
  }
}

class _DashboardScreenState
    extends State<DashboardScreen> {
  static const Color headingColor = Color(0xFF002254);
  static const Color buttonColor = Color(0xFF00C0FF);
  static const Color logoColor = Color(0xFF06BEE1);
  static const Color containerColor = Color(0xFFE9F1FA);

  late Future<Map<String, dynamic>> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = ApiService.getSummary();
  }

  void _refresh() {
    setState(() {
      _summaryFuture = ApiService.getSummary();
    });
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    ApiService.clearToken();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  void _open(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    ).then((_) {
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Panel principal',
          style: TextStyle(
            color: headingColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: headingColor,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: buttonColor,
        onRefresh: () async {
          _refresh();
          await _summaryFuture;
        },
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            22,
            12,
            22,
            30,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 28),
              _buildSummary(),
              const SizedBox(height: 30),
              const Text(
                'Módulos',
                style: TextStyle(
                  color: headingColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              _buildModules(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: 58,
            height: 58,
            colorFilter: const ColorFilter.mode(
              logoColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 18),
          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Punto de Venta',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Control general del negocio',
                  style: TextStyle(
                    color: Color(0xFF70839D),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: buttonColor,
            ),
          );
        }

        final Map<String, dynamic> summary =
            snapshot.data ?? {};

        return Row(
          children: [
            Expanded(
              child: _summaryCard(
                title: 'Productos',
                value:
                '${summary['total_productos'] ?? 0}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                title: 'Ventas hoy',
                value:
                '${summary['ventas_hoy'] ?? 0}',
                icon: Icons.receipt_long_outlined,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5EDF5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: buttonColor,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: headingColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF78879A),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModules() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns =
        constraints.maxWidth > 700 ? 4 : 2;

        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics:
          const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.95,
          children: [
            _moduleCard(
              title: 'Inventario',
              description:
              'Productos y existencias',
              icon: Icons.inventory_2_outlined,
              onTap: () {
                _open(const ProductosScreen());
              },
            ),
            _moduleCard(
              title: 'Nueva venta',
              description:
              'Registrar una operación',
              icon: Icons.point_of_sale_outlined,
              onTap: () {
                _open(const VentasScreen());
              },
            ),
            _moduleCard(
              title: 'Historial',
              description:
              'Consultar ventas realizadas',
              icon: Icons.history_rounded,
              onTap: () {
                _open(
                  const HistorialVentasScreen(),
                );
              },
            ),
            _moduleCard(
              title: 'Proveedores',
              description:
              'Agenda de contactos',
              icon: Icons.local_shipping_outlined,
              onTap: () {
                _open(
                  const ProveedoresScreen(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _moduleCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: containerColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(15),
                ),
                child: Icon(
                  icon,
                  color: buttonColor,
                  size: 26,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: headingColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF718197),
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}