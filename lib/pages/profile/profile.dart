import 'package:bico_certo/pages/dashboard/client_dashboard_page.dart';
import 'package:bico_certo/pages/profile/profile_tutorial_modal.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/services/auth_guard.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart';
import 'package:bico_certo/pages/wallet/create_wallet_page.dart';
import 'package:bico_certo/pages/profile/edit_profile_page.dart';
import '../dashboard/provider_dashboard_page.dart';
import '../../utils/string_formatter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _SetProfileState();
}

void _handleLogout(BuildContext context) async {
  final AuthService authService = AuthService();
  await authService.logout();
  if (!context.mounted) return;
  Navigator.pushNamed(context, AppRoutes.sessionCheck);
}

class _SetProfileState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _transactions = [];

  bool _isLoading = true;
  String _errorMessage = '';

  // Dados do Perfil (do /auth/me)
  String _fullName = '...';
  String _id = '...';
  String _city = '...';
  String _state = '...';
  String _description = '...';
  // URL de Imagem Padrão
  String _imgUrl =
      "https://img.freepik.com/vetores-premium/uma-silhueta-azul-do-rosto-de-uma-pessoa-contra-um-fundo-branco_754208-70.jpg?w=2000";

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  void _loadAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    String? profileError;

    try {
      final userData = await _authService.getUserProfile();
      if (!mounted) return;

      final userProfile = userData['user'];

      if (userProfile == null) {
        throw Exception("Objeto 'user' não encontrado na resposta da API.");
      }

      setState(() {
        _fullName = userProfile['full_name'] ?? 'Usuário';
        _city = userProfile['city'] ?? 'Cidade';
        _state = userProfile['state'] ?? '';
        _description = userProfile['description'] ?? 'Sem descrição.';
        _id = userProfile['id'] ?? '';

        if (userProfile['profile_pic_url'] != null) {
          _imgUrl = userProfile['profile_pic_url'];
        }
      });
    } catch (e) {
      profileError = 'Falha grave ao carregar o seu perfil.';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;

      if (profileError != null) {
        _errorMessage = profileError;
        _fullName = 'Erro';
      }
    });
  }

  void _checkAndNavigateToWallet() async {
    final details = await _authService.getWalletDetails();

    final bool walletExists =
        !(details.containsKey('has_wallet') && details['has_wallet'] == false);

    if (mounted) {
      if (walletExists) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const WalletPage()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Carteira não encontrada. Por favor, crie uma.'),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CreateWalletPage()),
        );
      }
    }
  }

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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    bool isHistoryLoading = true;
    const double avatarSize = 100.0;

    final double fonttitle = screenWidth * 0.044;
    final double font = screenWidth * 0.042;

    const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
    const Color lightBackground = Color.fromARGB(255, 230, 230, 230);
    const Color darkText = Color.fromARGB(255, 30, 30, 30);

    return AuthGuard(
      child: Scaffold(
        backgroundColor: lightBackground,
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 15, 73, 131),
          elevation: 1,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            "Meu Perfil",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              tooltip: 'Ajuda',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const ProfileTutorialModal(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              tooltip: 'Editar Perfil',
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditProfilePage(
                      currentName: _fullName,
                      currentCity: _city,
                      currentState: _state,
                      currentDescription: _description,
                      currentPicUrl: _imgUrl,
                      userId: _id,
                    ),
                  ),
                );

                if (result == true && mounted) {
                  _loadAllData();
                }
              },
            ),
          ],
        ),

        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
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
                        // Imagem do usuário
                        Container(
                          width: avatarSize,
                          height: avatarSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryBlue, width: 3),
                            color: Colors.black,
                            image: DecorationImage(
                              image: NetworkImage(_imgUrl),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),

                        Text(
                          _fullName, // Variável de state
                          style: TextStyle(
                            fontSize: fonttitle,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),

                        // city + state
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _city,
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
                              _state,
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: font,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.01),

                        Container(
                          padding: EdgeInsets.all(15),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: lightBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: Text(
                            _description,
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
                          onTap: _checkAndNavigateToWallet,
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.dashboard_outlined, // Ícone de Dashboard
                          label: "Dash Cliente",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ClientDashboardPage(),
                            ),
                          ),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.dashboard, // Ícone de Engrenagem
                          label: "Dash Provedor",
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ProviderDashboardPage(),
                            ),
                          ),
                        ),
                        _buildActionButton(
                          context: context,
                          icon: Icons.work_outline,
                          label: "Jobs",
                          onTap: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.ordersPage,
                              (route) => route.isFirst,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      "Deseja sair da conta?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(221, 36, 36, 36),
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleLogout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            250,
                            59,
                            59,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "LOGOUT",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
            } else if (index == 3) {}
          },
        ),
      ),
    );
  }
}
