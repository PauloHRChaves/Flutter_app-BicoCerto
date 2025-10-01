// widgets/bottom_navbar.dart
import 'package:flutter/material.dart';


  // Widget para a Bottom Navigation Bar em todas as paginas
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar(
    {    super.key,
    required this.currentIndex,
    required this.onTap,
    }
  );

  static const Color selectedColor = Color.fromARGB(255, 14, 67, 182);
  static const Color unselectedColor = Color.fromARGB(212, 105, 105, 105);
  static const Color barColor = Color.fromARGB(214, 255, 255, 255);
  static const Color centerBottomColor = Color.fromARGB(255, 255, 145, 0);


  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    final color = isSelected ? selectedColor : unselectedColor;

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0), 
        constraints: const BoxConstraints(minWidth: 60), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 28),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: barColor,
      height: 85,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 10.0,

      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.home_filled, "Início", 0),
          _buildNavItem(Icons.list, "Pedidos", 1),

        IconButton(

          icon: const Icon(Icons.add_circle, size: 60, color: centerBottomColor),
          onPressed: () {
            // Ação do botão central (se necessário)
          },
          tooltip: 'Nova Ação',
          padding: const EdgeInsets.only(bottom: 20),

        ),
          _buildNavItem(Icons.wallet, "Carteira", 2),
          _buildNavItem(Icons.person_outline, "Perfil", 3),
        ],
      )
    ),
  );

/* //----------VERSÃO SIMPLES DO BOTTOM NAVBAR (SEM BOTÃO CENTRAL)-----------------
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85,
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color.fromARGB(255, 14, 67, 182),
        unselectedItemColor: const Color.fromARGB(212, 105, 105, 105),
        backgroundColor: const Color.fromARGB(214, 255, 255, 255),
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Início"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Pedidos"),

          
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: "Carteira"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
        ],
      ),
    );
   
*/
 }
}



