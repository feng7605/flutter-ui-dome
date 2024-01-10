import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/core/style/themes.dart';
import 'package:frame/features/demo/providers/demo_provider.dart';
import 'package:frame/features/demo/views/pages/demo_page.dart';
import 'package:frame/widgets/app_loader.dart';
import 'package:frame/widgets/error_view.dart';

class MyApp extends ConsumerWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoAsync = ref.watch(demoProvider);

    return MaterialApp(
      themeMode: ThemeMode.dark,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      home: demoAsync.when(data: (Object data){
        return const DemoPage();
      }, error: (Object error, StackTrace? stackTrace){
        log('Error fetching configurations');
        log(error.toString());
        log(stackTrace.toString());
        return const Scaffold(body: ErrorView());
      }, 
      loading: () => const Scaffold(body: AppLoader()),
    ));
  }
}