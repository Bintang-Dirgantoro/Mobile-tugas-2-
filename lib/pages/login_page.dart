import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_services.dart';
import '../theme/app_colors.dart';
import 'home_page.dart';

/// Halaman Login dengan Session Firebase Auth
/// 
/// Fitur:
/// 1. Validasi format email dan kelengkapan password.
/// 2. Pencegahan spam klik dengan status `_isLoading`.
/// 3. Penanganan error spesifik FirebaseAuthException (password salah, email tidak terdaftar, jaringan offline).
/// 4. Sesi login otomatis tersimpan secara persisten oleh Firebase Auth di perangkat.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password wajib diisi!'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(email, password);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login gagal, periksa koneksi Anda.';

      if (e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'user-not-found') {
        message = 'Email atau password yang Anda masukkan salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format alamat email tidak valid.';
      } else if (e.code == 'user-disabled') {
        message = 'Akun pengguna ini telah dinonaktifkan.';
      } else if (e.code == 'too-many-requests') {
        message = 'Terlalu banyak percobaan gagal. Silakan coba beberapa saat lagi.';
      } else if (e.code == 'network-request-failed') {
        message = 'Koneksi internet bermasalah. Periksa jaringan Anda.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.danger,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo / Icon Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_outline, color: AppColors.accent, size: 38),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Smart UMKM & Utilitas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Silakan login untuk mengakses seluruh fitur aplikasi',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Form Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Alamat Email',
                    hintText: 'nama@email.com',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.accent, size: 20),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Form Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    prefixIcon: const Icon(Icons.key_outlined, color: AppColors.accent, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Login
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Masuk ke Aplikasi',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Catatan: Sesi login akan tetap tersimpan di perangkat ini hingga Anda menekan tombol Logout.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
