import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/local_storage_service.dart';
import 'services/chat_api_service.dart';
import 'controllers/chat_rooms_controller.dart';
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
/* 
  A rota inicial, em routes.dart, vai ser '/welcome' se for a primeira vez acessando o app ->
  vai passar para 'sessionCheck' onde vai verificar e passar o atributo "isLoggedIn" e mandar para a 'home_page' ->
  - Caso o "isLoggedIn" o usuario pode acessar a 'home_page' e o app normalmente.

  - Caso o "!isLoggedIn" botão de "login" vai habilitar, o usuario vai precisar logar || registrar ->
    vai ser mandado para a rota '/auth' e seguir a logica de 'auth_wrapper' ->
    vai para login_page//register_page.
*/