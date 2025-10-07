import 'package:flutter/material.dart';




class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  

  @override
  State<WalletPage> createState() => _WalletPageState();

  Duration({required int milliseconds}) {}
}

class _WalletPageState extends State<WalletPage> {
  // Estado para controlar a aba selecionada (0: Tokens, 1: NFTs, 2: Activity)
  int _selectedTab = 0;
  // Estado para a Bottom Navigation Bar
  @override
  Widget build(BuildContext context) {
    // Responsividade
    final screenHeight = MediaQuery.of(context).size.height;

    const Color primaryColor = Color(0xFF000000); // Preto para o texto principal
    const Color secondaryColor = Color(0xFF656565); // Cinza escuro
    const Color accentColor = Color(0xFF1976D2); // Azul para links/ações
    const Color backgroundCard = Color(0xFFF7F7F7); // Fundo dos cards
    
    return Scaffold(
      backgroundColor: Colors.white, 

      appBar: AppBar(
        backgroundColor: accentColor,
        elevation: 1,
        title: const Text(
          "Carteira",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: screenHeight * 0.05),

            // 2. Saldo Total
            const Text(
              '\$0.00 BRL',
              style: TextStyle(
                color: primaryColor,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // Valor do portfólio
            Text(
              '+\$0 (0.00%)',
              style: TextStyle(
                color: Colors.green.shade700, // Verde para o lucro
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 30),

            // 3. Ações Rápidas (Buy, Swap, etc.)
            _buildActionButtons(primaryColor, secondaryColor),
            const SizedBox(height: 24),

            // 4. Card "Fund your wallet"
            _buildFundWalletCard(backgroundCard, accentColor, primaryColor),
            const SizedBox(height: 30),

            // 5. Abas (Tokens, NFTs, Activity)
            _buildTabBar(primaryColor, secondaryColor, accentColor),
            const SizedBox(height: 16),

            // Conteúdo da aba (Exemplo de Token)
            if (_selectedTab == 0) _buildTokenList(secondaryColor),
          ],
        ),
      ), 
    );
  }

  // Widget para os botões de ação rápida (Buy, Swap, etc.)
  Widget _buildActionButton(IconData icon, String label, Color iconColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.grey.shade100,
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: iconColor, fontSize: 12),
        ),
      ],
    );
  }

  // Linha de botões de ação
  Widget _buildActionButtons(Color primaryColor, Color secondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(Icons.account_balance_wallet_outlined, 'Buy & Sell', primaryColor),
        _buildActionButton(Icons.swap_horiz, 'Swap', primaryColor),
        _buildActionButton(Icons.link, 'Bridge', primaryColor),
        _buildActionButton(Icons.arrow_upward, 'Send', primaryColor),
        _buildActionButton(Icons.arrow_downward, 'Receive', primaryColor),
      ],
    );
  }

  // Card para financiar a carteira
  Widget _buildFundWalletCard(Color bgColor, Color iconColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wallet_travel, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fund your wallet',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            'Add or transfer tokens to get started',
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Abas de Tokens, NFTs e Activity
  Widget _buildTabBar(Color primaryColor, Color secondaryColor, Color accentColor) {
    return Column(
      children: [
        Row(
          children: ['Tudo', 'Saídas', 'Entradas'].asMap().entries.map((entry) {
            final index = entry.key;
            final label = entry.value;
            final isSelected = _selectedTab == index;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTab = index;
                  });
                },
                child: Column(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? primaryColor : secondaryColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Indicador da aba selecionada
                    Container(
                      height: 2,
                      width: 80, // Ajuste de largura do sublinhado
                      color: isSelected ? accentColor : Colors.transparent,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // A linha divisória abaixo das abas
        const Divider(height: 0, thickness: 1),
      ],
    );
  }

  // Exemplo de lista de tokens (apenas BRL Bico Certo)
  Widget _buildTokenList(Color secondaryColor) {
    return ListTile(
      leading: const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.yellow,
        child: Text('RC', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      title: const Text(
        'Reformas e Construção',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '#65B4042032',
        style: TextStyle(color: secondaryColor),
      ),
      trailing: const Text(
        '+ R\$100,00',
        style: TextStyle(color:Colors.green, fontWeight: FontWeight.bold),
      ),
      onTap: () {}, // Torna o item clicável
    );
  }
  
}
