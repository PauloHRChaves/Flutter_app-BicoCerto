import 'package:flutter/material.dart';
import 'package:bico_certo/models/job_model.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  final double? fontSize;
  final double? iconSize;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    required this.icon,
    this.fontSize,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveFontSize = fontSize ?? screenWidth * 0.03;
    final effectiveIconSize = iconSize ?? 14.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: effectiveIconSize,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: effectiveFontSize,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class JobStatusBadge extends StatelessWidget {
  final JobStatus status;
  final double? fontSize;
  final double? iconSize;

  const JobStatusBadge({
    super.key,
    required this.status,
    this.fontSize,
    this.iconSize,
  });

  IconData _getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return Icons.check_circle_outline;
      case JobStatus.accepted:
        return Icons.handshake;
      case JobStatus.inProgress:
        return Icons.construction;
      case JobStatus.completed:
        return Icons.task_alt;
      case JobStatus.approved:
        return Icons.verified;
      case JobStatus.cancelled:
        return Icons.cancel;
      case JobStatus.disputed:
        return Icons.warning;
      case JobStatus.refunded:
        return Icons.payment;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: status.displayName,
      color: status.color,
      icon: _getStatusIcon(status),
      fontSize: fontSize,
      iconSize: iconSize,
    );
  }
}

class ProposalStatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;
  final double? iconSize;

  const ProposalStatusBadge({
    super.key,
    required this.status,
    this.fontSize,
    this.iconSize,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendente';
      case 'accepted':
        return 'Aceita';
      case 'rejected':
        return 'Rejeitada';
      case 'canceled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'canceled':
        return Icons.block;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      text: _getStatusText(status),
      color: _getStatusColor(status),
      icon: _getStatusIcon(status),
      fontSize: fontSize,
      iconSize: iconSize,
    );
  }
}

class SimpleProposalStatusBadge extends StatelessWidget {
  final String status;
  final double? fontSize;

  const SimpleProposalStatusBadge({
    super.key,
    required this.status,
    this.fontSize,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'canceled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendente';
      case 'accepted':
        return 'Aceita';
      case 'rejected':
        return 'Rejeitada';
      case 'canceled':
        return 'Cancelada';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFontSize = fontSize ?? 12.0;
    final statusColor = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusText(status),
        style: TextStyle(
          color: Colors.white,
          fontSize: effectiveFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}