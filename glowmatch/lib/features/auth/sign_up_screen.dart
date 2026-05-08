import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../theme.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});
  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _checkInbox = false;

  Future<void> _signUp() async {
    final auth = ref.read(authRepositoryProvider);
    setState(() { _busy = true; _error = null; });
    try {
      await auth.signUpWithEmail(_email.text.trim(), _password.text);
      // If email confirm is on, user must verify; if off, session is set.
      if (auth.currentSession != null) {
        if (mounted) context.go('/onboarding');
      } else {
        setState(() => _checkInbox = true);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create account',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  if (_checkInbox)
                    const Text(
                      'Check your inbox to verify your email, then sign in.',
                      style: TextStyle(color: AppPalette.textMuted),
                    )
                  else ...[
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password (min 8 chars)'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _busy ? null : _signUp,
                      child: const Text('Create account'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => context.go('/auth/sign-in'),
                    child: const Text('Have an account? Sign in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
