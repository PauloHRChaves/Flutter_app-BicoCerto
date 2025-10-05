import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';


class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  final double totalEarnings = 1850.00;
  final double percentageChange = 12.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Meu Perfil",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
      
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Perfil
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(
                      "https://placehold.co/128x128/e5e7eb/6b7280?text=Usuário",
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "João da Silva",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Desenvolvedor Front-end | São Paulo, SP",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Olá! Sou um desenvolvedor com 5 anos de experiência, especializado em interfaces de usuário modernas e responsivas.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      elevation: 3,
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    label: const Text(
                      "Editar Perfil",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Serviços
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Meus Serviços",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.insert_drive_file, color: Colors.indigo),
                    title: Text("Criação de Websites"),
                  ),
                  ListTile(
                    leading: Icon(Icons.analytics, color: Colors.indigo),
                    title: Text("Consultoria de SEO"),
                  ),
                  ListTile(
                    leading: Icon(Icons.build, color: Colors.indigo),
                    title: Text("Manutenção de Sistemas"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // ---- Ganhos / Dashboard Page
            // Dados simulados
  
          InkWell(
            onTap: (){Navigator.of(context).pushNamed(AppRoutes.dashboardPage);}, // Ação ao clicar (navegar para outra página)
            borderRadius: BorderRadius.circular(12.0),
            child: Card(
              // Definições visuais para replicar o estilo do seu dashboard
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4, // Sombra suave (replicando o box-shadow)
              margin: EdgeInsets.zero, // Remove margem padrão do Card se estiver em Column/Row
              
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Título e Ícone
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        const Text(
                          'Ganhos Totais da Semana',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333), // Cor escura para o título
                          ),
                        ),
                        const Icon(
                          Icons.trending_up, // Ícone de tendência (similar a 'chart-line')
                          color: Color(0xFF4CAF50), // Verde para sucesso
                          size: 28,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 10),

                    // Valor Principal
                    Text(
                      'R\$ ${totalEarnings.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a1a1a),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Detalhe de Comparação
                    Text(
                      '+${percentageChange.toStringAsFixed(0)}% em relação à semana anterior',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4CAF50), // Verde
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Avaliações
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Avaliações",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 28),
                      SizedBox(width: 6),
                      Text("4.8", style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold)
                      ),
                      SizedBox(width: 6),
                      Text("(125 avaliações)",
                          style: TextStyle(color: Colors.grey, fontSize: 14)
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "\"Excelente profissional! O trabalho de criação do meu site superou minhas expectativas.\"",
                          style: TextStyle(
                              color: Colors.black54,
                              fontStyle: FontStyle.italic),
                        ),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text("- Maria C.",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey)
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Botão Sair
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 3,
            ),
            onPressed: () {},
            child: const Text(
              "Sair",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 80),
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
            
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.ordersPage, 
              (route) => route.isFirst,
            );
          } else if (index == 2) {
            
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.walletPage, 
              (route) => route.isFirst,
            );
          } else if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.profilePage, 
              (route) => route.isFirst,
            );
          }
        },
      ),
    
    );
  }
}
 
