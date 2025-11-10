// lib/pages/profile/edit_profile_page.dart

import 'package:flutter/material.dart';
import 'package:bico_certo/services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentCity;
  final String currentState;
  final String currentDescription;
  final String currentPicUrl;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentCity,
    required this.currentState,
    required this.currentDescription,
    required this.currentPicUrl,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _descriptionController;
  late TextEditingController _picUrlController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _cityController = TextEditingController(text: widget.currentCity);
    _stateController = TextEditingController(text: widget.currentState);
    _descriptionController = TextEditingController(text: widget.currentDescription);
    _picUrlController = TextEditingController(text: widget.currentPicUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _descriptionController.dispose();
    _picUrlController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    final Map<String, dynamic> dataToUpdate = {};
    if (_nameController.text != widget.currentName) {
      dataToUpdate['full_name'] = _nameController.text;
    }
    if (_cityController.text != widget.currentCity) {
      dataToUpdate['city'] = _cityController.text;
    }
    if (_stateController.text != widget.currentState) {
      dataToUpdate['state'] = _stateController.text;
    }
    if (_descriptionController.text != widget.currentDescription) {
      dataToUpdate['description'] = _descriptionController.text;
    }
    if (_picUrlController.text != widget.currentPicUrl) {
      dataToUpdate['profile_pic_url'] = _picUrlController.text;
    }

    if (dataToUpdate.isEmpty) {
      setState(() => _isLoading = false);
      Navigator.pop(context, false); 
      return;
    }

    try {
      await _authService.updateUserProfile(dataToUpdate);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color.fromARGB(255, 15, 73, 131),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildTextField(
              controller: _nameController,
              label: 'Nome Completo',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cityController,
              label: 'Cidade',
              icon: Icons.location_city,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _stateController,
              label: 'Estado (UF)',
              icon: Icons.map,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _picUrlController,
              label: 'URL da Foto de Perfil',
              icon: Icons.image,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Descrição',
              icon: Icons.description,
              maxLines: 5,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 25, 116, 172),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _handleSave,
                    child: const Text(
                      'Salvar Alterações',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (value) {
        // Você pode adicionar validações aqui se quiser
        return null;
      },
    );
  }
}