class Job {
  final String jobId;
  final String client;
  final double maxBudget;
  final String deadline;
  final String category;
  final int proposalCount;
  final JobMetadata metadata;
  final String ipfsCid;

  Job({
    required this.jobId,
    required this.client,
    required this.maxBudget,
    required this.deadline,
    required this.category,
    required this.proposalCount,
    required this.metadata,
    required this.ipfsCid,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['job_id']?.toString() ?? '',
      client: json['client']?.toString() ?? '',
      maxBudget: _parseDouble(json['max_budget']),
      deadline: json['deadline']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      proposalCount: _parseInt(json['proposal_count']),
      metadata: JobMetadata.fromJson(json['metadata'] ?? {}),
      ipfsCid: json['ipfs_cid']?.toString() ?? '',
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