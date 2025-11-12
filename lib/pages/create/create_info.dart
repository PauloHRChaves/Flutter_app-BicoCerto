import 'package:bico_certo/services/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';

class OrderInfoPage extends StatelessWidget {
  // A função onTap será chamada ao pressionar o botão principal.
  // Ela deve ser passada pelo widget pai para navegar para a CreateOrderPage.

  const OrderInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Definindo a cor primária para reutilização (cor do AppBar e botões)
    const Color primaryColor = Color(0xFF0E43B6);
    
    return AuthGuard(
        child: Scaffold(
        appBar: AppBar(
          title: const Text('Guia Rápido', style: TextStyle(color: Colors.black87)),
          backgroundColor: Colors.white,
          elevation: 0.5, // Sombra suave na AppBar
          centerTitle: true,
        ),
        
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título Principal
              const Text(
                "Como Publicar Seu Pedido",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              
              const SizedBox(height: 16),

              // Parágrafo de Introdução
              const Text(
                "Para receber as melhores propostas, preencha as informações com clareza. Seu Pedido será enviado para profissionais qualificados.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),

              const SizedBox(height: 32),

              // Seção de Instruções (Mapeado do seu 'space-y-6')
              _buildInstructionStep(
                number: 1,
                title: "Detalhe a Necessidade",
                description: "Use o Título e a Descrição para explicar exatamente o que você precisa (Ex: \"Vazamento no encanamento do banheiro\"). Quanto mais claro, melhor a proposta do profissional.",
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),

              _buildInstructionStep(
                number: 2,
                title: "Defina Escopo e o local",
                description: "Selecione a Categoria correta, informe a Localização e escolha uma Data de Término estipulada. Isso ajuda o profissional a calcular o tempo e o deslocamento.",
                primaryColor: primaryColor,
              ),
              const SizedBox(height: 16),

              _buildInstructionStep(
                number: 3,
                title: "Anexe Fotos e um Valor Mínimo",
                description: "Adicionar fotos da área ou do problema é crucial. Profissionais conseguem avaliar a complexidade do serviço e enviar orçamentos mais precisos. Você também pode definir um valor mínimo para a proposta. .",
                primaryColor: primaryColor,
              ),

              const SizedBox(height: 40),
              
              // Seção de Expectativa ('div.bg-yellow-50')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBE5), // Cor amarela clara (yellow-50)
                  border: Border(left: BorderSide(color: const Color(0xFFFBBF24), width: 4)), // Borda amarela (yellow-500)
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Ícone de Aviso (Mapeado do SVG)
                        Icon(Icons.info_outline, color: Color(0xFFB45309)), // Cor amarela escura (yellow-800)
                        SizedBox(width: 8),
                        Text(
                          "O que acontece depois?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309), // Cor amarela escura
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Após publicar, seu pedido será visível para os profissionais da região. Você deverá aguardar o contato deles por meio do chat do aplicativo para discutir detalhes e receber orçamentos.",
                      style: TextStyle(color: Color(0xFF78350F)), // Cor amarela/marrom escura (yellow-700)
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Botão Principal para o Formulário
              ElevatedButton(
                onPressed: () {
                  
                  // Navega para a CreateOrderPage ao pressionar o botão
                  Navigator.of(context).pushNamed(AppRoutes.createFormPage);
                  
                }, // Chama a função passada pelo widget pai
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4, // Sombra para replicar 'shadow-lg'
                ),
                child: const Text(
                  'Começar a Criar Pedido',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

}


 // Widget auxiliar para construir os passos de instrução (reutilizável)
 Widget _buildInstructionStep({
    required int number,
    required String title,
    required String description,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número do Passo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Título e Descrição
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
