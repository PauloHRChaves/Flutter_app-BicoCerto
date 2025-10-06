import 'package:flutter/material.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';
import 'package:bico_certo/routes.dart';

class Testing extends StatefulWidget {
  const Testing({super.key});

  @override
  State<Testing> createState() => _SetProfileState();
}

class _SetProfileState extends State<Testing> {
  // Funções utilitárias para construir os elementos do design
  
  Widget _buildStatCard({required String title, required String value, required Color color, bool isRating = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.grey, spreadRadius: 1, blurRadius: 3)],
        ),
        child: Column(
          children: [
            if (isRating)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 5; i++)
                    Icon(
                      i < (double.tryParse(value) ?? 0) ? Icons.star : Icons.star_border,
                      color: color,
                      size: 20,
                    ),
                ],
              )
            else
              Text(
                value,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: color),
              ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para os botões de ação na barra horizontal (com indicador ativo)
  Widget _buildActionButton({required BuildContext context, required IconData icon, required String label, VoidCallback? onTap, bool isActive = false}) {
    const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: primaryBlue, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: isActive ? primaryBlue : Colors.grey.shade700),
          ),
          Container(
            margin: const EdgeInsets.only(top: 4),
            height: 2,
            width: 50,
            color: isActive ? primaryBlue : Colors.transparent,
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color.fromARGB(255, 25, 116, 172);
    const Color lightBackground = Color.fromARGB(255, 230, 230, 230);
    const Color darkText = Color.fromARGB(255, 30, 30, 30);

    // FIX SEGURANÇA: AuthGuard envolve todo o conteúdo do Scaffold
    return Scaffold(
        backgroundColor: lightBackground,
        appBar: AppBar(
          backgroundColor: Colors.white,
        ),
        
        body: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: [
            // --- Seção do Perfil Principal (Topo) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  // Avatar (Círculo Preto com ícone)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryBlue, width: 3),
                      color: Colors.black, // Fundo preto do avatar
                    ),
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Name",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  const SizedBox(height: 4),
                  const Text("Profissão", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text("CIDADE - ESTADO", style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),

                  // Cartão de Descrição
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: lightBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: Text("Descrição", textAlign: TextAlign.center, style: TextStyle(color: darkText, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Seção de Estatísticas (Trabalhos Concluídos e Avaliações) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildStatCard(title: "Trabalhos Concluídos", value: "00", color: primaryBlue),
                  const SizedBox(width: 16),
                  _buildStatCard(title: "Média de Avaliações", value: "4.5", color: Colors.amber, isRating: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // --- Barra de Navegação de Ícones (Funcionalidades) ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Ícone Carteira (Wallet) - Chama a função corrigida
                  _buildActionButton(
                    context: context,
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Wallet",
                    isActive: true, 
                  ),
                  _buildActionButton(context: context, icon: Icons.handshake_outlined, label: "YYY"),
                  _buildActionButton(context: context, icon: Icons.settings_outlined, label: "YYY"),
                  _buildActionButton(context: context, icon: Icons.headset_mic_outlined, label: "YYY"),
                ],
              ),
            ),
            
            // --- Histórico de Serviços ---
            Container(
              margin: const EdgeInsets.only(top: 20, left: 16, right: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Histórico de Serviços",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  const SizedBox(height: 12),
                  const Text("Lista de trabalhos concluídos (Implementar aqui).", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        
        bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {  
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.sessionCheck, 
              (route) => route.isFirst,
            );
          } else if (index == 1) {
            /*
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.teste, 
              (route) => route.isFirst,
            );*/
          } else if (index == 2) {
            /*Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.setProfile,
              (route) => route.isFirst,
            );*/
          }
        },
      ),

    );
  }
}

// PAGINA SEM LOGICA APLICADA - APENAS PARA UI