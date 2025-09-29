// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart'; 
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/widgets/category_cards.dart'; 
import 'package:bico_certo/widgets/bottom_navbar.dart'; 

// IMPORTS ABSOLUTOS (usando o nome do seu projeto como base do pacote)
import 'package:bico_certo/pages/auth/auth_wrapper.dart'; // Importa AuthWrapper
import 'package:bico_certo/pages/profile/profile.dart'; // Importa SetProfile


class HomePage extends StatelessWidget {
  final bool isLoggedIn;

  const HomePage({super.key, required this.isLoggedIn});

  // Função para lidar com o logout e navegação (USANDO ROTA NOMEADA)
  void _handleLogout(BuildContext context) async {
    final AuthService authService = AuthService();
    await authService.logout();

    if (!context.mounted) return;

    // Navega para a rota de checagem de sessão (AppRoutes.sessionCheck)
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.sessionCheck, 
    );
  }

  // Função para lidar com o Login/Navegação (USANDO ROTA NOMEADA)
  void _handleLogin(BuildContext context) {
    // Navega para a rota do AuthWrapper
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.authWrapper,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definindo cores para facilitar a leitura
    const Color darkBlue = Color.fromARGB(255, 22, 76, 110);
    const Color lightBlue = Color.fromARGB(255, 10, 94, 140);
    const Color accentColor = Color.fromARGB(255, 255, 132, 0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkBlue,
        title: const Text(
          "BICO CERTO",
          style: TextStyle(
            color: Color.fromARGB(255, 37, 143, 230),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Botão condicional de Login/Logout
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: OutlinedButton(
              onPressed: () {
                if (isLoggedIn) {
                  _handleLogout(context);
                } else {
                  _handleLogin(context);
                }
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: lightBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                side: const BorderSide(
                  color: Color.fromARGB(255, 255, 255, 255),
                  width: 1.5,
                ),
              ),
              child: Text(
                isLoggedIn ? 'Logout' : 'Login',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================================
            Container(
              width: double.infinity,
              color: darkBlue,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  text: 'Encontre o ', // texto normal
                  style: const TextStyle(
                    color: Colors.white, // Corrigido para branco
                    fontSize: 32,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Profissional Ideal',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: ' para o seu serviço !',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // CONTEÚDO PRINCIPAL

            //- BARRA DE PESQUISA
            SizedBox(
              height: 250,
              width: MediaQuery.of(context).size.width,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    'assets/images/searchbackground.png',
                    fit: BoxFit.cover,
                  ),

                  // 2. O Conteúdo: Barra de Pesquisa posicionada
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: 20.0,
                        right: 20.0,
                        bottom: 30.0,
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: "Qual serviço você procura?",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(30)),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botão de Busca.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A3AFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Buscar Serviço",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Texto de Categorias Populares
                  const Text(
                    "Categorias Populares",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Categorias (Grid)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      // Corrigido para usar a classe CategoriaCard novamente
                      CategoriaCard(icon: Icons.build, text: "Reformas"),
                      CategoriaCard(
                        icon: Icons.electrical_services,
                        text: "Assistência Técnica",
                      ),
                      CategoriaCard(
                        icon: Icons.book,
                        text: "Aulas Particulares",
                      ),
                      CategoriaCard(
                        icon: Icons.design_services,
                        text: "Design",
                      ),
                      CategoriaCard(
                        icon: Icons.show_chart,
                        text: "Consultoria",
                      ),
                      CategoriaCard(
                        icon: Icons.electric_bolt,
                        text: "Elétrica",
                      ),
                      CategoriaCard(
                        icon: Icons.design_services,
                        text: "Example 1",
                      ),
                      CategoriaCard(
                        icon: Icons.design_services,
                        text: "Example 2",
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Banner para de chamada para cadastro como Profissional - Apenas para Client
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A5AE0), Color(0xFF9D6CFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "É Profissional?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    "Cadastre-se, busque e receba orçamentos de novos clientes.",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(211, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 12),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A3AFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    // Leva para a tela de Login/Cadastro
                    onPressed: () {
                      _handleLogin(context);
                    },
                    child: const Text(
                      "Cadastrar agora",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            // Se já estiver na Home, não faz nada
          } else if (index == 1) {
            // Lógica para 'Pedidos'
            // Adicione sua navegação aqui
          } else if (index == 2) {
            // Navega para o perfil
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SetProfile()), 
            );
          }
        },
      ),
    );
  }
}