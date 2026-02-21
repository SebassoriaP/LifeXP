import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';
import '../core/supabase/supabase_client.dart';

class LifeXPApp extends ConsumerWidget {
  const LifeXPApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final init = ref.watch(supabaseInitProvider);

    return init.when(
      loading: () => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: Text('Error al inicializar: $e')),
        ),
      ),
      data: (_) {
        final router = ref.watch(goRouterProvider);
        return MaterialApp.router(
          title: 'LifeXP',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.dark,
          routerConfig: router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
