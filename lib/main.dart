import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/init/app_initializer.dart';
import 'core/monitoring/provider_logger.dart';
import 'app_widget.dart';

void main() async {
  await AppInitializer.init();

  runApp(
    ProviderScope(
      observers: [ProviderLogger()],
      child: const IbctApp(),
    ),
  );
}
