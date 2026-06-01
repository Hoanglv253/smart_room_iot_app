import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/widgets/auth_shell.dart';
import '../../home/screens/home_screen.dart';
import '../view_models/register_view_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _viewModel = RegisterViewModel();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final user = await _viewModel.register(
      email: _emailController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      name: _nameController.text,
    );

    if (!mounted) return;

    if (user != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
        (_) => false,
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
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return AuthShell(
          showBackButton: true,
          title: 'Dang ky tai khoan',
          subtitle: 'Tao tai khoan moi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ho va ten',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: _viewModel.obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mat khau',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _viewModel.obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: _viewModel.togglePasswordVisibility,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _viewModel.obscurePassword,
                decoration: const InputDecoration(
                  labelText: 'Xac nhan mat khau',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _viewModel.selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Chon vai tro',
                  prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: UserRole.admin,
                    child: Text('Admin'),
                  ),
                  DropdownMenuItem(
                    value: UserRole.manager,
                    child: Text('Manager'),
                  ),
                  DropdownMenuItem(
                    value: UserRole.user,
                    child: Text('User'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  _viewModel.setRole(value);
                },
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _viewModel.isLoading ? null : _register,
                child: _viewModel.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Dang ky'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _viewModel.isLoading
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Da co tai khoan? Dang nhap'),
              ),
            ],
          ),
        );
      },
    );
  }
}
