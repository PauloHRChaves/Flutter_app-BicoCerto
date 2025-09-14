import 'package:flutter/material.dart';
import 'services/local_storage_service.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isFirstTime = await LocalStorageService.getIsFirstTime();
  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App',
      initialRoute: isFirstTime ? AppRoutes.welcome : AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}