import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/main_navigation.dart';
import '../../services/auth_service.dart';
import '../../state/plants_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Enter a valid email.');
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthService().signIn(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showMessage(error);
      return;
    }

    await context.read<PlantsStore>().refreshAfterAuthChange();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(isGuest: false),
      ),
    );
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Enter a valid email.');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthService().signUp(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showMessage(error);
      return;
    }

    await context.read<PlantsStore>().refreshAfterAuthChange();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(isGuest: false),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter your email first.');
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthService().resetPassword(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showMessage(error);
    } else {
      _showMessage('Password reset email sent.');
    }
  }

  Future<void> _continueAsGuest() async {
    await context.read<PlantsStore>().clearForGuest();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(isGuest: true),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/login_bg.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.white.withOpacity(0.75),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'BloomOS',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2A1F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign in to save your plant and diagnosis history',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6F7B6D),
                      ),
                    ),
                    const SizedBox(height: 28),
                    buildInputField(
                      controller: _emailController,
                      hint: 'Email',
                    ),
                    const SizedBox(height: 15),
                    buildInputField(
                      controller: _passwordController,
                      hint: 'Password',
                      isPassword: true,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: const Text('Create account'),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _forgotPassword,
                      child: const Text('Forgot Password?'),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Guest Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF1F2A1F),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'You can use Bluetooth and scan plants, but cloud saving is disabled.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF6F7B6D),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _continueAsGuest,
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text('Continue as Guest'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildInputField({
  required TextEditingController controller,
  required String hint,
  bool isPassword = false,
}) {
  return Container(
    height: 55,
    decoration: BoxDecoration(
      color: const Color(0xFFF1F1F1),
      borderRadius: BorderRadius.circular(18),
    ),
    child: TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(
        color: Colors.black,
      ),
      cursorColor: Colors.black,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    ),
  );
}