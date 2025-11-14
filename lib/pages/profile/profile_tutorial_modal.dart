// lib/widgets/profile_tutorial_modal.dart

import 'package:flutter/material.dart';

class ProfileTutorialModal extends StatefulWidget {
  const ProfileTutorialModal({super.key});

  @override
  State<ProfileTutorialModal> createState() => _ProfileTutorialModalState();
}

class _ProfileTutorialModalState extends State<ProfileTutorialModal> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'title': 'Perfil do Usuario',
      'icon': Icons.person_pin_circle_rounded,
      'color': Colors.blue,
      'description':
          'Este é o seu perfil público e nele tem algumas informações:\n\n• Dashboard \n• Trabalhos \n• Localização e Descrição',
    },
    {
      'title': 'Edite suas Informações',
      'icon': Icons.edit_note_rounded,
      'color': Colors.orange,
      'description':
          'Mudou de cidade? Quer uma foto nova?\n\nToque no ícone de Lápis (✏️) no topo da tela para atualizar seus dados.',
    },
    {
      'title': 'Central de comando',
      'icon': Icons.dashboard_customize_rounded,
      'color': Colors.green,
      'description':
          'Use os botões de atalho para navegar rápido:\n\n💳 Carteira: Seus pagamentos.\n📊 Dashboard: Seus gráficos de ganhos.\n💼 Jobs: Seus serviços em andamento.',
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
              "Conheça seu Perfil",
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
                      const SizedBox(height: 10),
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: step['color'].withOpacity(0.1),
                        child: Icon(step['icon'], size: 45, color: step['color']),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step['title'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: step['color'],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        step['description'],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
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
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}