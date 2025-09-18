import 'package:flutter/material.dart';

// HOMEPAGE - PAGINA PRINCIPAL DO PROJETO - HAVERÁ MUDANÇAS

class HomePage extends StatelessWidget {
    final bool isLoggedIn;
  
  const HomePage({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bico Certo'),
        actions: [
          // Exibe o botão de login apenas ao user deslogado
          if (!isLoggedIn) 
            TextButton(
                onPressed: () {
                  // Navega para a tela de login (AuthWrapper)
                  Navigator.pushNamed(context, '/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00A650),
                ),
                child: const Text('Login', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
            ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const Text('Bem-vindo à Home Page!', style: TextStyle(fontSize: 24)),
            // conteúdo limitado = deslogado
            if (!isLoggedIn)
              const Text('Você está no modo de visualização. Faça login !'),
            // conteúdo total = logado
            if (isLoggedIn)
              const Text('Conteúdo exclusivo para usuários logados aqui!'),
          ],
        ),
      ),
    );
  }
}