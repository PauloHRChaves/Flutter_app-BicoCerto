import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';

// Widget para a Bottom Navigation Bar em todas as paginas
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color selectedColor = Color.fromARGB(255, 14, 67, 182);
  static const Color unselectedColor = Color.fromARGB(210, 73, 73, 73);
  static const Color barColor = Color.fromARGB(255, 252, 253, 255);
  static const Color centerBottomColor = Color.fromARGB(255, 255, 157, 0);

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    final color = isSelected ? selectedColor : unselectedColor;

    return InkWell(
      onTap: () => onTap(index),
      child: Container(
        constraints: const BoxConstraints(minWidth: 65),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 31),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Responsividade
    final screenHeight = MediaQuery.of(context).size.height;

    return BottomAppBar(
      color: barColor,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 10.0,

      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_filled, "Início", 0),
            _buildNavItem(Icons.list, "Pedidos", 1),

            Transform.translate(
              offset: const Offset(0.0, -18.0),
              child: IconButton(
                icon: const Icon(
                  Icons.add_circle,
                  size: 65,
                  color: centerBottomColor,
                ),
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.orderInfoPage);
                },
                tooltip: 'Nova Ação',
              ),
            ),

            _buildNavItem(Icons.message_outlined, "Chats", 2),
            _buildNavItem(Icons.person_outline, "Perfil", 3),
          ],
        ),
      ),
    );
  }
}
