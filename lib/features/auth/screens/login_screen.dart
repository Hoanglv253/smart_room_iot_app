import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../home/screens/home_screen.dart';
import '../view_models/login_view_model.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _viewModel = LoginViewModel();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final user = await _viewModel.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
      return;
    }

    final message = _viewModel.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _viewModel.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null) return HomeScreen(user: user);

        return AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            final mediaQuery = MediaQuery.of(context);
            final screenWidth = mediaQuery.size.width;
            final scale = (screenWidth / 390).clamp(0.88, 1.0);
            double fs(double size) => size * scale;

            return Scaffold(
              backgroundColor: Colors.white,
              body: MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: const TextScaler.linear(1.0),
                ),
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: fs(8)),
                        Center(
                          child: Icon(
                            Icons.house_rounded,
                            color: AppColors.primary,
                            size: fs(72),
                          ),
                        ),
                        SizedBox(height: fs(2)),
                        Center(
                          child: Text(
                            'APART-HUB',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: fs(32),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        SizedBox(height: fs(32)),
                        Text(
                          'Đăng nhập',
                          style: TextStyle(
                            color: const Color(0xFF111827),
                            fontSize: fs(42),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: fs(6)),
                        Text(
                          'Chào mừng bạn trở lại',
                          style: TextStyle(
                            color: const Color(0xFF4B5563),
                            fontSize: fs(16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: fs(22)),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: fs(14)),
                        TextField(
                          controller: _passwordController,
                          obscureText: _viewModel.obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Mật khẩu',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 16,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(color: Color(0xFFD1D5DB)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(14)),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.4,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _viewModel.obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: const Color(0xFF6B7280),
                              ),
                              onPressed: _viewModel.togglePasswordVisibility,
                            ),
                          ),
                        ),
                        SizedBox(height: fs(6)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Quên mật khẩu?',
                              style: TextStyle(
                                color: const Color(0xFF1E4F93),
                                fontSize: fs(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: fs(16)),
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _viewModel.isLoading ? null : _login,
                            child: _viewModel.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Đăng nhập',
                                    style: TextStyle(
                                      fontSize: fs(20),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: fs(18)),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 2,
                          children: [
                            Text(
                              'Chưa có tài khoản?',
                              style: TextStyle(
                                color: const Color(0xFF111827),
                                fontSize: fs(16),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: _viewModel.isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterScreen(),
                                        ),
                                      );
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Đăng ký',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: fs(16),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
