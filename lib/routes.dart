import 'package:app_bicocerto/pages/home_page.dart';

class AppRoutes {
  static const String home = '/';
  
  static get routes => {
    home: (context) => const HomePage(),
  };
}