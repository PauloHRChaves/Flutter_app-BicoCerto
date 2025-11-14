
import 'package:flutter/material.dart';

@pragma('flutter:keep-to-string-in-subtypes')
abstract interface class thisException {
  factory thisException([var message]) => _Exception(message);
}

class _Exception implements thisException {
  final dynamic message;

  _Exception([this.message]);

  String toString() {
    Object? message = this.message;
    if (message == null) return "Exception";
    return "$message";
  }
}


/// Exibe um Snackbar padronizado para mensagens de erro.
void showCustomErrorSnackbar(BuildContext context, String errorMessage) {
  // O ScaffoldMessenger gerencia a exibição de Snackbars
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Center(
        child: Text(
          // O erro vem como String, garantindo que o Text funcione
          errorMessage,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white, // Garantindo boa legibilidade
          ),
          textAlign: TextAlign.center,
        ),
      ),
      // Cor de fundo vermelha
      backgroundColor: const Color.fromARGB(255, 226, 0, 0),
      
      // Define a duração da exibição
      duration: const Duration(seconds: 4), 
      
      // O behavior Floating faz com que o snackbar não ocupe a largura total
      behavior: SnackBarBehavior.floating, 
    ),
  );
}

/// Mapeamento de localizações de erro (campo 'loc') para mensagens personalizadas
const Map<String, dynamic> _customErrorMessages = {
  // O valor agora é um Map<String, String>
   'auth/login': {
        'email': "Ops, este e-mail não é válido, tente novamente.",
        'password': "A senha deve ter pelo menos 8 caracteres.",
   },
   'auth/register':{
     'email': "Ops, este e-mail não é válido, tente novamente.",
     'username': "Este nome de usuário já está em uso.",
   },
};


String getCustomErrorMessage(Map<String, dynamic> errorJsonMap, String pageError) {
  final dynamic detailContent = errorJsonMap['detail'];
  
  // 1. TRATAMENTO DO FORMATO SIMPLES: {detail: "mensagem"}
  if (detailContent is String) {
    return detailContent;
  }
  
  // 2. TRATAMENTO DO FORMATO COMPLEXO: {detail: [...]}
  final List<dynamic>? detailList = detailContent is List ? detailContent : null;

  if (detailList == null || detailList.isEmpty) {
    return "Erro de requisição não especificado ou formato inesperado. Tente novamente.";
  }

  // Acessa o primeiro item da lista 'detail', verificando se é um Map.
  final Map<String, dynamic>? detailItem = 
    detailList.first is Map<String, dynamic> 
    ? detailList.first as Map<String, dynamic> 
    : null; 
    
  if (detailItem == null){
    return "Estrutura de erro de validação inválida.";
  }
  
  // 3. Acessa de forma segura a lista 'loc' e a mensagem 'msg'.
  final List<dynamic>? locList = detailItem['loc'] as List<dynamic>?;
  final String? apiMessage = detailItem['msg'] as String?;
  String? fieldName;

  // 4. Verifica se 'loc' existe e tem o campo (último elemento como String).
  if (locList != null && locList.isNotEmpty && locList.last is String) {
    fieldName = locList.last as String;
  }

  // ==========================================================
  // 5. Mapeamento para Mensagem Personalizada (Com Acesso Duplo)

  
  // Tenta obter o sub-mapa de mensagens específico para o endpoint (pageError)
  final Map<String, dynamic>? customEndPointMessage = 
      _customErrorMessages[pageError] as Map<String, dynamic>?;

  // Verifica se o campo foi encontrado E se o mapa do endpoint existe
  if (fieldName != null && customEndPointMessage != null) {
    
    // Verifica se a mensagem personalizada existe no sub-mapa
    if (customEndPointMessage.containsKey(fieldName)) {
      // Retorna a mensagem do sub-mapa
      return customEndPointMessage[fieldName]!;
    }
  }

  // 6. Fallback: Retorna a mensagem original da API ou uma genérica final.
  return apiMessage ?? "Erro desconhecido. Por favor, tente novamente.";
}