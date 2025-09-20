import 'package:flutter/material.dart';
import 'package:bico_certo/widgets/category_cards.dart';
import 'package:bico_certo/pages/profile/profile.dart';

// HOMEPAGE - PAGINA PRINCIPAL DO PROJETO - HAVERÁ MUDANÇAS

class HomePage extends StatelessWidget {
    final bool isLoggedIn;
  
  const HomePage({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              title: const Text("BICO CERTO",
              style: TextStyle(
                  color: Color.fromARGB(255, 37, 143, 230),
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          // Exibe o botão de login apenas ao user deslogado
          if (!isLoggedIn) 
            TextButton(
                onPressed: () {
                  // Navega para a tela de login (AuthWrapper)
                  Navigator.pushNamed(context, '/auth');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 60, 63, 218),
                ),
                child: const Text('Login', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255))),
            ),
        ],
      ),
      body:
      SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Encontre o Profissional" RichText formata o texto de forma dinamica.
                RichText(
                  text: TextSpan(
                      text: 'Encontre o ', // texto normal
                      style: TextStyle(color: Colors.black, fontSize: 32, fontFamily: 'Inter'), // estilo padrão
                      children: <TextSpan>[
                        TextSpan(
                          text: 'Profissional Ideal', // parte que terá cor diferente
                          style: TextStyle(color: const Color.fromARGB(255, 137, 27, 240), fontSize: 35, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                        ),
                        TextSpan(
                          text: ' para seu serviço.', // texto normal continuando
                          style: TextStyle(color: Colors.black,
                                  fontFamily: 'Inter'
                                  ),
                           
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  //- Barra de Pesquisa
                  const TextField(
                    decoration: InputDecoration(
                      hintText: "Qual serviço você precisa?",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botão de Busca.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF4A3AFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(30)),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Buscar Serviço",
                        style: TextStyle(fontSize: 20, color: Colors.white,  fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  //Texto de Categorias Populares
                  const Text(
                    "Categorias Populares",
                    style: TextStyle(fontSize: 25, 
                    fontWeight: FontWeight.w500, 
                    fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 25),
                  // Categorias (Grid)
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      CategoriaCard(icon: Icons.build, text: "Reformas"),
                      CategoriaCard(icon: Icons.electrical_services, text: "Assistência Técnica"),
                      CategoriaCard(icon: Icons.book, text: "Aulas Particulares"),
                      CategoriaCard(icon: Icons.design_services, text: "Design"),
                      CategoriaCard(icon: Icons.show_chart, text: "Consultoria"),
                      CategoriaCard(icon: Icons.electric_bolt, text: "Elétrica"),
                      CategoriaCard(icon: Icons.design_services, text: "Example 1"),
                      CategoriaCard(icon: Icons.design_services, text: "Example 2"),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Banner para de chamada para cadastro
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A5AE0), Color(0xFF9D6CFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //----- Texto primário do Banner
                        const Text(
                          "É Profissional?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        //----Texto secundário do Banner
                        const Text(
                          "Cadastre-se, busque e receba orçamentos de novos clientes.",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color.fromARGB(211, 255, 255, 255)),
                        ),

                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xFF4A3AFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),

                          onPressed: () {},
                          child: const Text("Cadastrar agora",
                                      style: TextStyle(fontSize: 16)),
                        )
                      ],
                    ),
                  ),
                ],
              ),
          ),
      
      
      bottomNavigationBar: SizedBox(
        height: 85,
        child: BottomNavigationBar(
          currentIndex: 2, // índice da aba selecionada
          selectedItemColor: const Color.fromARGB(214, 255, 255, 255),
          unselectedItemColor: const Color.fromARGB(214, 255, 255, 255),
          backgroundColor: const Color.fromARGB(255, 14, 67, 182),
          onTap: (index) {
            if (index == 0) {
              /*Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              ); */
            } else if (index == 1) {
              /*Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrdersPage()),
              //-------------- Vamos ver o que colocar ainda...
              );*/
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SetProfile()),
              );
            }
          },

          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Início"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "Pedidos"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          ],
        ),           
      ),
    );
  }
}


