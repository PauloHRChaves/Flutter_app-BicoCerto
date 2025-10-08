import 'package:flutter/material.dart'; 
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';




class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Página de Pedidos'),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
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
            /* COLOCAR A ROTA DO CHAT AQUI
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.chatPage,
              (route) => route.isFirst,
            );
            */
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