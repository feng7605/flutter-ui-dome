
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MenusList{
  const MenusList({
    required this.list,
  });
  final List<MenusList> list;
}

class MenuInfo {
  final String name;
  final String icon;

  MenuInfo(this.name, this.icon);
}

