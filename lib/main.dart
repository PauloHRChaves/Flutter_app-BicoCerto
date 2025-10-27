import 'package:flutter/material.dart';
import 'package:bico_certo/services/local_storage_service.dart';
import 'package:bico_certo/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:bico_certo/controllers/chat_rooms_controller.dart';
import 'package:bico_certo/services/chat_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isFirstTime = await LocalStorageService.getIsFirstTime();
  await dotenv.load(fileName: ".env");
  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;
  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provider global do ChatRoomsController
        ChangeNotifierProvider(
          create: (_) => ChatRoomsController(ChatApiService())..initialize(),
          lazy: false, // Inicializa imediatamente
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bico Certo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF156b9a)),
          fontFamily: 'LeagueSpartan',
          useMaterial3: true,
        ),
        initialRoute: isFirstTime ? AppRoutes.welcome : AppRoutes.sessionCheck,
        routes: AppRoutes.routes,
      ),
    );
  }
}