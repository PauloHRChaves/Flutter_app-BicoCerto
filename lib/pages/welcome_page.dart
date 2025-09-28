import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/local_storage_service.dart';
import 'package:bico_certo/widgets/wave_clipper.dart';

// POSSIVEIS MUDANÇAS

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    // Melhorar responsividade dos elementos - APENAS APLICADA NA "welcome_page" - AINDA EM TESTE
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset(
                'assets/images/image.png', 
                fit: BoxFit.fill,
              ),
          ),
          Positioned.fill(
            child: ClipPath(
              clipper: WaveClipper(),
              child: Container(
                color: const Color.fromARGB(255, 21, 107, 154),
              ),
            ),
          ),

          // Column para organizar os widgets verticalmente.
          Column(
            children: [
              // Espaço no topo para o logo (10% da altura da tela)
              SizedBox(height: screenHeight * 0.08),

              // Logo
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/icon_transparente.png',
                      height: screenHeight * 0.08, 
                    ),
                    // Espaço entre a imagem e o texto
                    SizedBox(width: screenWidth * 0.015),
                    Text(
                      'BICO CERTO',
                      style: TextStyle(
                        fontSize: screenWidth * 0.08, 
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),

              // Espaço entre o logo e o título
              SizedBox(height: screenHeight * 0.08), 
              
              // Título
              Center(
                child: Text(
                  'Qual serviço procura?!',
                  style: TextStyle(
                    fontSize: screenWidth * 0.07, 
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1774A3),
                  ),
                ),
              ),

              // Espaço entre o título e o subtítulo
              SizedBox(height: screenHeight * 0.01),
              
              // Subtítulo
              Center(
                child: Text(
                  'Encontre profissionais em\nsua localidade',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    color: const Color(0xFF339699),
                  ),
                ),
              ),
              
              // Espaço entre o subtítulo e a imagem principal
              SizedBox(height: screenHeight * 0.04), 
              
              // Imagem principal
              Center(
                child: Image.asset(
                  'assets/images/encanador_transparente.png',
                  // Altura da imagem principal proporcional à altura da tela
                  height: screenHeight * 0.35, 
                ),
              ),

              const Spacer(), // O spacer vai empurrar o botão para o final

              // Botão
              Center(
                child: SizedBox(
                  // Largura do botão proporcional à largura da tela
                  width: screenWidth * 0.5,
                  child: ElevatedButton(
                    onPressed: () => _continue(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A650),
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: EdgeInsets.symmetric(
                        // Padding do botão proporcional à altura da tela
                        vertical: screenHeight * 0.015,
                      ),
                    ),
                    child: Text(
                      'Próximo',
                      style: TextStyle(
                        // Tamanho da fonte do botão proporcional à largura da tela
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Espaço na parte inferior
              SizedBox(height: screenHeight * 0.08), 
            ],
          ),
        ],
      ),
    );
  }
}