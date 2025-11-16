import 'package:flutter/material.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:bico_certo/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentCity;
  final String currentState;
  final String currentDescription;
  final String currentPicUrl;
  final String userId;

  const EditProfilePage({
    super.key,
    required this.currentName,
    required this.currentCity,
    required this.currentState,
    required this.currentDescription,
    required this.currentPicUrl,
    required this.userId,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _newProfilePicUrl;
  bool _hasChanges = false;

  late TextEditingController _nameController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _cityController = TextEditingController(text: widget.currentCity);
    _stateController = TextEditingController(text: widget.currentState);
    _descriptionController =
        TextEditingController(text: widget.currentDescription);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleImageUpload() async {
    final imageSource =
    await _imageUploadService.showImageSourceOptions(context);
    if (imageSource == null) return;

    setState(() => _isUploadingImage = true);

    try {
      String? downloadUrl;

      if (imageSource == ImageSource.gallery) {
        downloadUrl = await _imageUploadService.uploadProfilePicture();
      } else {
        downloadUrl =
        await _imageUploadService.uploadProfilePictureFromCamera();
      }

      if (downloadUrl != null) {
        setState(() {
          _newProfilePicUrl = downloadUrl;
          _hasChanges = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploadingImage = false);
    }
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

    if (!_hasChanges && dataToUpdate.isEmpty && _newProfilePicUrl == null) {
      setState(() => _isLoading = false);
      Navigator.pop(context, false);
      return;
    }

    if (dataToUpdate.isNotEmpty) {
      try {
        await _authService.updateUserProfile(dataToUpdate);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    }
  }

  Future<bool> _onWillPop() async {
    Navigator.pop(context, _hasChanges);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentPicUrl = _newProfilePicUrl ?? widget.currentPicUrl;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Editar Perfil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color.fromARGB(255, 15, 73, 131),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: currentPicUrl.isNotEmpty
                          ? NetworkImage(currentPicUrl)
                          : null,
                      child: currentPicUrl.isEmpty
                          ? const Icon(Icons.person,
                          size: 70, color: Colors.grey)
                          : null,
                    ),
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _isUploadingImage ? null : _handleImageUpload,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 15, 73, 131),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _isUploadingImage ? null : _handleImageUpload,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Alterar foto'),
                ),
              ),
              const SizedBox(height: 24),
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
                  backgroundColor:
                  const Color.fromARGB(255, 25, 116, 172),
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
    );
  }
}