// lib/pages/wallet/send_page.dart

import 'package:flutter/material.dart';

class SendPage extends StatelessWidget {
  // O construtor deve ser const para evitar futuros erros.
  const SendPage({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enviar Dinheiro'),
      ),
      body: const Center(
        child: Text('Tela de Envio (Em Construção)'),
      ),
    );
  }
}