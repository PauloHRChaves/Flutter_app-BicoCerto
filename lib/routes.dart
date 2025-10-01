import 'package:bico_certo/pages/welcome_page.dart';
import 'package:bico_certo/pages/session_checker_page.dart';
import 'package:bico_certo/pages/auth/auth_wrapper.dart';
import 'package:bico_certo/pages/profile/profile.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart';
import 'package:bico_certo/pages/order/order_page.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String sessionCheck = '/check';
  static const String authWrapper = '/auth';
  static const String profilePage = '/profile';
  static const String walletPage = '/wallet';
   static const String ordersPage = '/orders';

  static get routes => {
    welcome: (context) => const WelcomePage(),
    sessionCheck: (context) => const SessionCheckerPage(),
    authWrapper: (context) => const AuthWrapper(),
    profilePage: (context) => const ProfilePage(),
    walletPage: (context) => const WalletPage(), 
    ordersPage: (context) => const OrdersPage()
  };
}
