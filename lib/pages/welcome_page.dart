import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../routes.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _continue(BuildContext context) async {
    await LocalStorageService.setIsFirstTime(false);

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => _continue(context),
          child: const Text("Continuar"),
        ),
      ),
    );
  }
}