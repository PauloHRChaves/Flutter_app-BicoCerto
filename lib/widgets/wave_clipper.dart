import 'package:flutter/material.dart';

// Irrelevante - apenas fazendo o widget de onda no top da tela

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // A altura da onda será uma porcentagem da altura da tela.
    final double waveHeight = size.height * 0.2; 

    // O objeto 'Path' é usado para desenhar a forma
    final Path path = Path();
    
    // Começa no canto superior esquerdo
    path.lineTo(0.0, waveHeight);

    // Primeiro ponto da curva
    var firstControlPoint = Offset(size.width * 0.25, waveHeight - 30);
    var firstEndPoint = Offset(size.width * 0.5, waveHeight);
    path.quadraticBezierTo(
      firstControlPoint.dx, 
      firstControlPoint.dy, 
      firstEndPoint.dx, 
      firstEndPoint.dy,
    );

    // Segundo ponto da curva
    var secondControlPoint = Offset(size.width * 0.75, waveHeight + 30);
    var secondEndPoint = Offset(size.width, waveHeight);
    path.quadraticBezierTo(
      secondControlPoint.dx, 
      secondControlPoint.dy, 
      secondEndPoint.dx, 
      secondEndPoint.dy,
    );

    // Continua para o canto superior direito
    path.lineTo(size.width, 0.0);
    
    // Fecha o caminho para formar uma área preenchível
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    // Para esta forma fixa é usado 'false'
    return false;
  }
}