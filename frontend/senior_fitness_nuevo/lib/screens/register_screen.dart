import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:senior_fitness_app/ui/app_palette.dart';
import 'package:senior_fitness_app/screens/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Femenino';

  final List<String> _conditions = [
    'Hipertensión',
    'Diabetes',
    'Artrosis',
    'Osteoporosis',
    'Problemas cardíacos',
    'Artritis',
    'Ninguna',
  ];

  final Set<String> _selectedConditions = {};
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus(); // Cierra teclado
    setState(() => _isLoading = true);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = credential.user;
      if (user == null) throw Exception('No se pudo crear el usuario.');

      await _firestore.collection('users').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 60,
        'gender': _gender,
        'chronic_conditions': _selectedConditions.isNotEmpty
            ? _selectedConditions.toList()
            : ['Ninguna'],
        'xp_points': 0,
        'streak': 0,
        'last_exercise_completed': null,
        'last_login': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '🎉 Registro exitoso. ¡Bienvenido a Senior Fitness! Ahora inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🧠 Sofi pensando animada
                SizedBox(
                  height: 180,
                  child: Lottie.asset(
                    'assets/animations/sofi_thinking.json',
                    repeat: true,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.face_retouching_natural_outlined,
                      color: AppPalette.primary,
                      size: 100,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  '¡Bienvenido a Senior Fitness! 🌿',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppPalette.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Completa tu registro para comenzar tu entrenamiento con Sofi 💪',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Ingresa tu nombre'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu correo';
                    }
                    if (!value.contains('@')) {
                      return 'Correo no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value != null && value.length < 6
                      ? 'Debe tener al menos 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Edad (en años)',
                    prefixIcon: Icon(Icons.cake_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  items: ['Femenino', 'Masculino', 'Otro']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) => setState(() => _gender = value!),
                  decoration: const InputDecoration(
                    labelText: 'Género',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Condiciones médicas (selecciona las que correspondan)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),

                ..._conditions.map((c) {
                  return CheckboxListTile(
                    title: Text(c),
                    value: _selectedConditions.contains(c),
                    activeColor: AppPalette.primary,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedConditions.add(c);
                        } else {
                          _selectedConditions.remove(c);
                        }
                      });
                    },
                  );
                }),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrarse',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),

                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Center(
                    child: Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(
                        color: AppPalette.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
