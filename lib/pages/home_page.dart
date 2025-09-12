import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
          image: AssetImage('assets/images/encanador_background.png'), 
          fit: BoxFit.cover,
          ),
        ) 
      )
    );
  }
}
