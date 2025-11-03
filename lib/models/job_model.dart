import 'package:flutter/material.dart';

enum JobStatus {
  none,
  created,
  open,
  accepted,
  inProgress,
  completed,
  approved,
  cancelled,
  disputed,
  refunded;

  static JobStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'none':
        return JobStatus.none;
      case 'created':
        return JobStatus.created;
      case 'open':
        return JobStatus.open;
      case 'accepted':
      case 'in_progress':
      case 'inprogress':
        return JobStatus.inProgress;
      case 'completed':
        return JobStatus.completed;
      case 'approved':
        return JobStatus.approved;
      case 'cancelled':
        return JobStatus.cancelled;
      case 'disputed':
        return JobStatus.disputed;
      case 'refunded':
        return JobStatus.refunded;
      default:
        return JobStatus.none;
    }
  }

  String get displayName {
    switch (this) {
      case JobStatus.none:
        return 'Nenhum';
      case JobStatus.created:
        return 'Criado';
      case JobStatus.open:
        return 'Aberto';
      case JobStatus.accepted:
      case JobStatus.inProgress:
        return 'Em Progresso';
      case JobStatus.completed:
        return 'Completo';
      case JobStatus.approved:
        return 'Aprovado';
      case JobStatus.cancelled:
        return 'Cancelado';
      case JobStatus.disputed:
        return 'Em Disputa';
      case JobStatus.refunded:
        return 'Reembolsado';
    }
  }

  Color get color {
    switch (this) {
      case JobStatus.none:
        return Colors.grey;
      case JobStatus.created:
        return Colors.blue;
      case JobStatus.open:
        return Colors.green;
      case JobStatus.accepted:
      case JobStatus.inProgress:
        return Colors.orange;
      case JobStatus.completed:
        return Colors.purple;
      case JobStatus.approved:
        return Colors.green.shade700;
      case JobStatus.cancelled:
        return Colors.red;
      case JobStatus.disputed:
        return Colors.deepOrange;
      case JobStatus.refunded:
        return Colors.amber;
    }
  }
}

class Job {
  final String jobId;
  final String client;
  final String providerId;
  final String providerAddress;
  final String providerName;
  final double maxBudget;
  final String acceptedAt;
  final String completedAt;
  final String deadline;
  final String category;
  final int proposalCount;
  final int proposalEstimatedTimeDays;
  final JobMetadata metadata;
  final String ipfsCid;
  final JobStatus status; // NOVO CAMPO

  Job({
    required this.jobId,
    required this.client,
    required this.providerId,
    required this.providerAddress,
    required this.providerName,
    required this.maxBudget,
    required this.acceptedAt,
    required this.completedAt,
    required this.deadline,
    required this.category,
    required this.proposalCount,
    required this.proposalEstimatedTimeDays,
    required this.metadata,
    required this.ipfsCid,
    required this.status, // NOVO CAMPO
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['id']?.toString() ?? '',
      client: json['client']?.toString() ?? '',
      providerId: json['accepted_proposal']?['provider']['user_id'].toString() ?? '',
      providerAddress: json['accepted_proposal']?['provider']['address'].toString() ?? '',
      providerName: json['accepted_proposal']?['provider']['name'].toString() ?? '',
      maxBudget: _parseDouble(json['max_budget']),
      deadline: json['deadline']?.toString() ?? '',
      acceptedAt: json['accepted_at']?.toString() ?? '',
      completedAt: json['completed_at']?.toString() ?? '',
      category: json['service_type']?.toString() ?? '',
      proposalCount: _parseInt(json['proposal_count']),
      proposalEstimatedTimeDays: _parseInt(json['accepted_proposal']?['estimatedTime']),
      metadata: JobMetadata.fromJson(json['metadata'] ?? {}),
      ipfsCid: json['ipfs_hash']?.toString() ?? '',
      status: JobStatus.fromString(json['status']?.toString() ?? 'none'), // NOVO CAMPO
    );
  }

  // Helper para converter qualquer valor para double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  // Helper para converter qualquer valor para int
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // NOVOS MÉTODOS ÚTEIS
  bool get isOpen => status == JobStatus.open;
  bool get isAccepted => status == JobStatus.accepted;
  bool get isInProgress => status == JobStatus.inProgress;
  bool get isCompleted => status == JobStatus.completed;
  bool get isApproved => status == JobStatus.approved;
  bool get isCancelled => status == JobStatus.cancelled;
  bool get isDisputed => status == JobStatus.disputed;
  bool get isRefunded => status == JobStatus.refunded;

  // Verifica se o job está ativo (aceita propostas)
  bool get isActive => status == JobStatus.open || status == JobStatus.created;

  // Verifica se o job está finalizado
  bool get isFinished =>
      status == JobStatus.approved ||
          status == JobStatus.cancelled ||
          status == JobStatus.refunded;
}

class JobMetadata {
  final JobData data;

  JobMetadata({required this.data});

  factory JobMetadata.fromJson(Map<String, dynamic> json) {
    return JobMetadata(
      data: JobData.fromJson(json['data'] ?? {}),
    );
  }
}

class JobData {
  final String title;
  final String description;
  final String category;
  final String location;
  final double maxBudget;
  final String deadline;
  final Employer employer;
  final String createdAt;

  JobData({
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.maxBudget,
    required this.deadline,
    required this.employer,
    required this.createdAt,
  });

  factory JobData.fromJson(Map<String, dynamic> json) {
    return JobData(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      maxBudget: _parseDouble(json['max_budget']),
      deadline: json['deadline']?.toString() ?? '',
      employer: Employer.fromJson(json['employer'] ?? {}),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}

class Employer {
  final String address;
  final String userId;
  final String? name;

  Employer({
    required this.address,
    required this.userId,
    this.name,
  });

  factory Employer.fromJson(Map<String, dynamic> json) {
    return Employer(
      address: json['address']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}