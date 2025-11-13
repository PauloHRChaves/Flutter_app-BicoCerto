import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';

import '../../main.dart';
import '../../services/pending_rating_service.dart';

final Map<String, String> categoryMapping = {
  'Reformas': 'reformas',
  'Assistência Técnica': 'assistencia_tecnica',
  'Aulas Particulares': 'aulas_particulares',
  'Faxina': 'faxina',
  'Pintura': 'pintura',
  'Elétrica': 'eletrica'
};

// ----- Widget (Quadradinhos com as Categorias Populares.)
class CategoriaCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const CategoriaCard({
    super.key,
    required this.icon,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color.fromARGB(255, 241, 133, 9), size: 35),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

void _handleLogout(BuildContext context) async {
  final AuthService authService = AuthService();
  await authService.logout();
  if (!context.mounted) return;
  Navigator.pushNamed(context, AppRoutes.sessionCheck);
}

void _handleLogin(BuildContext context) {
  Navigator.pushNamed(context, AppRoutes.authWrapper);
}

class HomePage extends StatefulWidget {
  final bool isLoggedIn;

  const HomePage({super.key, required this.isLoggedIn});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 800), () async {
      if (mounted) {
        final hasPending = await PendingRatingService.hasPendingRating();
        if (hasPending && mounted) {
          showPendingRatingModal(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToJobsList(BuildContext context, String categoryDisplayName) {
    Navigator.pushNamed(
      context,
      AppRoutes.jobsList,
      arguments: {'category': categoryDisplayName},
    );
  }

  void _performSearch() {
    final searchTerm = _searchController.text.trim();

    Navigator.pushNamed(
      context,
      AppRoutes.jobsList,
      arguments: {'searchTerm': searchTerm},
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final double fontnormal = screenWidth * 0.04;
    final double fontbold = screenWidth * 0.05;
    final double title = screenWidth * 0.06;

    const Color darkBlue = Color.fromARGB(255, 22, 76, 110);
    const Color lightBlue = Color.fromARGB(255, 10, 94, 140);
    const Color accentBlue = Color.fromARGB(255, 74, 58, 255);
    const Color accentColor = Color.fromARGB(255, 255, 132, 0);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkBlue,
        title: const Text(
          "BICO CERTO",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            child: OutlinedButton(
              onPressed: () {
                if (widget.isLoggedIn) {
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
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                side: const BorderSide(color: Colors.white, width: 1),
              ),
              child: Text(
                widget.isLoggedIn ? 'Logout' : 'Login',
                style: TextStyle(
                  fontSize: screenWidth * 0.05,
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
            Container(
              height: screenHeight * 0.14,
              width: screenWidth,
              color: darkBlue,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.02,
              ),
              child: RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  text: 'Encontre o ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.08,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Profissional Ideal',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: screenWidth * 0.09,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' para o seu serviço !',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // =========================================================
            // CONTEÚDO PRINCIPAL

            // BARRA DE PESQUISA
            SizedBox(
              height: screenHeight * 0.23,
              width: screenWidth,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    'assets/images/searchbackground.png',
                    fit: BoxFit.cover,
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.05,
                        right: screenWidth * 0.05,
                        bottom: screenHeight * 0.01,
                      ),
                      child: TextField(
                        controller: _searchController,
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
                            horizontal: screenHeight * 0.015,
                          ),
                        ),
                        // Buscar ao pressionar Enter
                        onSubmitted: (_) => _performSearch(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.01),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: screenWidth,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentBlue,
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.01,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),

                      // AGORA IMPLEMENTADO - Buscar ao clicar
                      onPressed: _performSearch,

                      child: Text(
                        "Buscar Serviço",
                        style: TextStyle(
                          fontSize: fontbold,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Texto de Categorias Populares
                  Text(
                    "Categorias Populares: ",
                    style: TextStyle(
                      fontSize: title,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Categorias GridView
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      CategoriaCard(
                        icon: Icons.build,
                        text: "Reformas",
                        onTap: () => _navigateToJobsList(context, "Reformas"),
                      ),
                      CategoriaCard(
                        icon: Icons.electrical_services,
                        text: "Assistência Técnica",
                        onTap: () => _navigateToJobsList(context, "Assistência Técnica"),
                      ),
                      CategoriaCard(
                        icon: Icons.book,
                        text: "Aulas Particulares",
                        onTap: () => _navigateToJobsList(context, "Aulas Particulares"),
                      ),
                      CategoriaCard(
                        icon: Icons.design_services,
                        text: "Design",
                        onTap: () => _navigateToJobsList(context, "Design"),
                      ),
                      CategoriaCard(
                        icon: Icons.show_chart,
                        text: "Pintura",
                        onTap: () => _navigateToJobsList(context, "Pintura"),
                      ),
                      CategoriaCard(
                        icon: Icons.electric_bolt,
                        text: "Faxina",
                        onTap: () => _navigateToJobsList(context, "Faxina"),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            ),

            // Banner para de chamada para cadastro como Profissional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 68, 52, 195),
                    Color.fromARGB(255, 127, 79, 224),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "É Profissional?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: title,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  Text(
                    "Cadastre-se, busque e receba orçamentos de novos clientes.",
                    style: TextStyle(fontSize: fontnormal, color: Colors.white),
                  ),

                  SizedBox(height: screenHeight * 0.01),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: accentBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {},
                    child: Text(
                      "Cadastrar agora",
                      style: TextStyle(
                        fontSize: fontnormal,
                        fontWeight: FontWeight.w600,
                      ),
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
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.sessionCheck,
                  (route) => route.isFirst,
            );
          } else if (index == 1) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.ordersPage,
                  (route) => route.isFirst,
            );
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.chatRoomsPage,
                  (route) => route.isFirst,
            );
          } else if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.profilePage,
                  (route) => route.isFirst,
            );
          }
        },
      ),
    );
  }
}