import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/core/configs/display_config.dart';
import 'package:frame/core/services/menu/menu_service.dart';
import 'package:frame/core/services/menu/models/menu_types.dart';
import 'package:frame/core/services/menu/providers/menu_provider.dart';
import 'package:frame/core/services/menu/widgets/side_menu.dart';

class DemoPage extends ConsumerWidget{
  const DemoPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("app"),
      // ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            if(DisplayConfig.isDesktop(context))
              Expanded(
                // default flex = 1
                // and it takes 1/6 part of the screen
                child: SideMenu(onTap: ref.read(menuProvider.notifier).setMenuName,),
              ),
            const Expanded(
              flex: 5,
              child: MenuView(),
            )
          ]
        ),
      ),
    );
  }

}