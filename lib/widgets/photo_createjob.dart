import 'package:flutter/material.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'dart:io'; // Necessário para o tipo File

// ... (Seus outros imports)

// NOVO WIDGET para exibir uma foto individual com botão de remover
class PhotoItemWidget extends StatelessWidget {
  final File imageFile;
  final VoidCallback onRemove;

  const PhotoItemWidget({
    super.key,
    required this.imageFile,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.file( // <-- AGORA USA Image.file
              imageFile,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
          // Botão de Remover (X)
          Positioned(
            top: -5,
            right: -5,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// PhotoInputWidget (ATUALIZADO)
// -------------------------------------------------------------
class PhotoInputWidget extends StatelessWidget {
  
  // ATUALIZADO: Agora recebe List<File>
  final List<File> photoFiles;
  final VoidCallback onAddPhoto;
  final Function(int) onRemovePhoto; // Novo callback

  const PhotoInputWidget({
    super.key,
    required this.photoFiles, 
    required this.onAddPhoto,
    required this.onRemovePhoto, 
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
            itemCount: photoFiles.length + 1, // +1 para o botão de adicionar
            itemBuilder: (context, index) {
              if (index == photoFiles.length) {
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
              

              // Exibição das Fotos (AGORA USA PhotoItemWidget)

              return PhotoItemWidget(
                imageFile: photoFiles[index],
                onRemove: () => onRemovePhoto(index), // Chama a função de remoção
              );
            },
          ),
        ),
      ],
    );
  }
}