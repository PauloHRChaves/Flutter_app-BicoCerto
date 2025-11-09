// ⚠️ ESTA PAGINA DEVE SER VISIVEL APENAS PELO DONO DA MESMA ⚠️

import 'package:bico_certo/pages/dashboard/client_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/services/auth_guard.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart';
import 'package:bico_certo/pages/wallet/create_wallet_page.dart';

import '../dashboard/provider_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _SetProfileState();
}

class _SetProfileState extends State<ProfilePage> {
  //Lógica de navegação e checagem da Wallet
  final AuthService _authService = AuthService();

  // GET ME
  String _fullName = '...'; 
  @override
  void initState() {
    super.initState();
    _loadUserData(); 
  }

  void _loadUserData() async {
    try {
      final userData = await _authService.getUserProfile();

      if (userData.containsKey('full_name') && userData['full_name'] != null) {
        setState(() {
          _fullName = userData['full_name'];
        });
      } else {
         setState(() {
          _fullName = 'Usuário'; 
        });
      }
    } catch (e) {
      
      print('Erro ao buscar dados do usuário: $e');
      setState(() {
        _fullName = 'Erro ao carregar';
      });
    }
  }

  //Lógica de navegação e checagem da Wallet
  void _checkAndNavigateToWallet() async {
    final details = await _authService.getWalletDetails();

    final bool walletExists =
        !(details.containsKey('has_wallet') && details['has_wallet'] == false);

    if (mounted) {
      if (walletExists) {
        // Carteira existe ou os detalhes vieram
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const WalletPage()));
      } else {
        // Carteira não existe (o retorno foi {'has_wallet': false})
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Carteira não encontrada. Por favor, crie uma.')),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CreateWalletPage()),
        );
      }
    }
  }

  // jobdone
  Widget _buildStatCard({
    required String title,
    required int value,
    required Color color,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double minimalfont = screenWidth * 0.034;

    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey, spreadRadius: 1, blurRadius: 3),
          ],
        ),
        child: Column(
          children: [
            Text(
              value.toString().padLeft(2, '0'),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: minimalfont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // estrelas
  Widget _buildStarCard({
    required String title,
    required double value,
    required Color color,
    bool isRating = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double minimalfont = screenWidth * 0.034;

    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.grey, spreadRadius: 1, blurRadius: 3),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 5; i++)
                  Icon(
                    i < (value) ? Icons.star : Icons.star_border,
                    color: color,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black54,
                fontSize: minimalfont,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // funções horizontais
  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
    const Color activeBlue = Color.fromARGB(255, 5, 84, 130);

    bool isPressed = false;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Container(
          color: Colors.white, // fundo fixo branco
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  splashColor: activeBlue.withValues(alpha: 0.15),
                  onTapDown: (_) => setLocalState(() => isPressed = true),
                  onTapCancel: () => setLocalState(() => isPressed = false),
                  onTapUp: (_) async {
                    await Future.delayed(const Duration(milliseconds: 150));
                    setLocalState(() => isPressed = false);
                  },
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryBlue, width: 3),
                      color: isPressed
                          ? const Color.fromARGB(157, 204, 235, 252)
                          : Colors.white,
                    ),
                    child: Icon(icon, color: primaryBlue, size: 28),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: TextStyle(
                  fontSize: 12,
                  color: isPressed
                      ? const Color.fromARGB(255, 51, 150, 207)
                      : const Color.fromARGB(255, 33, 33, 33),
                  fontWeight: isPressed ? FontWeight.bold : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    
    // os dados tem que ser da api não estaticos
    final String id = '123456789';
    final String cidade = 'CIDADE';
    final String estado = 'ESTADO';
    final String description =
        'descrição';

    final int jobdone = 0;
    final double estrelas = 2;

    final img =
        "https://img.freepik.com/vetores-premium/uma-silhueta-azul-do-rosto-de-uma-pessoa-contra-um-fundo-branco_754208-70.jpg?w=2000";

    // Responsividade
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    const double avatarSize = 100.0;

    final double fonttitle = screenWidth * 0.044;
    final double font = screenWidth * 0.042;

    const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
    const Color lightBackground = Color.fromARGB(255, 230, 230, 230);
    const Color darkText = Color.fromARGB(255, 30, 30, 30);

    // FIX SEGURANÇA: AuthGuard envolve todo o conteúdo do Scaffold
    return AuthGuard(
        child: Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 15, 73, 131),
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color.fromARGB(255, 255, 255, 255)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Meu Perfil",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),

            // ⚠️ LOGICA NÃO APLICADA
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 10),
        children: [
          SizedBox(height: screenHeight * 0.01),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⚠️ IMAGEM ENVIADA PELO USUÁRIO
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryBlue, width: 3),
                    color: Colors.black,
                    image: DecorationImage(
                      image: NetworkImage(
                        img,
                      ),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                // --- 🔽 NOME DE USUÁRIO ATUALIZADO 🔽 ---
                Text(
                  _fullName, // Mostra "...", depois o nome, ou um erro.
                  style: TextStyle(
                    fontSize: fonttitle,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),

                // ⚠️ ->  id
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "ID: ",
                      style: TextStyle(fontSize: font, color: Colors.grey),
                    ),
                    Text(
                      id,
                      style: TextStyle(color: Colors.grey, fontSize: font),
                    ),
                  ],
                ),

                // ⚠️ -> Cidade + Estado
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cidade,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: font,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      ' - ',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: font,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      estado,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: font,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),

                // Cartão de Descrição
                Container(
                  padding: EdgeInsets.all(15),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: lightBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),

                  // ⚠️ -> Descrição
                  child: Text(
                    description,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: darkText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.005),

          // --- Seção de Estatísticas (Trabalhos Concluídos e Avaliações) ---
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _buildStatCard(
                  title: "Trabalhos Concluídos",
                  // ⚠️ ->  Job Done
                  value: jobdone,
                  color: primaryBlue,
                ),
                const SizedBox(width: 10),
                _buildStarCard(
                  title: "Média de Avaliações",
                  // ⚠️ ->  Estrelas
                  value: estrelas,
                  color: Colors.amber,
                  isRating: true,
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.005),

          // --- Barra de Navegação de Ícones (Funcionalidades) ---
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Carteira",
                    onTap: _checkAndNavigateToWallet),
                _buildActionButton(
                  context: context,
                  icon: Icons.dashboard_outlined, // Ícone de Dashboard
                  label: "Dashboard",
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ClientDashboardPage(), // Mantido, pois parece ser a tela de Dashboard
                    ),
                  ),
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.settings_outlined, // Ícone de Engrenagem
                  label: "Configurações",
                  onTap: () {
                    // TODO: Navegar para a página de Configurações
                  },
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.work_outline, // Ícone de Jobs (Maleta)
                  label: "Jobs",
                  onTap: () {
                    // TODO: Navegar para a página de Jobs (ex: JobsListPage)
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 3,
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
            /*
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profilePage, 
              (route) => route.isFirst,
            );*/
          }
        },
      ),
    ));
  }
}