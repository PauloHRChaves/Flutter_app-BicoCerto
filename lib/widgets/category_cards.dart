import 'package:flutter/material.dart';

// ----- Widget (Quadradinhos com as Categorias Populares.)
class CategoriaCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const CategoriaCard({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color.fromARGB(255, 241, 133, 9), size: 35),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

