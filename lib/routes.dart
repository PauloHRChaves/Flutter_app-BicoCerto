import 'package:flutter/material.dart';
import 'package:bico_certo/pages/welcome_page.dart';
import 'package:bico_certo/pages/session_checker_page.dart';
import 'package:bico_certo/pages/auth/auth_wrapper.dart';
import 'package:bico_certo/pages/profile/profile.dart';

// TESTAR PAGINA PROFILE SEM BACKEND
import 'package:bico_certo/test/profile_teste.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String sessionCheck = '/check';
  static const String authWrapper = '/auth';
  static const String setProfile = '/profile';
  static const String teste = '/teste';

  static Map<String, Widget Function(BuildContext)> get routes => {
    welcome: (context) => const WelcomePage(),
    sessionCheck: (context) => const SessionCheckerPage(),
    authWrapper: (context) => const AuthWrapper(),
    setProfile: (context) => const SetProfile(),
    
    // TESTAR PAGINA SEM BACKEND
    teste: (context) => const Testing()
  };
}
