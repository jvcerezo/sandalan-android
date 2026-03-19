import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Initialize Supabase here in Phase 1

  runApp(
    const ProviderScope(
      child: SandalanApp(),
    ),
  );
}
