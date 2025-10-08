import 'package:flutter/material.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

// Este widget simula a galeria de fotos que você já criou.
// Em um projeto real, você usaria o seu PhotoGalleryWidget.
class PhotoInputWidget extends StatelessWidget {
  
  // Lista de URLs das fotos (simulação)
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


class CurrencyInputFormatter extends TextInputFormatter {
  
  // O construtor garante que o pacote intl esteja disponível para formatar
  // com as configurações regionais do Brasil.
  // IMPORTANTE: O pacote 'intl' AINDA É NECESSÁRIO para a classe NumberFormat.
  final NumberFormat formatter = NumberFormat.currency(
    locale: 'pt_BR', // Configuração regional do Brasil
    symbol: '',      // Não usamos o símbolo aqui, apenas os separadores
    decimalDigits: 2,
  );

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Se o valor de entrada for vazio, retorna vazio.
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String maxLength = '999999999'; // Limite máximo de valor (9 dígitos antes da vírgula) 
    if (newValue.text.replaceAll(RegExp(r'[^\d]'), '').length > maxLength.length) {
      return oldValue; // Ignora a entrada se exceder o limite
    }
    // Remove tudo que não for dígito.
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Se o usuário digitou '0' ou mais dígitos.
    if (newText.isNotEmpty) {

      // Converte a string de dígitos para um número double (ex: '1500' -> 15.00)
      final double value = int.parse(newText) / 100; 

      // Formata o número usando o NumberFormat (ex: 15.00 -> '15,00' ou '1.500,00')
      final String formattedValue = formatter.format(value).trim();
      
      // Retorna a nova string com o cursor no final
      return TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: formattedValue.length),
      );
    }

    return newValue;
  }
}



// -------------------------------------------------------------
// PÁGINA CreateJobPage
// -------------------------------------------------------------
class CreateJobPage extends StatefulWidget {
  const CreateJobPage({super.key});

  @override
  State<CreateJobPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateJobPage> {
  // 1. Controladores e Variáveis de Estado
  final TextEditingController _titleJobControlle = TextEditingController();
  final TextEditingController _descriptionJobController = TextEditingController();
  final TextEditingController _locationJobController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  // ------------ Ver controlador para as fotos

  
  String? _selectedCategory; // Estado da Categoria (Dropdown)
  DateTime? _selectedDate; // Estado da Data de Término
  String _selectedDateFormated = '';

  // Lista de categorias (para o Dropdown)
  final List<String> _categories = [
    'Reformas', 'Assistência Técnica', 'Aulas Particulares', 'Design', 'Consultoria', 'Elétrica'
  ];

  // Função para abrir o seletor, coletar data, e formata-la.
  Future<void> _selectDate(BuildContext context) async {

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)), // Data inicial
      firstDate: DateTime.now(), // Não pode ser uma data passada
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // Limite de 2 anos
    );

    if (picked != null && picked != _selectedDate) {
      
      final DateFormat formatter = DateFormat("dd-MM-yyyy");
      final String formattedDate = formatter.format(picked);

      setState(() {
        _selectedDate = picked;
        _selectedDateFormated = formattedDate;
      });
    }
  }

  // Função para tratar o valor da proposta antes de enviar
  String _treatedBugdet(String formattedText){
    if (formattedText.isEmpty) {
      return '0.00';
    }

    final String removeThousandPoints = formattedText.replaceAll('.', '');
    final String cleanText = removeThousandPoints.replaceAll(',', '.');
    return cleanText;


  }

  // --------------------------------------------------------------------------------
  //                       LÓGICA DA COLETA E ENVIO DE DADOS
  // --------------------------------------------------------------------------------
 
  void _submitOrder() async {
    final AuthService _authService = AuthService();
    
    //-- 2. Validação básica
    if (_titleJobControlle.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha Título e Categoria.')),
      );
      return;
    }
    
    
    try{  
    
      await _authService.createJob(
        title: _titleJobControlle.text,
        description: _descriptionJobController.text,
        category: _selectedCategory!,
        location: _locationJobController.text,
        budget: _treatedBugdet(_budgetController.text), 
        deadline: _selectedDateFormated,
        password: 'Senha1233.', 
      );
      
    //------------------------CAMPO DE TESTES DE ENVIO -----------------------------
    /*
      final data = {
      'title': _titleJobControlle.text,
      'category': _selectedCategory,
      'location': _locationJobController.text,
      'budget': _treatedBugdet(_budgetController.text),
      'description': _descriptionJobController.text,
      'dueDate': _selectedDateFormated,
      };
    
      //---Imprime os dados no console para demonstração
      print("--- Pedido Enviado ---");
      data.forEach((key, value) => print("$key: $value"));
      print("------------------------");
    */
    //------------------------------------------------------------------------------

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trabalho criado com sucesso!.', style: TextStyle(fontSize: 16, color: Colors.white),), backgroundColor: Colors.green, duration: Duration(seconds: 4)),
        );
        Navigator.of(context).pushNamed(AppRoutes.sessionCheck); // Volta para a tela anterior
      }
    } catch (e) {
      print('Erro ao criar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar pedido: ${e.toString()}', style: const TextStyle(fontSize: 16, color: Colors.white),), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
      );
    }
  }
  // ---------------------------FIM DA LÓGICA DE ENVIO-------------------------------

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
            _buildTextField("Título do Pedido", _titleJobControlle, "Ex: Conserto de vazamento no banheiro"),
            const SizedBox(height: 20),

            // Categoria do Serviço (Dropdown)
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            
            // Localização
            _buildTextField("Localização", _locationJobController, "Ex: Bairro Centro, Rua das Flores, 123"),
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

            _buildCurrencyFieldWithoutPackage("Valor de Proposta", _budgetController, "Ex: 150,00"),
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
          controller: _descriptionJobController,
          maxLines: 5,
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

  Widget _buildCurrencyFieldWithoutPackage(
    String label,
    TextEditingController controller,
    String hint
  ){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number, // Abre o teclado numérico
          inputFormatters: [

            // 1. Permite apenas dígitos
            FilteringTextInputFormatter.digitsOnly, 

            // 2. Aplica a formatação de moeda personalizada
            CurrencyInputFormatter(), 
          ],
          decoration: InputDecoration(
            hintText: hint,
            // 💡 Adiciona o "R$ " Fixo à esquerda
            prefixText: 'R\$ ', 
            prefixStyle: const TextStyle(color: Colors.black, fontSize: 16), // Estilo do prefixo
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), 
              borderSide: BorderSide.none
            ),
            fillColor: Colors.grey.shade100,
            filled: true,
          ),
        ),
      ],
    );
  }


  @override
  void dispose() {
    _titleJobControlle.dispose();
    _descriptionJobController.dispose();
    _locationJobController.dispose();
    super.dispose();
  }
}



