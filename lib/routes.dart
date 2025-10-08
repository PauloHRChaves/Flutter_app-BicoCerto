/*
import 'package:bico_certo/pages/profile/dashboard.dart';
import 'package:bico_certo/pages/wallet/create_wallet_page.dart';
import 'package:bico_certo/pages/welcome_page.dart';
import 'package:bico_certo/pages/session_checker_page.dart';
import 'package:bico_certo/pages/auth/auth_wrapper.dart';
import 'package:bico_certo/pages/profile/profile.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart'; 
import 'package:bico_certo/pages/order/order_page.dart';
import 'package:bico_certo/pages/create/create_info.dart';
import 'package:bico_certo/pages/create/create_form.dart';
import 'package:bico_certo/pages/auth/forgot_password_page.dart'; 
import 'package:bico_certo/pages/auth/reset_password_page.dart';

// NOVOS IMPORTS PARA AS PÁGINAS DE TRANSAÇÃO
import 'package:bico_certo/pages/wallet/send_page.dart';
import 'package:bico_certo/pages/wallet/receive_page.dart';

import 'package:flutter/material.dart';

// Import para importar wallet
import 'package.bico_certo/pages/wallet/import_wallet_page.dart';

// TESTAR PAGINA PROFILE SEM BACKEND
//import 'package:bico_certo/test/profile_teste.dart';

class AppRoutes {
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

  // NOVAS ROTAS PARA AS AÇÕES DE CARTEIRA
  static const String sendPage = '/send-money';
  static const String receivePage = '/receive-money';

  // NOVAS ROTAS PARA IMPORTAR WALLET
  static const String createWalletPage = '/create-wallet';
  static const String importWalletPage = '/import-wallet';


  static Map<String, Widget Function(BuildContext)> get routes => {
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
    
    // NOVAS ROTAS ADICIONADAS PARA CREATE WALLET
    sendPage: (context) => const SendPage(), 
    receivePage: (context) => const ReceivePage(),

    // novas rotas para import wallet
    createWalletPage: (context) => const CreateWalletPage(),
    importWalletPage: (context) => const ImportWalletPage(),
  };
}

*/
import 'package:bico_certo/pages/profile/dashboard.dart';
import 'package:bico_certo/pages/wallet/create_wallet_page.dart';
import 'package:bico_certo/pages/welcome_page.dart';
import 'package:bico_certo/pages/session_checker_page.dart';
import 'package:bico_certo/pages/auth/auth_wrapper.dart';
import 'package:bico_certo/pages/profile/profile.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart'; 
import 'package:bico_certo/pages/order/order_page.dart';
import 'package:bico_certo/pages/create/create_info.dart';
import 'package:bico_certo/pages/create/create_form.dart';
import 'package:bico_certo/pages/auth/forgot_password_page.dart'; 
import 'package:bico_certo/pages/auth/reset_password_page.dart';

// NOVOS IMPORTS PARA AS PÁGINAS DE TRANSAÇÃO
import 'package:bico_certo/pages/wallet/send_page.dart';
import 'package:bico_certo/pages/wallet/receive_page.dart';

// --- NOVO IMPORT PARA A PÁGINA DE IMPORTAÇÃO ---
import 'package:bico_certo/pages/wallet/import_wallet_page.dart'; 

import 'package:flutter/material.dart';

// TESTAR PAGINA PROFILE SEM BACKEND
//import 'package:bico_certo/test/profile_teste.dart';

class AppRoutes {
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
  
  // Rotas de Carteira
  static const String createWalletPage = '/create-wallet';
  static const String sendPage = '/send-money';
  static const String receivePage = '/receive-money';
  static const String importWalletPage = '/import-wallet'; // <<< NOVA ROTA


  static Map<String, Widget Function(BuildContext)> get routes => {
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
    
    // NOVAS ROTAS ADICIONADAS
    sendPage: (context) => const SendPage(), 
    receivePage: (context) => const ReceivePage(),
    importWalletPage: (context) => const ImportWalletPage(), // <<< NOVO MAPEAMENTO
  };
}