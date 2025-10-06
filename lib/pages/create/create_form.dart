import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';

// Este widget simula a galeria de fotos que você já criou.
// Em um projeto real, você usaria o seu PhotoGalleryWidget.
class PhotoInputWidget extends StatelessWidget {
  final List<String> photoUrls;
  final VoidCallback onAddPhoto;

  const PhotoInputWidget({
    super.key,
    required this.photoUrls,
    required this.onAddPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Fotos (Opcional)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photoUrls.length + 1, // +1 para o botão de adicionar
            itemBuilder: (context, index) {
              if (index == photoUrls.length) {
                // Botão de Adicionar Foto
                return GestureDetector(
                  onTap: onAddPhoto,
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400, width: 1.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.grey, size: 30),
                        SizedBox(height: 4),
                        Text("Adicionar", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }
              
              // Exibição das Fotos (Simulação com Placeholders)
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    photoUrls[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// PÁGINA PRINCIPAL: CreateOrderPage
// -------------------------------------------------------------
class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({super.key});

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  // 1. Controladores e Variáveis de Estado
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  String? _selectedCategory; // Estado da Categoria (Dropdown)
  DateTime? _selectedDate; // Estado da Data de Término
  

  // Lista de categorias (para o Dropdown)
  final List<String> _categories = [
    'Reformas', 'Assistência Técnica', 'Aulas Particulares', 'Design', 'Consultoria', 'Elétrica'
  ];


  // Função para abrir o seletor de data
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)), // Data inicial
      firstDate: DateTime.now(), // Não pode ser uma data passada
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // Limite de 2 anos
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Função chamada ao enviar o formulário
  void _submitOrder() {
    // 1. Coleta os dados
    final data = {
      'title': _titleController.text,
      'category': _selectedCategory,
      'location': _locationController.text,
      'description': _descriptionController.text,
      'dueDate': _selectedDate?.toIso8601String(),
      };

    /*// 2. Validação básica (exemplo)
    if (_titleController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha Título e Categoria.')),
      );
      return;
    }*/

  
    // 3. Imprime os dados no console para demonstração
    print("--- Pedido Enviado ---");
    data.forEach((key, value) => print("$key: $value"));
    print("------------------------");
    

    // 4. Feedback e retorno
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido criado com sucesso!')),
    );
    Navigator.of(context).pushNamed(AppRoutes.sessionCheck); // Volta para a tela anterior
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Pedido'),
        backgroundColor: const Color.fromARGB(255, 14, 67, 182),
        foregroundColor: Colors.white,
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título do Pedido
            _buildTextField("Título do Pedido", _titleController, "Ex: Conserto de vazamento no banheiro"),
            const SizedBox(height: 20),

            // Categoria do Serviço (Dropdown)
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            
            // Localização
            _buildTextField("Localização", _locationController, "Ex: Bairro Centro, Rua das Flores, 123"),
            const SizedBox(height: 20),

            // Descrição
            _buildDescriptionField(),
            const SizedBox(height: 20),

            // Entrada de Fotos
            PhotoInputWidget(
              photoUrls: [], 
              onAddPhoto: (){},
            ),
            const SizedBox(height: 20),

            // Data Estipulada de Término
            _buildDateField(),
            const SizedBox(height: 30),

            // Botão de Envio
            Center(
              child: ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Botão de largura total
                  backgroundColor: const Color.fromARGB(255, 14, 67, 182),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Publicar Pedido',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widgets Auxiliares de Construção ---

  // Campo de Texto Padrão
  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            fillColor: Colors.grey.shade100,
            filled: true,
          ),
        ),
      ],
    );
  }

  // Campo de Descrição (Multilinha)
  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Descrição Detalhada", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: "Descreva o problema ou o serviço que você precisa...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            fillColor: Colors.grey.shade100,
            filled: true,
          ),
        ),
      ],
    );
  }

  // Seletor de Categoria
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Categoria do Serviço", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCategory,
              hint: const Text('Selecione uma categoria'),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
  
  // Seletor de Data
  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Data Estipulada de Término", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null 
                      ? 'Selecione a data limite' 
                      : 'Data: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedDate == null ? Colors.black54 : Colors.black,
                  ),
                ),
                Icon(Icons.calendar_today, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}
