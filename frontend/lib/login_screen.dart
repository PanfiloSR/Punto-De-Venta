import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'services/api_service.dart';
import 'productos_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color headingColor = Color(0xFF002254);
  static const Color buttonColor = Color(0xFF00C0FF);
  static const Color logoColor = Color(0xFF06BEE1);
  static const Color hintColor = Color(0xFF878787);
  static const Color iconColor = Color(0xFFA5A5A5);
  static const Color containerColor = Color(0xFFe9f1fa);
  static const Color backgroundColor = Colors.white;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;

  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final String? jwtToken =
      await userCredential.user?.getIdToken();

      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception(
          'No fue posible obtener el token de autenticación.',
        );
      }

      ApiService.setToken(jwtToken);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicio de sesión exitoso.'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) {
            return const ProductosScreen();
          },
        ),
      );
    } on FirebaseAuthException catch (error) {
      setState(() {
        _errorMessage = _mapFirebaseError(error);
      });
    } catch (_) {
      setState(() {
        _errorMessage =
        'Ocurrió un error inesperado. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapFirebaseError(
      FirebaseAuthException error,
      ) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo electrónico no tiene un formato válido.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'El correo o la contraseña son incorrectos.';

      case 'user-disabled':
        return 'La cuenta se encuentra deshabilitada.';

      case 'too-many-requests':
        return 'Se realizaron demasiados intentos. Intenta más tarde.';

      case 'network-request-failed':
        return 'No fue posible conectar. Revisa tu conexión.';

      default:
        return error.message ?? 'No fue posible iniciar sesión.';
    }
  }

  InputDecoration _lineInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: hintColor,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
      prefixIconConstraints: const BoxConstraints(
        minWidth: 38,
        minHeight: 44,
      ),
      suffixIcon: suffixIcon,
      filled: false,
      contentPadding: const EdgeInsets.only(
        top: 14,
        bottom: 12,
      ),
      border: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: buttonColor,
          width: 1.4,
        ),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: buttonColor,
          width: 1.4,
        ),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: buttonColor,
          width: 2.2,
        ),
      ),
      errorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
      focusedErrorBorder: const UnderlineInputBorder(
        borderSide: BorderSide(
          color: Colors.redAccent,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              32,
              38,
              32,
              24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(
                    height: 75,
                  ),
                  _buildLoginContainer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/images/logo.svg',
          width: 96,
          height: 96,
          fit: BoxFit.contain,
          colorFilter: const ColorFilter.mode(
            logoColor,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(
          height: 18,
        ),
        const Text(
          'Punto de Venta',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: headingColor,
            fontSize: 31,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginContainer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        24,
        26,
        24,
        26,
      ),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: headingColor.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Iniciar sesión',
              textAlign: TextAlign.left,
              style: TextStyle(
                color: headingColor,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(
              height: 28,
            ),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              cursorColor: buttonColor,
              style: const TextStyle(
                color: headingColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: _lineInputDecoration(
                hint: 'Correo electrónico',
                icon: Icons.email_outlined,
              ),
              validator: (
                  String? value,
                  ) {
                final String email = value?.trim() ?? '';

                if (email.isEmpty) {
                  return 'Ingresa tu correo electrónico.';
                }

                if (!email.contains('@')) {
                  return 'Ingresa un correo válido.';
                }

                return null;
              },
            ),
            const SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              cursorColor: buttonColor,
              style: const TextStyle(
                color: headingColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              onFieldSubmitted: (_) {
                _iniciarSesion();
              },
              decoration: _lineInputDecoration(
                hint: 'Contraseña',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword =
                      !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ),
              validator: (
                  String? value,
                  ) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa tu contraseña.';
                }

                return null;
              },
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD0D0),
                  ),
                ),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC62828),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
            const SizedBox(
              height: 34,
            ),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed:
                _isLoading ? null : _iniciarSesion,
                style: FilledButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  buttonColor.withOpacity(0.45),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(999),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Ingresar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}