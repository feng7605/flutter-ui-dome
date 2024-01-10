import 'package:equatable/equatable.dart';

class DemoConfigInfos extends Equatable {
  const DemoConfigInfos({
    required this.demoConfigInfos,
  });
  final List<DemoConfigInfo> demoConfigInfos;

  factory DemoConfigInfos.fromJson(Map<String, dynamic> json) {
    return const DemoConfigInfos(
      demoConfigInfos: [],
    );
  }
  
  @override
  List<Object?> get props => demoConfigInfos;
}


class DemoConfigInfo {
  const DemoConfigInfo({
    required this.name,
    this.age,
    this.title, // 可选的title参数
  });

  final String name;
  final int? age;
  final String? title;
}