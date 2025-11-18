import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:senior_fitness_app/ui/app_palette.dart';
import 'package:senior_fitness_app/screens/login_screen.dart';
import 'package:senior_fitness_app/services/gemini_service.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _geminiService = GeminiService();
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  final _nameController = TextEditingController();

  Map<String, dynamic>? _userData;
  bool _loading = true;
  bool _updatingPhoto = false;
  String _sofiMessage = "";
  String _level = "Principiante";
  int _xp = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final snap =
          await _firestore.collection('users').doc(widget.userId).get();
      if (!snap.exists) throw Exception("Usuario no encontrado");

      _userData = snap.data();
      _xp = (_userData?['xp'] ?? 0) as int;
      _level = _determineLevel(_xp);
      _nameController.text = _userData?['name'] ?? 'Usuario';

      final name = _userData?['name'] ?? 'Usuario';
      _sofiMessage = "¡Encantada de verte, $name! 💙";

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _sofiMessage = "💬 Sofi no logró cargar tu información 💙";
        _loading = false;
      });
    }
  }

  String _determineLevel(int xp) {
    if (xp < 200) return 'Principiante';
    if (xp < 500) return 'Intermedio';
    return 'Avanzado';
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final pickedFile =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return;

    setState(() => _updatingPhoto = true);

    try {
      final ref = _storage.ref().child('profile_pics/${widget.userId}.jpg');
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        final file = File(pickedFile.path);
        await ref.putFile(file);
      }

      final url = await ref.getDownloadURL();
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .update({'photoUrl': url});

      setState(() {
        _userData?['photoUrl'] = url;
        _updatingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada correctamente 📸')),
      );
    } catch (e) {
      setState(() => _updatingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al subir la foto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final photoUrl = _userData?['photoUrl'];
    final age = _userData?['age'] ?? 'No especificada';
    final conditions =
        List<String>.from(_userData?['chronic_conditions'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        title: const Text('Mi Perfil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🩵 Sofi Card (fondo azul grande)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: AppPalette.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Lottie.asset('assets/animations/sofi_waving.json',
                      height: 90, width: 90),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _sofiMessage,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 👤 Avatar flotante sobre tarjeta
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Tarjeta blanca con info
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 60),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tu nombre',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3),
                      ),
                      const SizedBox(height: 6),
                      Text("Edad: $age años",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text("Nivel: $_level | $_xp XP",
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

                // Avatar flotante
                Positioned(
                  top: 0,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: AppPalette.primary.withOpacity(0.2),
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(Icons.person,
                                size: 60, color: AppPalette.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: InkWell(
                          onTap: _updatingPhoto ? null : _pickAndUploadPhoto,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppPalette.primary,
                            child: _updatingPhoto
                                ? const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)
                                : const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 🩺 Condiciones médicas
            _buildHealthConditions(conditions),
            const SizedBox(height: 30),

            // 🔴 Botón cerrar sesión (idéntico al mockup)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _logout,
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthConditions(List<String> conditions) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Condiciones de salud',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (conditions.isEmpty)
              const Text('No hay condiciones registradas 🩺',
                  style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: conditions
                    .map((c) => Chip(
                          label: Text(c),
                          backgroundColor: AppPalette.primary.withOpacity(0.15),
                          labelStyle: const TextStyle(color: Colors.black87),
                        ))
                    .toList(),
              ),
          ],
        ),
      );
}
