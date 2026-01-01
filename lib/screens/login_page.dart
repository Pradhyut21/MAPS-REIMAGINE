import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wayfinder/theme.dart';
import 'package:wayfinder/widgets/app_background.dart';
import 'package:wayfinder/services/auth_service.dart';
import 'package:wayfinder/nav.dart';

class LoginPage extends StatefulWidget {
  final String? redirect;
  const LoginPage({super.key, this.redirect});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.signInOrCreate(name: _nameCtrl.text, email: _emailCtrl.text);
      if (!mounted) return;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign in failed')));
        return;
      }
      final target = widget.redirect ?? AppRoutes.home;
      context.go(target);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('LoginPage.build');
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: AppGradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: Container(
              width: 420,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.25)),
              ),
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Icon(Icons.account_circle, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text('Welcome', style: context.textStyles.titleLarge?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
                      ]),
                      const SizedBox(height: 6),
                      Text('Sign in or create an account to book trips and sync your data.', style: context.textStyles.bodySmall?.copyWith(color: AppColors.lightGray)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person)),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email (optional)', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password (local only)', prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) => (v == null || v.trim().length < 4) ? 'Min 4 characters' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: const Icon(Icons.login),
                        label: Text(_loading ? 'Signing in...' : 'Continue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: const StadiumBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() => _loading = true);
                                try {
                                  await AuthService.instance.signInOrCreate(name: 'Guest');
                                  if (!mounted) return;
                                  final target = widget.redirect ?? AppRoutes.home;
                                  context.go(target);
                                } finally {
                                  if (mounted) setState(() => _loading = false);
                                }
                              },
                        child: const Text('Continue as guest'),
                      ),
                      const SizedBox(height: 8),
                      Text('For cloud login and booking, connect a backend in the Firebase or Supabase panel from the left sidebar.',
                          style: context.textStyles.labelSmall?.copyWith(color: AppColors.lightGray)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
