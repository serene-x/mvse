import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Env.isConfigured) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      ).timeout(const Duration(seconds: 8));
      Env.backendAvailable = true;
    } catch (_) {
      // Catalog browsing and local saves still work if initialization fails.
      Env.backendAvailable = false;
    }
  }

  runApp(const ProviderScope(child: MvseApp()));
}
