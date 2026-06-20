import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = StorageService();
  await storage.init();
  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWith((ref) => storage),
      ],
      child: const SmartClassroomApp(),
    ),
  );
}
