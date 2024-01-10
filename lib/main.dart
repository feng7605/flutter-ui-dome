
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frame/app/app.dart';
import 'package:frame/app/global.dart';
import 'package:frame/app/observers.dart';
import 'package:frame/core/storage/hive_storage_service.dart';
import 'package:frame/core/storage/storage_service.dart';
import 'package:frame/core/storage/storage_service_provider.dart';
import 'package:frame/utils/state_logger.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main(){
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      //EnvInfo.initialize(environment);
      await Hive.initFlutter();
      final StorageService initializedStorageService = HiveStorageService();
      await initializedStorageService.init();
      runApp(ProviderScope(
        observers: [
          Observers(), const StateLogger(),
        ],
        overrides: [
          storageServiceProvider.overrideWithValue(initializedStorageService)
        ],
        child: MyApp(),
      ));
    },
    (e, _) => throw e,
  );
}