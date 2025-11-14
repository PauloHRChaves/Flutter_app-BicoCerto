import 'package:flutter/material.dart';

class WalletTutorialModal extends StatefulWidget {
  const WalletTutorialModal({super.key});

  @override
  State<WalletTutorialModal> createState() => _WalletTutorialModalState();
}

class _WalletTutorialModalState extends State<WalletTutorialModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'title': 'Criar Carteira',
      'icon': Icons.add_card,
      'color': Colors.blue,
      'description':
          '1. Digite a senha da sua conta.\n2. Toque em "Criar Nova Carteira".\n\nSua carteira será gerada automaticamente e protegida pela sua senha.',
    },
    {
      'title': 'Importar Carteira',
      'icon': Icons.download_rounded,
      'color': Colors.orange,
      'description':
          'Já tem uma carteira?\n\n1. Toque em "Importar Carteira Existente".\n2. Cole sua Chave Privada.\n3. Digite sua senha.',
    },
    {
      'title': 'Exclusão da Carteira',
      'icon': Icons.security,
      'color': Colors.red,
      'description':
          '⚠️ CUIDADO: Se você excluir a carteira sem ter um copia da Chave Privada, perderá seu saldo para sempre.\n\nPara excluir, va na tela da carteira e clique na lixeira,depois confirme com sua senha.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 550, 
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          // Barrinha cinza de "puxar"
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Como funciona a Carteira?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _tutorialSteps.length,
              itemBuilder: (context, index) {
                final step = _tutorialSteps[index];
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10), // Espaçamento extra no topo
                      CircleAvatar(
                        radius: 45, // Aumentei levemente o ícone
                        backgroundColor: step['color'].withOpacity(0.1),
                        child: Icon(step['icon'], size: 45, color: step['color']),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22, // Fonte do título um pouco maior
                          fontWeight: FontWeight.bold,
                          color: step['color'],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step['description'],
                        textAlign: TextAlign.center, // Centraliza o texto
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5, // Espaçamento entre linhas para leitura fácil
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20), // Espaço no final para não colar
                    ],
                  ),
                );
              },
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _tutorialSteps.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? const Color.fromARGB(255, 25, 116, 172)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 25, 116, 172),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Entendi", 
                  style: TextStyle(color: Colors.white, fontSize: 16)
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), // Margem segura inferior
        ],
      ),
    );
  }
}
