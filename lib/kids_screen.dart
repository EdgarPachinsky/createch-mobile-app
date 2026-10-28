import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'child_home_screen.dart';
import 'settings.dart';
import 'strings.dart';
import 'theme.dart';

// After sign-in: a child account opens its own page; a parent's children come from my_children, where
// one child opens straight away and siblings pick who they are.
class KidsScreen extends StatefulWidget {
  const KidsScreen({super.key});

  @override
  State<KidsScreen> createState() => _KidsScreenState();
}

class _KidsScreenState extends State<KidsScreen> {
  late Future<List<Map<String, dynamic>>?> _kids = _load();

  // null for a child account (child_accounts row, supabase/033_shop_and_child_accounts.sql), else the parent's children
  Future<List<Map<String, dynamic>>?> _load() async {
    final db = Supabase.instance.client;
    try {
      final me = await db.from('child_accounts').select('child_id').eq('id', db.auth.currentUser!.id).maybeSingle();
      if (me != null) return null;
    } on PostgrestException {
      // shortcut: no child_accounts table before migration 033, so everyone is a parent; drop once it is run
    }
    return List<Map<String, dynamic>>.from(await db.rpc('my_children') as List);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _kids,
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorView(onRetry: () => setState(() {
            _kids = _load();
          }));
        }
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final kids = snap.data;
        if (kids == null) return const ChildHomeScreen(child: null, canGoBack: false);
        if (kids.length == 1) return ChildHomeScreen(child: kids.first, canGoBack: false);
        return Scaffold(
          appBar: AppBar(
            title: Text(t(context, 'who_is_playing'), style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            actions: const [SettingsButtons(), SignOutButton()],
          ),
          body: kids.isEmpty
              ? Center(child: Text(t(context, 'no_kids'), textAlign: TextAlign.center))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final (i, kid) in kids.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: [violet, pink, mint, sky][i % 4],
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChildHomeScreen(child: kid, canGoBack: true)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Avatar(name: kid['full_name'] as String, size: 56),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      kid['full_name'] as String,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  const Avatar({super.key, required this.name, required this.size});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: Colors.white,
    child: Text(
      name.isEmpty ? '?' : name.characters.first.toUpperCase(),
      style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.bold, color: violet),
    ),
  );
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: t(context, 'sign_out'),
    icon: const Icon(Icons.logout),
    onPressed: () {
      // pop pushed child pages so the login screen underneath shows
      Navigator.of(context).popUntil((r) => r.isFirst);
      Supabase.instance.client.auth.signOut();
    },
  );
}

class ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(backgroundColor: Colors.transparent, actions: const [SettingsButtons(), SignOutButton()]),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🙈', style: TextStyle(fontSize: 56)),
          Text(t(context, 'load_error')),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: Text(t(context, 'try_again'))),
        ],
      ),
    ),
  );
}
