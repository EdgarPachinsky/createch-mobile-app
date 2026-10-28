import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'settings.dart';
import 'strings.dart';
import 'theme.dart';

// Children sign in with the login Createch gives them; parents with the parent-portal phone number (or email).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  Future<void> _signIn() async {
    final login = _login.text.trim();
    if (login.isEmpty || _password.text.isEmpty) {
      return setState(() => _error = t(context, 'err_empty'));
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(email: loginEmail(login), password: _password.text);
      // main.dart switches to the kids screen on the auth change
    } on AuthRetryableFetchException {
      // the server couldn't be reached (offline, or a wrong SUPABASE_URL); its message is a raw socket error
      setState(() => _error = t(context, 'err_network'));
    } on AuthException catch (e) {
      setState(() => _error = e.code == 'invalid_credentials' ? t(context, 'err_credentials') : e.message);
    } catch (_) {
      setState(() => _error = t(context, 'err_network'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: funGradient),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Image.asset('assets/logo.png', width: 96, height: 96),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Createch',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      Text(
                        t(context, 'tagline'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 32),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  t(context, 'lets_go'),
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(t(context, 'login_hint')),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _login,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  autofillHints: const [AutofillHints.username],
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: t(context, 'login_label'),
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _password,
                                  obscureText: _hidePassword,
                                  autofillHints: const [AutofillHints.password],
                                  onSubmitted: (_) => _signIn(),
                                  decoration: InputDecoration(
                                    labelText: t(context, 'password'),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      tooltip: t(context, _hidePassword ? 'show_password' : 'hide_password'),
                                      icon: Icon(_hidePassword ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                    ),
                                  ),
                                ),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                                ],
                                const SizedBox(height: 20),
                                FilledButton(
                                  onPressed: _loading ? null : _signIn,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: violet,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                                        )
                                      : Text(
                                          t(context, 'sign_in'),
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(top: 4, right: 4, child: SettingsButtons(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// What the login field means: an email as typed, a phone number as a parent's phone login,
// anything else as a child's login (child accounts, supabase/033_shop_and_child_accounts.sql)
String loginEmail(String input) {
  final login = input.trim();
  if (login.contains('@')) return login;
  final isPhone = RegExp(r'^[\d\s+\-()]+$').hasMatch(login) && login.replaceAll(RegExp(r'\D'), '').length >= 8;
  return isPhone ? phoneLoginEmail(login) : '${login.toLowerCase()}@child.createch.invalid';
}

// Port of the website's normalizePhone / phoneLoginEmail (src/app/global-constants/admin/admin.constant.ts):
// '091 23 45 67' -> '37491234567@phone.createch.invalid'
String phoneLoginEmail(String phone) {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.length == 9 && digits.startsWith('0')) {
    digits = '374${digits.substring(1)}';
  } else if (digits.length == 8) {
    digits = '374$digits';
  }
  return '$digits@phone.createch.invalid';
}
