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
import 'package:bico_certo/pages/wallet/wallet_page.dart';
import 'package:bico_certo/pages/wallet/create_wallet_page.dart';
import 'package:bico_certo/pages/wallet/import_wallet_page.dart';
// IMPORTS PARA AS PÁGINAS DE TRANSAÇÃO
import 'package:bico_certo/pages/wallet/send_page.dart';
import 'package:bico_certo/pages/wallet/receive_page.dart';
// JOBS
import 'package:bico_certo/pages/order/order_page.dart';
import 'package:bico_certo/pages/create/create_info.dart';
import 'package:bico_certo/pages/create/create_form.dart';
import 'package:bico_certo/pages/chat/chat_rooms_page.dart';
import 'package:bico_certo/pages/chat/chat_page.dart';
import 'package:bico_certo/pages/jobs_list_page.dart';

class AppRoutes {
  // Rotas Essenciais
  static const String welcome = '/';

  // Rotas Principais
  static const String profilePage = '/profile';
  static const String ordersPage = '/orders';
  static const String dashboardPage = '/dashboard';

  // Rotas de Serviço
  static const String orderInfoPage = '/order_info';
  static const String createFormPage = '/order_form';

  // Rotas de Autenticação
  static const String sessionCheck = '/check';
  static const String authWrapper = '/auth';
  static const String forgotPasswordPage = '/forgot-password';
  static const String resetPasswordPage = '/reset-password';

  static const String chatRoomsPage = '/chat_rooms';
  static const String chatPage = '/chat';

  // NOVAS ROTAS PARA AS AÇÕES DE CARTEIRA
  static const String sendPage = '/send-money';
  static const String receivePage = '/receive-money';

  // ROTAS PARA WALLET
  static const String walletPage = '/wallet';
  static const String createWalletPage = '/create-wallet';
  static const String importWalletPage = '/import-wallet';

  // ROTA PARA LISTAGEM DE JOBS
  static const String jobsList = '/jobs-list';

  static Map<String, Widget Function(BuildContext)> get routes => {
    // Rotas Essenciais
    welcome: (context) => const WelcomePage(),
    sessionCheck: (context) => const SessionCheckerPage(),
    authWrapper: (context) => const AuthWrapper(),

    // Rotas de Páginas
    profilePage: (context) => const ProfilePage(),
    ordersPage: (context) => const OrdersPage(),
    dashboardPage: (context) => const DashboardScreen(),

    // Rotas de Serviço
    orderInfoPage: (context) => const OrderInfoPage(),
    createFormPage: (context) => const CreateJobPage(),
    forgotPasswordPage: (context) => const ForgotPasswordPage(),
    resetPasswordPage: (context) => const ResetPasswordPage(),

    // Rotas WALLET
    createWalletPage: (context) => const CreateWalletPage(),
    importWalletPage: (context) => const ImportWalletPage(),
    walletPage: (context) => const WalletPage(),
    sendPage: (context) => const SendPage(),
    receivePage: (context) => const ReceivePage(),

    chatRoomsPage: (context) => const ChatRoomsScreen(),
    chatPage: (context) => const ChatPage(),
  };

  // Método para rotas dinâmicas (que precisam de argumentos)
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case jobsList:
        final args = settings.arguments as Map<String, dynamic>?;

        return MaterialPageRoute(
          builder: (_) => JobsListPage(
            category: args?['category'],
            searchTerm: args?['searchTerm'],
          ),
          settings: settings,
        );

      case chatPage:
        final args = settings.arguments;
        if (args != null) {
          return MaterialPageRoute(
            builder: (_) => const ChatPage(),
            settings: settings,
          );
        }
        return null;

      default:
        return null;
    }
  }
}