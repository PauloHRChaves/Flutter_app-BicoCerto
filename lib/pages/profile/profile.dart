// ⚠️ ESTA PAGINA DEVE SER VISIVEL APENAS PELO DONO DA MESMA ⚠️

import 'package:bico_certo/pages/dashboard/client_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/services/auth_guard.dart';
import 'package:bico_certo/pages/wallet/wallet_page.dart';
import 'package:bico_certo/pages/wallet/create_wallet_page.dart';
import 'package:bico_certo/pages/profile/edit_profile_page.dart';
import '../dashboard/provider_dashboard_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _SetProfileState();
}

class _SetProfileState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  bool _isLoading = true;
  String _errorMessage = '';

  // Dados do Perfil (do /auth/me)
  String _id = '...';
  String _fullName = '...';
  String _city = '...';
  String _state = '...';
  String _description = '...';
  // URL de Imagem Padrão
  String _imgUrl =
      "https://img.freepik.com/vetores-premium/uma-silhueta-azul-do-rosto-de-uma-pessoa-contra-um-fundo-branco_754208-70.jpg?w=2000";

  // Dados de Stats (do /provider/dashboard/quick-stats)
  int _jobdone = 0;
  double _estrelas = 0.0;

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
    String? statsError;

    try {
      final userData = await _authService.getUserProfile();
      if (!mounted) return;

      
      final userProfile = userData['user'];

      if (userProfile == null) {
        throw Exception("Objeto 'user' não encontrado na resposta da API.");
      }

    
      setState(() {
        _fullName = userProfile['full_name'] ?? 'Usuário';
        _id = userProfile['id'] ?? '...';
        _city = userProfile['city'] ?? 'Cidade'; 
        _state = userProfile['state'] ?? ''; 
        _description = userProfile['description'] ?? 'Sem descrição.';
        
        if (userProfile['profile_pic_url'] != null) {
          _imgUrl = userProfile['profile_pic_url'];
        }
      });
    } catch (e) {
      profileError = 'Falha grave ao carregar o seu perfil.';
      print('Erro em getUserProfile: $e');
    }

    try {
      final statsData = await _authService.getProviderQuickStats();
      if (!mounted) return;

      setState(() {
        _jobdone = (statsData['completedJobs'] as num?)?.toInt() ?? 0;
        _estrelas = (statsData['rating'] as num?)?.toDouble() ?? 0.0;
      });
    } catch (e) {
      statsError = 'Falha ao carregar estatísticas (carteira pode não existir).';
      print('Erro em getProviderQuickStats: $e');
      
      setState(() {
        _jobdone = 0;
        _estrelas = 0.0;
      });
    }

    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      
      if (profileError != null) {
        _errorMessage = profileError;
        _fullName = 'Erro';
      } else if (statsError != null) {
        
        print(statsError); 
      }
    });
  }

  
  void _checkAndNavigateToWallet() async {
    
    final details = await _authService.getWalletDetails();

    final bool walletExists =
        !(details.containsKey('has_wallet') && details['has_wallet'] == false);

    if (mounted) {
      if (walletExists) {
        
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const WalletPage()));
      } else {
        
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
              Icons.edit_outlined, 
              color: Colors.white,
            ),
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
                                // ⚠️ ATUALIZADO: Vem da variável de state _state
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
                              onTap: _checkAndNavigateToWallet),
                          _buildActionButton(
                            context: context,
                            icon: Icons.dashboard_outlined, // Ícone de Dashboard
                            label: "Dashboard Cliente",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ClientDashboardPage(), 
                              ),
                            ),
                          ),
                          _buildActionButton(
                            context: context,
                            icon: Icons.dashboard, // Ícone de Engrenagem
                            label: "Dashboard Provider",
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
           
          }
        },
      ),
    ));
  }
}