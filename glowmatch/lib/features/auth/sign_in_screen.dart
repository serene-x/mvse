import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';
import '../../env.dart';
import '../../theme.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});
  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) {
        setState(() => _error =
            'Unable to sign in. Check your details and connection, then try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authRepositoryProvider);
    final socialProviders =
        ref.watch(enabledSocialProvidersProvider).valueOrNull ?? {};
    final googleEnabled = socialProviders.any((p) => p.name == 'google');
    final appleEnabled = socialProviders.any((p) => p.name == 'apple');

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('mvse',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  const Text('Your routines, notes, and shade matches.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppPalette.textMuted)),
                  const SizedBox(height: 20),
                  if (!Env.backendAvailable)
                    const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                            'Accounts are unavailable in this version. You can still browse products, ingredients and seasonal shades.',
                            textAlign: TextAlign.center)),
                  TextButton(
                      onPressed: () => context.go('/discovery'),
                      child: const Text('Continue browsing')),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _busy || !Env.backendAvailable
                        ? null
                        : () => _runAuth(() => auth.signInWithEmail(
                            _email.text.trim(), _password.text)),
                    child: const Text('Sign in'),
                  ),
                  if (googleEnabled || appleEnabled) ...[
                    const SizedBox(height: 16),
                    const Row(children: [
                      Expanded(child: Divider()),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or',
                              style: TextStyle(color: AppPalette.textMuted))),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    if (googleEnabled)
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _runAuth(auth.signInWithGoogle),
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text('Continue with Google'),
                      ),
                    const SizedBox(height: 10),
                    if (appleEnabled)
                      OutlinedButton.icon(
                        onPressed:
                            _busy ? null : () => _runAuth(auth.signInWithApple),
                        icon: const Icon(Icons.apple),
                        label: const Text('Continue with Apple'),
                      ),
                  ],
                  const SizedBox(height: 28),
                  TextButton(
                    onPressed: () => context.go('/auth/sign-up'),
                    child: const Text("New here? Create account"),
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }
}
