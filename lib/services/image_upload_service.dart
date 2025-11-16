import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http_parser;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class ImageUploadService {
  static final String baseUrl = dotenv.env['BASE_URL'] ?? '';
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();

  /// Upload de foto de perfil da GALERIA
  Future<String?> uploadProfilePicture() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final compressedFile = await _compressImage(File(pickedFile.path));
      if (compressedFile == null) return null;

      return await _uploadToAPI(compressedFile);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload de foto de perfil da CÂMERA
  Future<String?> uploadProfilePictureFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final compressedFile = await _compressImage(File(pickedFile.path));
      if (compressedFile == null) return null;

      return await _uploadToAPI(compressedFile);
    } catch (e) {
      rethrow;
    }
  }

  /// Comprimir imagem antes do upload
  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;

      String outPath;
      if (filePath.toLowerCase().endsWith('.jpg') ||
          filePath.toLowerCase().endsWith('.jpeg')) {
        outPath = filePath
            .replaceAll('.jpg', '_compressed.jpg')
            .replaceAll('.jpeg', '_compressed.jpg');
      } else {
        outPath =
            filePath.replaceAll(path.extension(filePath), '_compressed.jpg');
      }

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 85,
        minWidth: 800,
        minHeight: 800,
        format: CompressFormat.jpeg,
      );

      if (result == null) return file;
      return File(result.path);
    } catch (e) {
      return file;
    }
  }

  /// Fazer upload para a API
  Future<String> _uploadToAPI(File imageFile) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      String? mimeType = lookupMimeType(imageFile.path);

      if (mimeType == null || !mimeType.startsWith('image/')) {
        mimeType = 'image/jpeg';
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/profile-picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      final multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: http_parser.MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['url'];
      } else {
        final error = json.decode(response.body);
        throw Exception(
            error['detail'] ?? error['message'] ?? 'Erro ao fazer upload');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Deletar foto de perfil
  Future<bool> deleteProfilePicture() async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/upload/profile-picture'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Erro ao deletar foto');
      }
    } catch (e) {
      return false;
    }
  }

  /// Mostrar opções de galeria/câmera
  Future<ImageSource?> showImageSourceOptions(BuildContext context) async {
    return await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolher foto do perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Câmera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}