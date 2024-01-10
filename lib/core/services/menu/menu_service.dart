import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/core/services/menu/providers/menu_provider.dart';

class MenuView extends ConsumerWidget{
  const MenuView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuAsync = ref.watch(menuProvider);
    Widget getMenu(){
      switch(menuAsync.name){
        case "main":
          return const Text("Main");
        case "about":
          return const Text("About");
        default:
          return const Text("Error");
      }
    }
    return getMenu();
  }
}