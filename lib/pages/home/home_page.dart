import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';
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

const Color kPrimaryBlue = Color.fromARGB(255, 12, 120, 200);
const Color kHeaderBlueDark = Color.fromARGB(255, 22, 76, 110);
const Color kLogoutButtonColor = Color.fromARGB(255, 10, 94, 140);
const Color kHowItWorksIconBg = Color.fromARGB(255, 230, 240, 250);

// =========================================================================
// WIDGETS AUXILIARES (Passos, Benefícios e Ilustração)
// =========================================================================

class CustomIllustration extends StatelessWidget {
  const CustomIllustration({super.key});
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/hpimg1.png',
      fit: BoxFit.contain,
      height: 200,
      width: double.infinity,
    );
  }
}

class IconCategory extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const IconCategory({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        children: [
          // O círculo colorido com o ícone
          GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 30,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 5),
          // O texto da categoria
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// WIDGET PARA OS PASSOS "COMO FUNCIONA?"
class HowItWorksStep extends StatelessWidget {
  final IconData icon;
  final String title;

  const HowItWorksStep({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 216, 235, 255),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: kPrimaryBlue, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// WIDGET PARA OS BENEFÍCIOS "POR QUE ESCOLHER?"
class BenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const BenefitItem({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: kPrimaryBlue, size: 24),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// void _handleLogout(BuildContext context) async {
//   final AuthService authService = AuthService();
//   await authService.logout();
//   if (!context.mounted) return;
//   Navigator.pushNamed(context, AppRoutes.sessionCheck);
// }

// void _handleLogin(BuildContext context) {
//   Navigator.pushNamed(context, AppRoutes.authWrapper);
// }

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

  void _createJob() {
    Navigator.pushNamed(context, AppRoutes.createFormPage);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final double fontbold = screenWidth * 0.05;

    const Color darkBlue = Color.fromARGB(255, 22, 76, 110);

    const Color kPrimaryBlue = Color.fromARGB(255, 12, 120, 200);
    const Color kIconBlue = Color.fromARGB(255, 12, 120, 200);
    const Color kIconOrange = Color.fromARGB(255, 255, 132, 0);

    return Scaffold(
      backgroundColor: darkBlue,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkBlue,
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "BICO CERTO",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                color: darkBlue,
                padding: EdgeInsets.all(10),
                child: Text.rich(
                  TextSpan(
                    // Estilo base aplicado a todo o TextSpan, a menos que seja sobrescrito
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(
                        255,
                        225,
                        225,
                        225,
                      ), // Cor padrão (cinza claro)
                    ),
                    children: const <TextSpan>[
                      TextSpan(text: 'Quem '),

                      TextSpan(
                        text: 'PRECISA ',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 149, 1),
                        ),
                      ),

                      TextSpan(text: 'encontra quem '),

                      TextSpan(
                        text: 'FAZ',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 149, 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Imagem
            Container(
              width: screenWidth,
              height: 210,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Center(child: CustomIllustration()),
            ),

            // Barra de pesquisa
            Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 5),
                    child: Container(
                      width: screenWidth,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: darkBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 0,
                    left: screenWidth * 0.05,
                    right: screenWidth * 0.05,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Qual serviço deseja realizar?",
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            // borderSide: BorderSide.none,
                            borderSide: BorderSide(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),

                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conteudo main
            Container(
              padding: EdgeInsetsDirectional.symmetric(horizontal: 5),
              color: const Color.fromARGB(255, 244, 255, 255),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: darkBlue,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: SizedBox(
                            width: screenWidth,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                padding: EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(30),
                                  ),
                                ),
                              ),

                              onPressed: _performSearch,

                              child: Text(
                                "Buscar",
                                style: TextStyle(
                                  fontSize: fontbold,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),
                      ],
                    ),
                  ),

                  if (!widget.isLoggedIn)
                    Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(183, 216, 240, 253),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Faça Login para ter total acesso ao App !',
                            style: TextStyle(
                              fontSize: 18,
                              color: const Color.fromARGB(186, 39, 39, 39),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                    
                  // Categorias
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(10),
                          ),
                        ),
                        height: 115,
                        child: Padding(
                          padding: EdgeInsetsGeometry.symmetric(horizontal: 0),
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            // padding: const EdgeInsets.symmetric(
                            //   horizontal: 10.0,
                            // ),
                            children: [
                              IconCategory(
                                icon: Icons.plumbing,
                                text: "Encanador",
                                color: const Color.fromARGB(255, 49, 157, 219),
                                onTap: () =>
                                    _navigateToJobsList(context, "Encanador"),
                              ),
                              IconCategory(
                                icon: Icons.build,
                                text: "Pedreiro",
                                color: const Color.fromARGB(255, 64, 64, 64),
                                onTap: () =>
                                    _navigateToJobsList(context, "Pedreiro"),
                              ),
                              IconCategory(
                                icon: Icons.lightbulb_outline,
                                text: "Eletricista",
                                color: Colors.green, // Cor diferente
                                onTap: () =>
                                    _navigateToJobsList(context, "Elétrica"),
                              ),
                              IconCategory(
                                icon: Icons.cleaning_services,
                                text: "Diarista",
                                color: kIconBlue,
                                onTap: () =>
                                    _navigateToJobsList(context, "Faxina"),
                              ),
                              IconCategory(
                                icon: Icons.chair,
                                text: "Montador",
                                color: kIconOrange,
                                onTap: () =>
                                    _navigateToJobsList(context, "Montador"),
                              ),
                              IconCategory(
                                icon: Icons.brush,
                                text: "Pintor",
                                color: Colors.red, // Cor diferente
                                onTap: () =>
                                    _navigateToJobsList(context, "Pintura"),
                              ),
                              IconCategory(
                                icon: Icons.spa,
                                text: "Manicure",
                                color: const Color.fromARGB(
                                  255,
                                  177,
                                  54,
                                  244,
                                ), // Cor diferente
                                onTap: () =>
                                    _navigateToJobsList(context, "Manicure"),
                              ),
                              IconCategory(
                                icon: Icons.local_florist,
                                text: "Jardineiro",
                                color: const Color.fromARGB(
                                  255,
                                  21,
                                  131,
                                  69,
                                ), // Cor diferente
                                onTap: () =>
                                    _navigateToJobsList(context, "Jardineiro"),
                              ),
                              IconCategory(
                                icon: Icons.carpenter,
                                text: "Marceneiro",
                                color: const Color.fromARGB(
                                  255,
                                  132,
                                  74,
                                  7,
                                ), // Cor diferente
                                onTap: () =>
                                    _navigateToJobsList(context, "Marceneiro"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Precisa de mão de obra?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(221, 36, 36, 36),
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _createJob,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "CRIE UMA REQUISIÇÃO DE SERVIÇO",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Prestador
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: darkBlue,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Para você Prestador de Serviço:",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(221, 255, 255, 255),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            HowItWorksStep(
                              icon: Icons.search,
                              title: "Procure pelo Serviço Ideal",
                            ),

                            SizedBox(width: 5),

                            HowItWorksStep(
                              icon: Icons.handshake_outlined,
                              title: "Faça uma Proposta",
                            ),

                            SizedBox(width: 5),

                            HowItWorksStep(
                              icon: Icons.monetization_on_outlined,
                              title: "Finalize o Trabalho",
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Provedor
                  Container(
                    decoration: BoxDecoration(
                      color: darkBlue,
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Para você Provedor de Serviço:",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color.fromARGB(221, 255, 255, 255),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              HowItWorksStep(
                                icon: Icons.create_outlined,
                                title: "Crie um Serviço",
                              ),

                              SizedBox(width: 5),

                              HowItWorksStep(
                                icon: Icons.content_paste_search,
                                title: "Analise as Propostas",
                              ),

                              SizedBox(width: 5),

                              HowItWorksStep(
                                icon: Icons.check_circle_outlined,
                                title: "Finalize e Avalie o Serviço",
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.08),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 255, 255, 255),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(30),
                        ),
                        border: Border.all(width: 1, color: darkBlue),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "POR QUE ESCOLHER O BICO CERTO?",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 15),
                          const BenefitItem(
                            icon: Icons.verified_outlined,
                            text: "Profissionais Capacitados",
                          ),
                          const BenefitItem(
                            icon: Icons.shield_outlined,
                            text: "Segurança Garantida",
                          ),
                          const BenefitItem(
                            icon: Icons.timelapse,
                            text: "Prático, Justo e Transparente",
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Implementação da navegação (usando MOCK Routes)
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
