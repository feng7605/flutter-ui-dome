import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/core/services/menu/models/menu_types.dart';

final menuProvider = StateNotifierProvider<CurrMenuNotifier, MenuInfo>((ref) {
  return CurrMenuNotifier("");
});

class CurrMenuNotifier extends StateNotifier<MenuInfo>{
  final String name;
  CurrMenuNotifier(this.name) : super(MenuInfo(name, ""));

  void setMenu(MenuInfo menu){
    state = menu;
  }
  void setMenuName(String name){
    state = MenuInfo(name, "");
  }
}
