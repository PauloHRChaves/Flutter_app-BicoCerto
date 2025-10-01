import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/local_storage_service.dart';
import 'package:bico_certo/widgets/wave_clipper.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _contentController = PageController();
  final PageController _backgroundController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pagesData = [
    {
      'title': 'Qual serviço procura?!',
      'subtitle': 'Encontre profissionais em sua localidade',
      'illustration_image': 'assets/images/encanador_transparente.png',
      'background_image': 'assets/images/back1.png',
    },
    {
      'title': 'Conexão Rápida',
      'subtitle': 'Converse diretamente com o profissional',
      'illustration_image': 'assets/images/pedreiro_transparente.png',
      'background_image': 'assets/images/back2.png',
    },
    {
      'title': 'Contrate com Segurança',
      'subtitle':
          'Veja avaliações, perfis e garanta o melhor serviço para você',
      'illustration_image': 'assets/images/costureira_transparente.png',
      'background_image': 'assets/images/back3.png',
    },
    {
      'title': 'Pronto para Começar?!',
      'subtitle': 'Cadastre-se já',
      'illustration_image': 'assets/images/handshake.png',
      'background_image': 'assets/images/back.png',
    },
  ];

  // Ação para ir para a próxima página
  void _nextPage() {
    if (_currentPage < _pagesData.length - 1) {
      _contentController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      _backgroundController.nextPage(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // Ação final para sair da WelcomePage
  Future<void> _continue(BuildContext context) async {
    await LocalStorageService.setIsFirstTime(false);

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.sessionCheck,
        (Route<dynamic> route) => false,
      );
    }
  }

  Widget _buildPageContent(
    Map<String, String> pageData,
    double screenHeight,
    double screenWidth,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.24),

          // Título
          Center(
            child: Text(
              pageData['title']!,
              style: TextStyle(
                fontSize: screenWidth * 0.07,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1774A3),
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.01),

          // Subtítulo
          Center(
            child: Text(
              pageData['subtitle']!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w800,
                height: 1.05,
                color: const Color(0xFF339699),
              ),
            ),
          ),

          Expanded(
            flex: 6,
            child: Center(
              child: Image.asset(
                pageData['illustration_image']!,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Lógica do botão
    final bool isLastPage = _currentPage == _pagesData.length - 1;
    final String buttonText = isLastPage ? 'Continuar' : 'Próximo';
    final VoidCallback buttonAction = isLastPage ? () => _continue(context) : _nextPage;

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _backgroundController,
            itemCount: _pagesData.length,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Image.asset(
                  _pagesData[index]['background_image']!,
                  fit: BoxFit.fill,
                ),
              );
            },
          ),

          // FUNDO - Wave_clipper
          Positioned.fill(
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(color: const Color.fromARGB(255, 21, 107, 154)),
            ),
          ),

          // CONTEÚDO (Texto e Ilustrações)
          PageView.builder(
            controller: _contentController,
            itemCount: _pagesData.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
              // Sincroniza o PageView de fundo ao deslizar
              _backgroundController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );
            },
            itemBuilder: (context, index) {
              return _buildPageContent(
                _pagesData[index],
                screenHeight,
                screenWidth,
              );
            },
          ),

          // ELEMENTOS FIXOS NO TOPO
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.08),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/icon_transparente.png',
                    height: screenHeight * 0.08,
                  ),
                  SizedBox(width: screenWidth * 0.015),
                  Flexible(
                    child: Text(
                      'BICO CERTO',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ELEMENTOS FIXOS NO RODAPÉ
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: screenHeight * 0.08),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pagesData.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.01,
                        ),
                        height: screenHeight * 0.012,
                        width: _currentPage == index
                            ? screenWidth * 0.05
                            : screenWidth * 0.025,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF00A650)
                              : Colors.white54,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      );
                    }),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  SizedBox(
                    width: screenWidth * 0.5,
                    child: ElevatedButton(
                      onPressed: buttonAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00A650),
                        foregroundColor: const Color(0xFFFFFFFF),
                        padding: EdgeInsets.symmetric(
                          vertical: screenHeight * 0.015,
                        ),
                      ),
                      child: Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
