import 'pages/welcome_page.dart';
import 'pages/login_page.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';

  static get routes => {
    welcome: (context) => const WelcomePage(),
    login: (context) => const LoginPage(),
  };
}