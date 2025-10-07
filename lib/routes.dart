import 'package:bico_certo/pages/profile/dashboard.dart';
import 'package:bico_certo/pages/welcome_page.dart';
import 'package:bico_certo/pages/session_checker_page.dart';
import 'package:bico_certo/pages/auth/auth_wrapper.dart';
import 'package:bico_certo/pages/profile/profile.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart';
import 'package:bico_certo/pages/order/order_page.dart';
import 'package:bico_certo/pages/create/create_info.dart';
import 'package:bico_certo/pages/create/create_form.dart';

import 'package:flutter/material.dart';

// TESTAR PAGINA PROFILE SEM BACKEND
import 'package:bico_certo/test/profile_teste.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String sessionCheck = '/check';
  static const String authWrapper = '/auth';
  static const String profilePage = '/profile';
  static const String walletPage = '/wallet';
  static const String ordersPage = '/orders';
  static const String orderInfoPage = '/info_order';
  static const String createFormPage = '/order_form';
  static const String dashboardPage = '/dashboard';

  // TESTAR PAGINA PROFILE SEM BACKEND
  static const String profileteste = '/teste';

  static Map<String, Widget Function(BuildContext)> get routes => {
    welcome: (context) => const WelcomePage(),
    sessionCheck: (context) => const SessionCheckerPage(),
    authWrapper: (context) => const AuthWrapper(),
    profilePage: (context) => const ProfilePage(),
    walletPage: (context) => const WalletPage(), 
    ordersPage: (context) => const OrdersPage(),
    orderInfoPage: (context) => const OrderInfoPage(),
    createFormPage: (context) => const CreateOrderPage(),
    dashboardPage: (context) => const DashboardScreen(),

    // TESTAR PAGINA PROFILE SEM BACKEND
    profileteste: (context) => const ProfileTeste(),
  };
}