import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/widgets/password_request.dart'; 
import 'package:bico_certo/widgets/photo_createjob.dart';

class CurrencyInputFormatter extends TextInputFormatter {

  final NumberFormat formatter = NumberFormat.currency(
    locale: 'pt_BR', 
    symbol: '',      
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
  final TextEditingController _titleJobController = TextEditingController();
  final TextEditingController _descriptionJobController = TextEditingController();
  final TextEditingController _locationJobController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
 
  String? _selectedCategory; // Estado da Categoria (Dropdown)
  DateTime? _selectedDate; // Estado da Data de Término
  String _selectedDateFormated = '';

  // Lista de categorias (para o Dropdown)
  final List<String> _categories = [
    'Reformas', 'Assistência Técnica', 'Aulas Particulares', 'Design', 'Consultoria', 'Elétrica'
  ];
  final List<File> _jobPhotos = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Escolher Imagem'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria de Fotos'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Câmera'),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000, // Opcional: Limita a resolução para economizar banda/espaço
        imageQuality: 70, // Opcional: Limita a qualidade da imagem
      );

      if (pickedFile != null) {
        setState(() {
          // Adiciona o novo arquivo à lista
          _jobPhotos.add(File(pickedFile.path));
        });
      }
    }
  }
  
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
 
  Future<void> _submitOrder(String password) async {
    final AuthService authService = AuthService();
    
    //-- 2. Validação básica
    if (_titleJobController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha Título e Categoria.')),
      );
      return;
    }
    
    
    try{  
      // Chama o serviço de API para criar o trabalho

      await authService.createJob(
        title: _titleJobController.text,
        description: _descriptionJobController.text,
        category: _selectedCategory!,
        location: _locationJobController.text,
        images: _jobPhotos,
        deadline: _selectedDateFormated,
        budget: _treatedBugdet(_budgetController.text), 
        password: password, 
        
      );
      
    //------------------------CAMPO DE TESTES DE ENVIO -----------------------------
    /*
      final data = {
      'title': _titleJobController.text,
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
          const SnackBar(content: Text('Trabalho criado com sucesso!.', 
          style: TextStyle(fontSize: 16, color: Colors.white),), 
          backgroundColor: Colors.green, 
          duration: Duration(seconds: 4)),
        );
        Navigator.of(context).pushNamed(AppRoutes.sessionCheck); // Volta para a tela anterior
      }
    } catch (e) {
      print('Erro ao criar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar pedido: ${e.toString()}', 
        style: const TextStyle(fontSize: 16, color: Colors.white),), 
        backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
      );
    }
  }
  
  // ---------------------------FIM DA LÓGICA DE ENVIO------------------------------- 
  void _showConfirmationModal(
    BuildContext context, 
    String buttonText, 
    ConfirmationCallback onConfirm
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: PasswordConfirmationWidget(
            onConfirm: onConfirm,
            confirmationText: buttonText,
          ),
        );
      },
    );
  }

  void _handleJobCreationAttempt() {
    // 1. Validação de campos da página de Create Job
    if (_titleJobController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
      );
      return; // Para aqui se a validação falhar
    }

    // 2. Se a validação passar, mostra o modal/widget de confirmação
    _showConfirmationModal(
      context, 
      "Criar Novo Trabalho", 
      _submitOrder // <-- Passamos a função adaptada!
    );
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
            _buildTextField("Título do Pedido", _titleJobController, "Ex: Conserto de vazamento no banheiro"),
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
              photoFiles: _jobPhotos, 
              onAddPhoto: _pickImage, // Função de seleção de imagem
              onRemovePhoto: (index) { 
                setState(() {
                    _jobPhotos.removeAt(index);
                  });
                },
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
                onPressed: (){
                  _handleJobCreationAttempt();
                },
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
  // Campo de Entrada de Valor (Moeda) - Sem Pacote Externo
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
    _titleJobController.dispose();
    _descriptionJobController.dispose();
    _locationJobController.dispose();
    super.dispose();
  }
}



