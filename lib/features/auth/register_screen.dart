import 'package:flutter/material.dart';
import 'package:mobile_app/core/state/app_state.dart';
import 'package:mobile_app/core/theme/app_tokens.dart';
import 'package:mobile_app/core/widgets/app_components.dart';
import 'package:mobile_app/core/widgets/fairytale_background.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onSwitchToLogin});

  final VoidCallback onSwitchToLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _agreeToPolicy = true;
  bool _hidePassword = true;
  bool _hideConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFD32F2F), // A readable error red
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      _showError('Traveler\'s Name cannot be empty.');
      return;
    }

    if (email.isEmpty) {
      _showError('The Email Scroll cannot be empty.');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('Please enter a valid magical email scroll.');
      return;
    }

    if (password.isEmpty) {
      _showError('Your Secret Passphrase is required.');
      return;
    }

    if (password != confirm) {
      _showError('Your passphrases do not match.');
      return;
    }

    setState(() => _loading = true);

    try {
      await context.read<AppState>().register(
        fullName: name,
        email: email,
        password: password,
      );
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FairytaleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                const IllustrationPanel(
                  title: 'Begin Your Quest',
                  subtitle: 'Start your journey, learn the ancient spells, and earn magical relics.',
                  icon: Icons.person_add_alt_1_rounded,
                  height: 160,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Join the Realm',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextInput(
                  controller: _nameController,
                  label: 'Traveler\'s Name',
                  hint: 'Linda Smith',
                  prefixIcon: Icons.badge_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextInput(
                  controller: _emailController,
                  label: 'Email Scroll',
                  hint: 'name@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextInput(
                  controller: _passwordController,
                  label: 'Secret Passphrase',
                  hint: 'Create a secure passphrase',
                  obscureText: _hidePassword,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => _hidePassword = !_hidePassword);
                    },
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextInput(
                  controller: _confirmController,
                  label: 'Confirm Passphrase',
                  hint: 'Re-enter your passphrase',
                  obscureText: _hideConfirm,
                  prefixIcon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() => _hideConfirm = !_hideConfirm);
                    },
                    icon: Icon(
                      _hideConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToPolicy,
                      onChanged: (value) {
                        setState(() => _agreeToPolicy = value ?? false);
                      },
                    ),
                    const Expanded(
                      child: Text('I agree to the Magical Code of Conduct (Terms)'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _loading
                    ? const AppLoadingState(label: 'Inscribing scroll in the registry...')
                    : AppPrimaryButton(
                        label: 'Sign Up',
                        icon: Icons.rocket_launch_rounded,
                        onPressed: _handleSignUp,
                        enabled: _agreeToPolicy,
                      ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Already have a scroll? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: widget.onSwitchToLogin,
                        child: const Text('Sign in'),
                      ),
                    ],
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
