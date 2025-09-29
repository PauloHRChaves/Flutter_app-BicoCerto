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
      debugShowCheckedModeBanner: false,
      title: 'Bico Certo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF156b9a)),
        fontFamily: 'LeagueSpartan', 
        useMaterial3: true,
      ),
      initialRoute: isFirstTime ? AppRoutes.welcome : AppRoutes.sessionCheck,
      routes: AppRoutes.routes,
    );
  }
}

// ----------------------------------------------------------------------
// CLASSE AUXILIAR DE LAYOUT (BOTTOM WAVE CLIPPER)
// ----------------------------------------------------------------------

// Clipper personalizado para criar a forma de onda (Usado no AuthWrapper)
class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.75);
    var firstControlPoint = Offset(size.width * 0.25, size.height);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy, firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.5);
    var secondEndPoint = Offset(size.width, size.height * 0.75);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy, secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}