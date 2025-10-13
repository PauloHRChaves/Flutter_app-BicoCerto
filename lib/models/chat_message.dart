class ChatMessage {
  final String id;
  final Map<String, dynamic> sender;
  final String message;
  final String messageType;
  final dynamic jsonMetadata;
  final String status;
  final String createdAt;
  final Map<String, dynamic>? replyTo;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    this.messageType = 'text',
    this.jsonMetadata,
    this.status = 'sent',
    required this.createdAt,
    this.replyTo,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sender: json['sender'],
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      jsonMetadata: json['json_metadata'],
      status: json['status'] ?? 'sent',
      createdAt: json['created_at'] ?? '',
      replyTo: json['reply_to'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'message': message,
      'message_type': messageType,
      'json_metadata': jsonMetadata,
      'status': status,
      'created_at': createdAt,
      'reply_to': replyTo,
    };
  }

  factory ChatMessage.optimistic({
    required String currentUserId,
    required String message,
    Map<String, dynamic>? replyTo,
  }) {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${message.hashCode}';
    final now = DateTime.now();
    final formattedDate = '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year} às '
        '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    return ChatMessage(
      id: tempId,
      sender: {'id': currentUserId, 'name': 'Você'},
      message: message,
      status: 'sending',
      createdAt: formattedDate,
      replyTo: replyTo,
    );
  }

  ChatMessage copyWith({
    String? id,
    Map<String, dynamic>? sender,
    String? message,
    String? messageType,
    dynamic jsonMetadata,
    String? status,
    String? createdAt,
    Map<String, dynamic>? replyTo,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      jsonMetadata: jsonMetadata ?? this.jsonMetadata,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      replyTo: replyTo ?? this.replyTo,
    );
  }

  bool get isTemporary => id.startsWith('temp_');
}