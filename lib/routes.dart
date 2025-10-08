import 'package:flutter/material.dart';

import 'package:bico_certo/pages/welcome_page.dart';
// AUTENTICAÇÃO
import 'package:bico_certo/pages/session_checker_page.dart';
import 'package:bico_certo/pages/auth/auth_wrapper.dart';
import 'package:bico_certo/pages/auth/forgot_password_page.dart'; 
import 'package:bico_certo/pages/auth/reset_password_page.dart';
// PERFIL
import 'package:bico_certo/pages/profile/dashboard.dart';
import 'package:bico_certo/pages/profile/profile.dart';
// WALLET
import 'package:bico_certo/pages/wallet/import_wallet_page.dart'; 
import 'package:bico_certo/pages/wallet/create_wallet_page.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart'; 
    // IMPORTS PARA AS PÁGINAS DE TRANSAÇÃO
import 'package:bico_certo/pages/wallet/send_page.dart';
import 'package:bico_certo/pages/wallet/receive_page.dart';
// JOBS
import 'package:bico_certo/pages/order/order_page.dart';
import 'package:bico_certo/pages/create/create_info.dart';
import 'package:bico_certo/pages/create/create_form.dart';


// TESTAR PAGINA SEM BACKEND 🚧
import 'package:bico_certo/test/profile_teste.dart'; // Perfil

class AppRoutes {
// TESTAR PAGINA SEM BACKEND 🚧
  static const String profileteste='/teste';

  // Rotas Essenciais
  static const String welcome = '/';
  static const String sessionCheck = '/check';
  static const String authWrapper = '/auth';

  // Rotas Principais
  static const String profilePage = '/profile';
  static const String walletPage = '/wallet';
  static const String ordersPage = '/orders';
  static const String dashboardPage = '/dashboard';

  // Rotas de Serviço
  static const String orderInfoPage = '/order_info';
  static const String createFormPage = '/order_form';
  
  // Rotas de Autenticação
  static const String forgotPasswordPage = '/forgot-password';
  static const String resetPasswordPage = '/reset-password';
  static const String createWalletPage = '/create-wallet';
  static const String importWalletPage = '/import-wallet';

  // NOVAS ROTAS PARA AS AÇÕES DE CARTEIRA
  static const String sendPage = '/send-money';
  static const String receivePage = '/receive-money';


  static Map<String, Widget Function(BuildContext)> get routes => {
    // TESTAR PAGINA SEM BACKEND 🚧
    profileteste: (context) => const ProfileTeste(),

    // Rotas Essenciais
    welcome: (context) => const WelcomePage(),
    sessionCheck: (context) => const SessionCheckerPage(),
    authWrapper: (context) => const AuthWrapper(),

    // Rotas de Páginas
    profilePage: (context) => const ProfilePage(),
    walletPage: (context) => const WalletPage(), 
    ordersPage: (context) => const OrdersPage(),
    dashboardPage: (context) => const DashboardScreen(),

    // Rotas de Serviço
    orderInfoPage: (context) => const OrderInfoPage(),
    createFormPage: (context) => const CreateOrderPage(),
    forgotPasswordPage: (context) => const ForgotPasswordPage(),
    resetPasswordPage: (context) => const ResetPasswordPage(),
    createWalletPage: (context) => const CreateWalletPage(),
    
    // Rotas Send e Receive
    sendPage: (context) => const SendPage(), 
    receivePage: (context) => const ReceivePage(),
    importWalletPage: (context) => const ImportWalletPage(),
  };
}