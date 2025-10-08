// lib/pages/wallet/receive_page.dart

import 'package:flutter/material.dart';

class ReceivePage extends StatelessWidget {
  // O construtor deve ser const para evitar futuros erros.
  const ReceivePage({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receber Dinheiro'),
      ),
      body: const Center(
        child: Text('Tela de Recebimento (Em Construção)'),
      ),
    );
  }
}