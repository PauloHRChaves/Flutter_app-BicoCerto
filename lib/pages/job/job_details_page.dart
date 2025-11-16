import 'dart:convert';

import 'package:bico_certo/services/job_service.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/models/job_model.dart';
import 'package:bico_certo/services/proposal_service.dart';
import 'package:bico_certo/services/chat_api_service.dart';
import 'package:bico_certo/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../services/job_state_service.dart';
import '../../utils/string_formatter.dart';
import '../../widgets/location_navigation_widget.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/user_avatar.dart';
import '../create/create_form.dart';
import 'job_proposals_page.dart';

class AppColors {
  static const primary = Color.fromARGB(255, 22, 76, 110);
  static const accent = Color.fromARGB(255, 74, 58, 255);
}

class AppDimensions {
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  static const double avatarRadius = 30.0;
  static const double spacing = 12.0;
  static const double spacingLarge = 24.0;
}

class DateFormatters {
  static String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  static String formatDateTime(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }
}

class JobHelpers {
  static int getDaysUntilDeadline(String deadline) {
    try {
      final deadlineDate = DateTime.parse(deadline);
      final now = DateTime.now();
      return deadlineDate.difference(now).inDays;
    } catch (e) {
      return 0;
    }
  }

  static Color getDeadlineColor(int days) {
    if (days <= 3) return Colors.red;
    if (days <= 7) return Colors.orange;
    return Colors.green;
  }

  static IconData getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('reforma')) return Icons.build;
    if (categoryLower.contains('assistência') || categoryLower.contains('tecnica')) {
      return Icons.electrical_services;
    }
    if (categoryLower.contains('aula')) return Icons.book;
    if (categoryLower.contains('design')) return Icons.design_services;
    if (categoryLower.contains('pintura')) return Icons.format_paint;
    if (categoryLower.contains('faxina')) return Icons.cleaning_services;
    if (categoryLower.contains('elétrica') || categoryLower.contains('eletrica')) {
      return Icons.electric_bolt;
    }
    return Icons.work;
  }
}

class ProposalStatusHelpers {
  static String getStatusText(String status) {
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

  static Color getStatusColor(String status) {
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

  static bool isActiveProposal(Map<String, dynamic>? proposal) {
    if (proposal == null) return false;
    final status = proposal['status'].toString().toLowerCase();
    return status == 'pending' || status == 'accepted';
  }
}

class JobDetailsPage extends StatefulWidget {
  final Job job;

  const JobDetailsPage({
    super.key,
    required this.job,
  });

  @override
  State<JobDetailsPage> createState() => _JobDetailsPageState();
}

class _JobDetailsPageState extends State<JobDetailsPage> {
  final ProposalService _proposalService = ProposalService();
  final ChatApiService _chatApiService = ChatApiService();
  final JobStateService _jobStateService = JobStateService();
  WebSocketChannel? _websocketChannel;
  final AuthService _authService = AuthService();
  final JobService _jobService = JobService();

  bool _isLoadingChat = false;
  late int _proposalCount;
  Map<String, dynamic>? _myProposal;
  bool _isLoadingProposal = true;
  bool _isJobOwner = false;
  bool _isCheckingOwner = true;
  bool _isProvider = false;
  late Job _currentJob;

  @override
  void initState() {
    super.initState();
    _currentJob = widget.job;
    _proposalCount = _currentJob.proposalCount;
    _checkIfJobOwner();
    _loadMyProposal();
    _checkIfProvider();

    _jobStateService.setCurrentJob(_currentJob.jobId);
    _connectWebSocket();

  }

  @override
  void dispose() {
    _jobStateService.clearCurrentJob();
    _websocketChannel?.sink.close();
    super.dispose();
  }

  Future<void> _connectWebSocket() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return;

      _websocketChannel = await _chatApiService.connectNotificationsWebSocket();

      _websocketChannel!.stream.listen(
            (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('Erro no WebSocket: $error');
        },
      );
    } catch (e) {
      print('Erro ao conectar WebSocket: $e');
    }
  }

  Future<void> _cancelOpenJob() async {
    final password = await _showCancelOpenJobDialog();
    if (password == null || password.isEmpty) return;

    _showLoadingDialog();

    try {
      final result = await _jobService.cancelOpenJob(
        jobId: _currentJob.jobId,
        password: password,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessSnackBar(result['message'] ?? 'Job cancelado com sucesso!');

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Erro ao cancelar job');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Erro ao cancelar job: $e');
      }
    }
  }

  Future<String?> _showCancelOpenJobDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _CancelOpenJobDialog(),
    );
  }

  Future<void> _rejectJob() async {
    final password = await _showRejectJobDialog();
    if (password == null || password.isEmpty) return;

    _showLoadingDialog();

    try {
      final result = await _jobService.rejectJob(
        jobId: _currentJob.jobId,
        password: password,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessSnackBar(result['message'] ?? 'Job rejeitado com sucesso!');

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Erro ao rejeitar job');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Erro ao rejeitar job: $e');
      }
    }
  }

  Future<String?> _showRejectJobDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _RejectJobDialog(),
    );
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      if (type == 'job_status_update') {
        final updateData = data['data'];
        final jobId = updateData['job_id'];

        if (jobId == _currentJob.jobId) {
          // Outras notificações
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.update, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        updateData['message'] ?? 'Job atualizado',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.blue[700],
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          _reloadJobDetails();
        }
      }
    } catch (e) {
      print('Erro ao processar mensagem WebSocket: $e');
    }
  }

  Future<void> _reloadJobDetails() async {

    try {
      final updatedJob = await _jobService.getJobById(_currentJob.jobId);

      if (updatedJob != null && mounted) {
        setState(() {
          _currentJob = updatedJob;
          _proposalCount = updatedJob.proposalCount;
        });

        await _loadMyProposal();
        await _checkIfProvider();

      }
    } catch (e) {
      print('Erro ao recarregar job: $e');
    }
  }

  Future<void> _checkIfProvider() async {
    try {
      final userWalletAddress = await _authService.getAddress();
      if (userWalletAddress != null && _currentJob.providerAddress.isNotEmpty) {
        final providerAddress = _currentJob.providerAddress.toLowerCase();
        final userAddress = userWalletAddress.toLowerCase();

        setState(() {
          _isProvider = providerAddress == userAddress;
        });
      }
    } catch (e) {
      setState(() {
        _isProvider = false;
      });
    }
  }

  Future<void> _approveJob() async {
    final result = await _showApproveJobDialog();
    if (result == null) return;

    final password = result['password'] as String;
    final rating = result['rating'] as int;

    _showLoadingDialog();

    try {
      final result = await _jobService.approveJob(
        jobId: _currentJob.jobId,
        rating: rating,
        password: password,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessSnackBar(result['message'] ?? 'Job aprovado com sucesso!');

        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Erro ao aprovar job');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Erro ao aprovar job: $e');
      }
    }
  }

  Future<Map<String, dynamic>?> _showApproveJobDialog() {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _ApproveJobDialog(),
    );
  }

  Future<void> _completeJob() async {
    final password = await _showCompleteJobDialog();
    if (password == null || password.isEmpty) return;

    _showLoadingDialog();

    try {
      final result = await _jobService.completeJob(
        jobId: _currentJob.jobId,
        password: password,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessSnackBar(result['message'] ?? 'Job concluído com sucesso!');

        // Aguardar um pouco e voltar indicando que houve mudança
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorSnackBar(result['message'] ?? 'Erro ao concluir job');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fechar loading
        _showErrorSnackBar('Erro ao concluir job: $e');
      }
    }
  }

  Future<String?> _showCompleteJobDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _CompleteJobDialog(),
    );
  }

  Future<void> _startChatWithProvider() async {
    setState(() => _isLoadingChat = true);

    try {
      final currentUserId = await _authService.getUserId();
      if (currentUserId == null) {
        throw Exception('Usuário não autenticado');
      }

      final providerId = _currentJob.providerId;

      final roomData = await _chatApiService.createChatRoom(
        jobId: _currentJob.jobId,
        providerId: providerId,
        clientId: currentUserId,
      );

      setState(() => _isLoadingChat = false);
      if (!mounted) return;

      final roomId = roomData['room_id'];
      if (roomId != null) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'roomId': roomId,
            'jobTitle': _currentJob.metadata.data.title,
          },
        );
      } else {
        throw Exception('Room ID não retornado');
      }
    } catch (e) {
      setState(() => _isLoadingChat = false);
      if (!mounted) return;
      _showErrorSnackBar('Erro ao iniciar conversa: $e');
    }
  }

  Future<void> _checkIfJobOwner() async {
    setState(() => _isCheckingOwner = true);

    try {
      final userWalletAddress = await _authService.getAddress();
      if (userWalletAddress != null) {
        final jobClientAddress = _currentJob.client.toLowerCase();
        final userAddress = userWalletAddress.toLowerCase();

        setState(() {
          _isJobOwner = jobClientAddress == userAddress;
          _isCheckingOwner = false;
        });
      } else {
        setState(() {
          _isJobOwner = false;
          _isCheckingOwner = false;
        });
      }
    } catch (e) {
      setState(() {
        _isJobOwner = false;
        _isCheckingOwner = false;
      });
    }
  }

  Future<void> _loadMyProposal() async {
    if (_isJobOwner) {
      setState(() => _isLoadingProposal = false);
      return;
    }

    setState(() => _isLoadingProposal = true);

    try {
      final proposal = await _proposalService.getMyProposalForJob(_currentJob.jobId);
      if (mounted) {
        setState(() {
          _myProposal = proposal;
          _isLoadingProposal = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProposal = false);
      }
    }
  }

  void _onProposalSubmitted() {
    setState(() => _proposalCount++);
    Navigator.pop(context, true);
    _loadMyProposal();
  }

  Future<void> _cancelProposal() async {
    if (_myProposal == null) return;

    final password = await _showCancelDialog();
    if (password == null || password.isEmpty) return;

    _showLoadingDialog();

    try {
      final result = await _proposalService.cancelProposal(
        proposalId: _myProposal!['proposal_id'],
        password: password,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        setState(() {
          _myProposal = null;
          _proposalCount = _proposalCount > 0 ? _proposalCount - 1 : 0;
        });
        _showSuccessSnackBar(result['message'] ?? 'Proposta cancelada com sucesso');
        Navigator.pop(context, true);
      } else {
        _showErrorSnackBar(result['message'] ?? 'Erro ao cancelar proposta');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Erro ao cancelar proposta: $e');
      }
    }
  }

  Future<String?> _showCancelDialog() {
    return showDialog<String>(
      context: context,
      builder: (context) => const _CancelProposalDialog(),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: AppDimensions.spacing),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showProposalDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ProposalForm(
          job: _currentJob,
          proposalService: _proposalService,
          onProposalSubmitted: _onProposalSubmitted,
        ),
      ),
    );
  }

  Future<void> _startChatWithClient() async {
    setState(() => _isLoadingChat = true);

    try {
      final currentUserId = await _authService.getUserId();
      if (currentUserId == null) {
        throw Exception('Usuário não autenticado');
      }

      final roomData = await _chatApiService.createChatRoom(
        jobId: _currentJob.jobId,
        providerId: currentUserId,
        clientId: _currentJob.metadata.data.employer.userId,
      );

      setState(() => _isLoadingChat = false);
      if (!mounted) return;

      final roomId = roomData['room_id'];
      if (roomId != null) {
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'roomId': roomId,
            'jobTitle': _currentJob.metadata.data.title,
          },
        );
      } else {
        throw Exception('Room ID não retornado');
      }
    } catch (e) {
      setState(() => _isLoadingChat = false);
      if (!mounted) return;
      _showErrorSnackBar('Erro ao iniciar conversa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveProposal = ProposalStatusHelpers.isActiveProposal(_myProposal);
    final isLoading = _isCheckingOwner || _isLoadingProposal;
    final isInProgress = _currentJob.status != JobStatus.open;
    final isCanceled = _currentJob.status == JobStatus.cancelled;
    final isAcceptedOrInProgress = _currentJob.status == JobStatus.accepted ||
        _currentJob.status == JobStatus.inProgress;

    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _JobHeader(
              job: _currentJob,
              proposalCount: _proposalCount,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isJobOwner && _currentJob.status == JobStatus.open)
                    _OwnerSection(
                      job: _currentJob,
                      proposalCount: _proposalCount,
                      onCancelJob: _cancelOpenJob,
                    ),
                    if (_isJobOwner && _currentJob.status == JobStatus.completed)
                        _ApproveJobSection(
                        job: _currentJob,
                        onApproveJob: _approveJob,
                        onRejectJob: _rejectJob,
                      ),
                  if (!_isJobOwner) ...[
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (hasActiveProposal)
                      _MyProposalSection(
                        proposal: _myProposal!,
                        onCancel: _cancelProposal,
                      ),
                    if (!isLoading && _isProvider && isAcceptedOrInProgress)
                      _CompleteJobSection(
                        onCompleteJob: _completeJob,
                        jobStatus: _currentJob.status,
                      ),
                    if (_currentJob.status == JobStatus.completed)
                      _ApprovalTimerCard(job: _currentJob),
                  ],
                  if (!isLoading && (_isJobOwner || _currentJob.status == JobStatus.open)) ...[
                    _BudgetSection(maxBudget: _currentJob.maxBudget, job: _currentJob),
                    const SizedBox(height: AppDimensions.spacingLarge),
                  ],
                  _DescriptionSection(description: _currentJob.metadata.data.description),
                  const SizedBox(height: AppDimensions.spacingLarge),
                  _InformationSection(job: _currentJob),
                  const SizedBox(height: AppDimensions.spacingLarge),
                  if (_isJobOwner && isInProgress && !isCanceled)
                    _ProviderSection(
                      job: _currentJob,
                      isLoadingChat: _isLoadingChat,
                      onChatPressed: _startChatWithProvider,
                    ),
                  if (!_isJobOwner)
                    _ClientSection(
                      job: _currentJob,
                      isLoadingChat: _isLoadingChat,
                      onChatPressed: _startChatWithClient,
                    ),
                  if (_proposalCount > 0 && !hasActiveProposal && !_isJobOwner)
                    _ProposalStatusSection(proposalCount: _proposalCount),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _isJobOwner || isInProgress
          ? null
          : _BottomActionBar(
        hasActiveProposal: hasActiveProposal,
        isLoadingProposal: isLoading,
        onSendProposal: _showProposalDialog,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Detalhes do Job',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white
    );
  }
}

class _ApprovalTimerCard extends StatelessWidget {
  final Job job;

  const _ApprovalTimerCard({required this.job});

  Map<String, dynamic>? _getApprovalDeadlineInfo() {
    try {
      if (job.status != JobStatus.completed) return null;

      final completedAtStr = job.completedAt;
      if (completedAtStr.isEmpty) return null;

      final completedAt = DateTime.parse(completedAtStr);
      final approvalDeadline = completedAt.add(const Duration(days: 3));
      final now = DateTime.now();
      final timeRemaining = approvalDeadline.difference(now);

      return {
        'completedAt': completedAt,
        'deadline': approvalDeadline,
        'timeRemaining': timeRemaining,
        'isExpired': timeRemaining.isNegative,
        'hoursRemaining': timeRemaining.inHours.abs(),
        'daysRemaining': timeRemaining.inDays.abs(),
      };
    } catch (e) {
      return null;
    }
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return '$days ${days == 1 ? 'dia' : 'dias'} e $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '$hours ${hours == 1 ? 'hora' : 'horas'} e $minutes min';
    } else {
      final minutes = duration.inMinutes;
      return '$minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final approvalInfo = _getApprovalDeadlineInfo();

    if (approvalInfo == null) return const SizedBox.shrink();

    final isExpired = approvalInfo['isExpired'] as bool;
    final timeRemaining = approvalInfo['timeRemaining'] as Duration;
    final completedAt = approvalInfo['completedAt'] as DateTime;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.timer,
          title: 'Prazo de Aprovação',
        ),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isExpired
                  ? [Colors.red[50]!, Colors.red[100]!]
                  : [Colors.amber[50]!, Colors.orange[50]!],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(
              color: isExpired ? Colors.red[300]! : Colors.orange[300]!,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red[100] : Colors.orange[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpired ? Icons.warning_amber : Icons.hourglass_bottom,
                      color: isExpired ? Colors.red[700] : Colors.orange[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpired
                              ? 'Prazo de Aprovação Expirado!'
                              : 'Aguardando Aprovação do Cliente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isExpired ? Colors.red[900] : Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isExpired
                              ? 'O prazo para aprovação já passou'
                              : 'O cliente tem até 3 dias para aprovar',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? Colors.red[700] : Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                height: 1,
                color: isExpired ? Colors.red[200] : Colors.orange[200],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 22,
                      color: isExpired ? Colors.red[600] : Colors.orange[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isExpired ? 'Tempo Expirado' : 'Tempo Restante',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isExpired
                                ? 'Expirou há ${_formatTimeRemaining(timeRemaining.abs())}'
                                : _formatTimeRemaining(timeRemaining),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.red[700] : Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Data de conclusão
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 22,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trabalho Concluído em',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatters.formatDateTime(completedAt.toIso8601String()),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (!isExpired) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Após a aprovação, o pagamento será liberado automaticamente.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
      ],
    );
  }
}

class _OwnerSection extends StatelessWidget {
  final Job job;
  final int proposalCount;
  final VoidCallback? onCancelJob; // ✅ ADICIONAR

  const _OwnerSection({
    required this.job,
    required this.proposalCount,
    this.onCancelJob, // ✅ ADICIONAR
  });

  IconData _getJobStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return Icons.check_circle_outline;
      case JobStatus.created:
        return Icons.add_circle_outline;
      case JobStatus.accepted:
      case JobStatus.inProgress:
        return Icons.construction_outlined;
      case JobStatus.completed:
        return Icons.task_alt;
      case JobStatus.approved:
        return Icons.verified;
      case JobStatus.cancelled:
        return Icons.cancel_outlined;
      case JobStatus.disputed:
        return Icons.warning_amber;
      case JobStatus.refunded:
        return Icons.payment;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInProgress = job.status == JobStatus.inProgress || job.status == JobStatus.accepted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: Colors.blue[300]!, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  if (isInProgress)
                    Expanded(
                      child: _StatCard(
                        icon: _getJobStatusIcon(job.status),
                        label: 'Status',
                        value: job.status.displayName,
                        color: job.status.color,
                      ),
                    )
                  else ...[
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_outline,
                        label: 'Propostas',
                        value: proposalCount.toString(),
                        color: Colors.orange,
                      ),
                    )
                  ],
                ],
              ),
              const SizedBox(height: 16),
              if (!isInProgress) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobProposalsPage(job: job),
                        ),
                      );

                      if (result == true && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                    icon: const Icon(Icons.list_alt),
                    label: Text(
                      proposalCount > 0
                          ? 'Ver $proposalCount Proposta${proposalCount != 1 ? 's' : ''}'
                          : 'Ver Propostas',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCancelJob,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar Pedido'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red, width: 2),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _JobHeader extends StatelessWidget {
  final Job job;
  final int proposalCount;

  const _JobHeader({
    required this.job,
    required this.proposalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryIconBadge(category: job.category),
              const SizedBox(width: 16),
              Expanded(
                child: _JobTitleAndCategory(
                  title: job.metadata.data.title,
                  category: job.category,
                ),
              ),
              const SizedBox(width: 12),
              // Status do Job
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: job.status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      job.status.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryIconBadge extends StatelessWidget {
  final String category;

  const _CategoryIconBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Icon(
        JobHelpers.getCategoryIcon(category),
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

class _JobTitleAndCategory extends StatelessWidget {
  final String title;
  final String category;

  const _JobTitleAndCategory({
    required this.title,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          child: Text(
            category,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MyProposalSection extends StatelessWidget {
  final Map<String, dynamic> proposal;
  final VoidCallback onCancel;

  const _MyProposalSection({
    required this.proposal,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = proposal['status'].toString().toLowerCase() == 'pending';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.assignment_turned_in,
          title: 'Minha Proposta',
        ),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProposalStatusRow(status: proposal['status']),
              const Divider(height: 24),
              _ProposalDetailRow(
                icon: Icons.attach_money,
                iconColor: Colors.green[700]!,
                label: 'Valor: ',
                value: 'R\$ ${StringFormatter.formatAmount(proposal['amount'])}',
                valueColor: Colors.green[700],
              ),
              const SizedBox(height: AppDimensions.spacing),
              _ProposalDetailRow(
                icon: Icons.calendar_today,
                iconColor: Colors.blue[700]!,
                label: 'Prazo estimado: ',
                value: '${proposal['estimated_time_days']} dias',
              ),
              const SizedBox(height: AppDimensions.spacing),
              _ProposalDetailRow(
                icon: Icons.schedule,
                iconColor: Colors.purple[700]!,
                label: 'Enviada em: ',
                value: DateFormatters.formatDateTime(proposal['created_at']),
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancelar Proposta'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.red, width: 2),
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
      ],
    );
  }
}

class _ProposalStatusRow extends StatelessWidget {
  final String status;

  const _ProposalStatusRow({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        SimpleProposalStatusBadge(
          status: status,
          fontSize: 12,
        ),
      ],
    );
  }
}

class _ProposalDetailRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _ProposalDetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _BudgetSection extends StatelessWidget {
  final double maxBudget;
  final Job job;

  const _BudgetSection({
    required this.maxBudget,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    final isInProgress = job.status == JobStatus.inProgress ||
        job.status == JobStatus.accepted ||
        job.status == JobStatus.completed;

    final title = isInProgress ? 'Custo' : 'Orçamento Máximo';
    final subtitle = 'O cliente está disposto a pagar até este valor';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.attach_money,
          title: isInProgress ? 'Valor do Serviço' : 'Orçamento',
        ),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green[200]!, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if(!isInProgress)...[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'R\$ ${StringFormatter.formatAmount(maxBudget)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[900],
                ),
              ),
              if(!isInProgress) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.green[700]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String description;

  const _DescriptionSection({required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.description, title: 'Descrição'),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Text(
            description,
            style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}

class _InformationSection extends StatelessWidget {
  final Job job;

  const _InformationSection({required this.job});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.info_outline, title: 'Informações'),
        const SizedBox(height: AppDimensions.spacing),
        LocationNavigationWidget(
          locationString: job.metadata.data.location,
          color: Colors.red,
        ),
        const SizedBox(height: AppDimensions.spacing),
        _InfoRow(
          icon: Icons.schedule,
          label: 'Publicado em',
          value: DateFormatters.formatDateTime(job.metadata.data.createdAt),
          color: Colors.purple,
        ),
        const SizedBox(height: AppDimensions.spacing),
      ],
    );
  }
}

class _DeadlineInfoCard extends StatelessWidget {
  final Job job;

  const _DeadlineInfoCard({required this.job});

  Map<String, dynamic> _getDeadlineInfo() {
    try {
      final acceptedDate = DateTime.parse(job.acceptedAt);
      final estimatedDays = job.proposalEstimatedTimeDays;
      final deadline = acceptedDate.add(Duration(days: estimatedDays));
      final now = DateTime.now();
      final daysRemaining = deadline.difference(now).inDays;
      final isLate = daysRemaining < 0;

      return {
        'deadline': deadline,
        'daysRemaining': daysRemaining.abs(),
        'isLate': isLate,
        'estimatedDays': estimatedDays,
        'acceptedDate': acceptedDate,
      };
    } catch (e) {
      return {
        'deadline': DateTime.now(),
        'daysRemaining': 0,
        'isLate': false,
        'estimatedDays': 7,
        'acceptedDate': DateTime.now(),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _getDeadlineInfo();
    final isLate = info['isLate'] as bool;
    final daysRemaining = info['daysRemaining'] as int;
    final estimatedDays = info['estimatedDays'] as int;
    final deadline = info['deadline'] as DateTime;
    final acceptedDate = info['acceptedDate'] as DateTime;

    final statusColor = isLate ? Colors.red : Colors.green;
    final statusIcon = isLate ? Icons.warning : Icons.check_circle_outline;
    final statusText = isLate
        ? 'Atrasado em $daysRemaining ${daysRemaining == 1 ? 'dia' : 'dias'}'
        : '$daysRemaining ${daysRemaining == 1 ? 'dia' : 'dias'} restantes';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLate ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(
          color: isLate ? Colors.red[200]! : Colors.green[200]!,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prazo do Serviço',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DeadlineDetail(
                  icon: Icons.play_arrow,
                  label: 'Iniciado em',
                  value: DateFormatters.formatDate(acceptedDate.toIso8601String()),
                  color: Colors.blue,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              Expanded(
                child: _DeadlineDetail(
                  icon: Icons.flag,
                  label: 'Prazo final',
                  value: DateFormatters.formatDate(deadline.toIso8601String()),
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Prazo estimado: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '$estimatedDays ${estimatedDays == 1 ? 'dia' : 'dias'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineDetail extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DeadlineDetail({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ClientSection extends StatefulWidget {
  final Job job;
  final bool isLoadingChat;
  final VoidCallback onChatPressed;

  const _ClientSection({
    required this.job,
    required this.isLoadingChat,
    required this.onChatPressed,
  });

  @override
  State<_ClientSection> createState() => _ClientSectionState();
}

class _ClientSectionState extends State<_ClientSection> {
  final JobService _jobService = JobService();
  Map<String, dynamic>? _reputation;
  bool _isLoadingReputation = true;

  @override
  void initState() {
    super.initState();
    _loadClientReputation();
  }

  Future<void> _loadClientReputation() async {
    setState(() => _isLoadingReputation = true);

    try {
      final result = await _jobService.getUserReputation(widget.job.client, true);

      if (mounted && result['success'] == true) {
        setState(() {
          _reputation = result['reputation'];
          _isLoadingReputation = false;
        });
      } else {
        setState(() => _isLoadingReputation = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReputation = false);
      }
    }
  }

  String _getAccountAge(int? timestamp) {
    if (timestamp == null || timestamp == 0) return 'Recente';

    try {
      final joinedDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final now = DateTime.now();
      final difference = now.difference(joinedDate);

      if (difference.inDays < 30) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dias'}';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months} ${months == 1 ? 'mês' : 'meses'}';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years} ${years == 1 ? 'ano' : 'anos'}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  double _calculateStarRating(int? reputationScore) {
    if (reputationScore == null) return 0.0;
    final stars = (reputationScore / 100.0);
    return stars.clamp(0.0, 5.0);
  }

  Color _getReputationColor(int? reputationScore) {
    if (reputationScore == null || reputationScore == 0) {
      return Colors.grey;
    } else if (reputationScore < 100) {
      return Colors.red[700]!;
    } else if (reputationScore < 200) {
      return Colors.orange[700]!;
    } else if (reputationScore < 300) {
      return Colors.yellow[700]!;
    } else if (reputationScore < 400) {
      return Colors.lightGreen[700]!;
    } else {
      return Colors.green[700]!;
    }
  }

  String _getReputationText(int? reputationScore) {
    if (reputationScore == null || reputationScore == 0) {
      return 'Sem avaliações';
    } else if (reputationScore <= 100) {
      return 'Iniciante';
    } else if (reputationScore <= 200) {
      return 'Regular';
    } else if (reputationScore <= 300) {
      return 'Bom';
    } else if (reputationScore <= 400) {
      return 'Muito Bom';
    } else {
      return 'Excelente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.person, title: 'Cliente'),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  UserAvatar(
                    userId: widget.job.metadata.data.employer.userId,
                    userName: widget.job.metadata.data.employer.name,
                    radius: AppDimensions.avatarRadius,
                    backgroundColor: Colors.blue[700]!,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.metadata.data.employer.name ?? 'Cliente',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business_center,
                              size: 14,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Contratante',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoadingReputation)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_reputation != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ClientStatItem(
                              label: 'Jobs Concluidos',
                              value: '${_reputation!['totalJobs'] ?? 0}',
                              color: Colors.blue[700]!,
                              icon: Icons.work_outline,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber[700],
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                _StarRating(
                                  rating: _calculateStarRating(_reputation!['averageRating']),
                                  size: 14,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getReputationText(_reputation!['averageRating']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getReputationColor(_reputation!['averageRating']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: Colors.grey[300]),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Membro há ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            _getAccountAge(_reputation!['joinedAt']),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.isLoadingChat ? null : widget.onChatPressed,
                  icon: widget.isLoadingChat
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.chat_bubble_outline),
                  label: Text(widget.isLoadingChat ? 'Iniciando...' : 'Conversar com Cliente'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.blue[700]!, width: 2),
                    foregroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _calculateApprovalRate() {
    if (_reputation == null) return '0';

    final jobsCreated = _reputation!['jobsCreated'] ?? 0;
    final approvedJobs = _reputation!['approvedJobs'] ?? 0;

    if (jobsCreated == 0) return '0';

    final rate = (approvedJobs / jobsCreated) * 100;
    return rate.toStringAsFixed(0);
  }
}

class _ClientStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ClientStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ProviderSection extends StatefulWidget {
  final Job job;
  final bool isLoadingChat;
  final VoidCallback onChatPressed;

  const _ProviderSection({
    required this.job,
    required this.isLoadingChat,
    required this.onChatPressed,
  });

  @override
  State<_ProviderSection> createState() => _ProviderSectionState();
}

class _ProviderSectionState extends State<_ProviderSection> {
  final JobService _jobService = JobService();
  Map<String, dynamic>? _reputation;
  bool _isLoadingReputation = true;

  @override
  void initState() {
    super.initState();
    _loadProviderReputation();
  }

  Future<void> _loadProviderReputation() async {
    setState(() => _isLoadingReputation = true);

    try {
      final result = await _jobService.getUserReputation(widget.job.providerAddress, false);

      if (mounted && result['success'] == true) {
        setState(() {
          _reputation = result['reputation'];
          _isLoadingReputation = false;
        });
      } else {
        setState(() => _isLoadingReputation = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReputation = false);
      }
    }
  }

  String _getAccountAge(int? timestamp) {
    if (timestamp == null || timestamp == 0) return 'Recente';

    try {
      final joinedDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      final now = DateTime.now();
      final difference = now.difference(joinedDate);

      if (difference.inDays < 30) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'dia' : 'dias'}';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return '${months} ${months == 1 ? 'mês' : 'meses'}';
      } else {
        final years = (difference.inDays / 365).floor();
        return '${years} ${years == 1 ? 'ano' : 'anos'}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  double _calculateStarRating(int? reputationScore) {
    if (reputationScore == null) return 0.0;
    final stars = (reputationScore / 100.0);
    return stars.clamp(0.0, 5.0);
  }

  Color _getReputationColor(int? reputationScore) {
    if (reputationScore == null || reputationScore == 0) {
      return Colors.grey;
    } else if (reputationScore < 100) {
      return Colors.red[700]!;
    } else if (reputationScore < 200) {
      return Colors.orange[700]!;
    } else if (reputationScore < 300) {
      return Colors.yellow[700]!;
    } else if (reputationScore < 400) {
      return Colors.lightGreen[700]!;
    } else {
      return Colors.green[700]!;
    }
  }

  String _getReputationText(int? reputationScore) {
    if (reputationScore == null || reputationScore == 0) {
      return 'Sem avaliações';
    } else if (reputationScore < 100) {
      return 'Iniciante';
    } else if (reputationScore < 200) {
      return 'Regular';
    } else if (reputationScore < 300) {
      return 'Bom';
    } else if (reputationScore < 400) {
      return 'Muito Bom';
    } else {
      return 'Excelente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(icon: Icons.person_outline, title: 'Prestador de Serviço'),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  UserAvatar(
                    userId: widget.job.providerId,
                    userName: widget.job.providerName,
                    radius: AppDimensions.avatarRadius,
                    backgroundColor: Colors.purple[700]!,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.job.providerName ?? 'Prestador',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.purple[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Proposta aceita',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoadingReputation)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_reputation != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[100]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _ProviderStatItem(
                              label: 'Serviços Concluídos',
                              value: '${_reputation!['totalJobs'] ?? 0}',
                              color: Colors.green[700]!,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey[300],
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.amber[700],
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                _StarRating(
                                  rating: _calculateStarRating(_reputation!['averageRating']),
                                  size: 14,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getReputationText(_reputation!['averageRating']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getReputationColor(_reputation!['averageRating']),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(height: 1, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Membro há ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            _getAccountAge(_reputation!['joinedAt']),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.isLoadingChat ? null : widget.onChatPressed,
                  icon: widget.isLoadingChat
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.chat_bubble_outline),
                  label: Text(widget.isLoadingChat ? 'Iniciando...' : 'Conversar com Prestador'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: Colors.purple[700]!, width: 2),
                    foregroundColor: Colors.purple[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
        _DeadlineInfoCard(job: widget.job),
      ],
    );
  }
}

class _ProviderStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ProviderStatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _StarRating extends StatelessWidget {
  final double rating;
  final double size;

  const _StarRating({
    required this.rating,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(
            Icons.star,
            size: size,
            color: Colors.amber[700],
          );
        } else if (index < rating) {
          return Icon(
            Icons.star_half,
            size: size,
            color: Colors.amber[700],
          );
        } else {
          return Icon(
            Icons.star_border,
            size: size,
            color: Colors.amber[700],
          );
        }
      }),
    );
  }
}

class _ProposalStatusSection extends StatelessWidget {
  final int proposalCount;

  const _ProposalStatusSection({required this.proposalCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppDimensions.spacingLarge),
        const _SectionTitle(icon: Icons.assignment, title: 'Status das Propostas'),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 24),
              const SizedBox(width: AppDimensions.spacing),
              Expanded(
                child: Text(
                  'Este job já possui $proposalCount proposta(s). Envie a sua e destaque-se!',
                  style: TextStyle(fontSize: 14, color: Colors.orange[900]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool hasActiveProposal;
  final bool isLoadingProposal;
  final VoidCallback onSendProposal;

  const _BottomActionBar({
    required this.hasActiveProposal,
    required this.isLoadingProposal,
    required this.onSendProposal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: hasActiveProposal
            ? _buildProposalSentButton()
            : _buildSendProposalButton(isLoadingProposal, onSendProposal),
      ),
    );
  }

  Widget _buildProposalSentButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.grey),
          SizedBox(width: 8),
          Text(
            'Proposta Enviada',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendProposalButton(bool isLoading, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        elevation: 3,
      ),
      child: isLoading
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.send, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Enviar Proposta',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: AppDimensions.iconSize),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppDimensions.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelProposalDialog extends StatefulWidget {
  const _CancelProposalDialog();

  @override
  State<_CancelProposalDialog> createState() => _CancelProposalDialogState();
}

class _CancelProposalDialogState extends State<_CancelProposalDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: AppDimensions.spacing),
          Text('Cancelar Proposta'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tem certeza que deseja cancelar sua proposta? Esta ação não pode ser desfeita.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha da Carteira',
              hintText: 'Digite sua senha',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Não, manter'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, digite sua senha'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, _passwordController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Sim, cancelar'),
        ),
      ],
    );
  }
}

class _ProposalForm extends StatefulWidget {
  final Job job;
  final ProposalService proposalService;
  final VoidCallback onProposalSubmitted;

  const _ProposalForm({
    required this.job,
    required this.proposalService,
    required this.onProposalSubmitted,
  });

  @override
  State<_ProposalForm> createState() => _ProposalFormState();
}

class _ProposalFormState extends State<_ProposalForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _timeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _timeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await widget.proposalService.submitProposal(
        jobId: widget.job.jobId,
        description: _descriptionController.text.trim(),
        amountEth: double.parse((_amountController.text.replaceAll(".", "")).replaceAll(",", ".")),
        estimatedTimeDays: int.parse(_timeController.text),
        password: _passwordController.text,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      Navigator.pop(context);

      if (result['success'] == true) {
        widget.onProposalSubmitted();
        _showSuccessMessages(result);
      } else {
        _showErrorMessage(result['message'] ?? 'Erro ao enviar proposta');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      _showErrorMessage('Erro ao enviar proposta: $e');
    }
  }

  void _showSuccessMessages(Map<String, dynamic> result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: AppDimensions.spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Proposta enviada!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    result['message'] ?? 'Sua proposta foi enviada com sucesso',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: AppDimensions.spacing),
            Text('Proposta Enviada'),
          ],
        ),
        content: const Text(
          'Sua proposta foi enviada com sucesso! '
              'O cliente receberá uma notificação e poderá entrar em contato com você.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildBudgetInfo(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildTimeField(),
            const SizedBox(height: 16),
            _buildPasswordField(),
            const SizedBox(height: 8),
            _buildPasswordHint(),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Enviar Proposta',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildBudgetInfo() {
    return Text(
      'Orçamento máximo: R\$ ${StringFormatter.formatAmount(widget.job.maxBudget)}',
      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: 'Descrição da sua proposta',
        hintText: 'Descreva como você realizará o trabalho...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        prefixIcon: const Icon(Icons.description),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, descreva sua proposta';
        }
        return null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [
        CurrencyInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Valor da proposta (R\$)',
        hintText: '0,00',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        prefixIcon: const Icon(Icons.attach_money),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe o valor';
        }
        final amount = double.tryParse((value.replaceAll(".", "")).replaceAll(",", "."));
        if (amount == null || amount <= 0) {
          return 'Valor inválido';
        }
        if (amount > widget.job.maxBudget) {
          return 'Valor acima do orçamento máximo';
        }
        return null;
      },
    );
  }

  Widget _buildTimeField() {
    return TextFormField(
      controller: _timeController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Tempo estimado (dias)',
        hintText: 'Ex: 7',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        prefixIcon: const Icon(Icons.calendar_today),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe o tempo estimado';
        }
        final days = int.tryParse(value);
        if (days == null || days <= 0) {
          return 'Tempo inválido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Senha da Carteira',
        hintText: 'Digite sua senha para assinar a transação',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, informe sua senha';
        }
        if (value.length < 6) {
          return 'A senha deve ter pelo menos 6 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordHint() {
    return Text(
      'Sua senha é necessária para assinar a transação na blockchain',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitProposal,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Enviar Proposta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ApproveJobSection extends StatelessWidget {
  final Job job;
  final VoidCallback onApproveJob;
  final VoidCallback onRejectJob;

  const _ApproveJobSection({
    required this.job,
    required this.onApproveJob,
    required this.onRejectJob,
  });

  Map<String, dynamic>? _getApprovalDeadlineInfo() {
    try {
      final completedAtStr = job.completedAt;
      if (completedAtStr.isEmpty) return null;

      final completedAt = DateTime.parse(completedAtStr);
      final approvalDeadline = completedAt.add(const Duration(days: 3));
      final now = DateTime.now();
      final timeRemaining = approvalDeadline.difference(now);

      return {
        'timeRemaining': timeRemaining,
        'isExpired': timeRemaining.isNegative,
      };
    } catch (e) {
      return null;
    }
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return '$days ${days == 1 ? 'dia' : 'dias'} e $hours ${hours == 1 ? 'hora' : 'horas'}';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      return '$hours ${hours == 1 ? 'hora' : 'horas'}';
    } else {
      final minutes = duration.inMinutes;
      return '$minutes ${minutes == 1 ? 'minuto' : 'minutos'}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final approvalInfo = _getApprovalDeadlineInfo();
    final isExpired = approvalInfo?['isExpired'] ?? false;
    final timeRemaining = approvalInfo?['timeRemaining'] as Duration?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.task_alt,
          title: 'Aprovação do Trabalho',
        ),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isExpired
                  ? [Colors.red[50]!, Colors.red[100]!]
                  : [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(
              color: isExpired ? Colors.red[300]! : Colors.blue[300]!,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red[600] : Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpired ? Icons.warning_amber : Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isExpired
                              ? 'Prazo de Aprovação Expirado!'
                              : 'Trabalho Aguardando Aprovação',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isExpired ? Colors.red[900] : Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isExpired
                              ? 'Aprove ou rejeite o trabalho'
                              : 'O prestador concluiu o trabalho',
                          style: TextStyle(
                            fontSize: 12,
                            color: isExpired ? Colors.red[700] : Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (timeRemaining != null && !isExpired) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Tempo restante: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        _formatTimeRemaining(timeRemaining),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRejectJob,
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeitar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.red, width: 2),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onApproveJob,
                      icon: const Icon(Icons.verified, color: Colors.white),
                      label: const Text('Aprovar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isExpired ? Colors.red[600] : Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ao aprovar, você avaliará o trabalho e liberará o pagamento. Ao rejeitar, o trabalho voltará para o status "Em Progresso".',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
      ],
    );
  }
}

class _ApproveJobDialog extends StatefulWidget {
  const _ApproveJobDialog();

  @override
  State<_ApproveJobDialog> createState() => _ApproveJobDialogState();
}

class _ApproveJobDialogState extends State<_ApproveJobDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  int _rating = 5;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.verified, color: Colors.blue),
          SizedBox(width: AppDimensions.spacing),
          Text('Aprovar Trabalho'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Você está prestes a aprovar este trabalho. '
                  'O pagamento será liberado automaticamente para o prestador.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Avaliação com estrelas
            const Text(
              'Avalie o trabalho do prestador:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: Colors.amber[700],
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                  );
                }),
              ),
            ),
            Center(
              child: Text(
                _getRatingText(_rating),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Campo de senha
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Senha da Carteira',
                hintText: 'Digite sua senha',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                ),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, digite sua senha'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, {
              'password': _passwordController.text,
              'rating': _rating,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Aprovar'),
        ),
      ],
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Muito Ruim';
      case 2:
        return 'Ruim';
      case 3:
        return 'Regular';
      case 4:
        return 'Bom';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}


class _CompleteJobSection extends StatelessWidget {
  final VoidCallback onCompleteJob;
  final JobStatus jobStatus;

  const _CompleteJobSection({
    required this.onCompleteJob,
    required this.jobStatus,
  });

  @override
  Widget build(BuildContext context) {
    final canComplete = jobStatus == JobStatus.inProgress || jobStatus == JobStatus.accepted;

    if (!canComplete) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.construction,
          title: 'Ações do Prestador',
        ),
        const SizedBox(height: AppDimensions.spacing),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green[50]!, Colors.green[100]!],
            ),
            borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
            border: Border.all(color: Colors.green[300]!, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.work,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trabalho em Andamento',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Finalizou o serviço? Marque como concluído!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onCompleteJob,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text('Concluir Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Após concluir, o cliente deverá aprovar o trabalho para você receber o pagamento.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.spacingLarge),
      ],
    );
  }
}

class _CompleteJobDialog extends StatefulWidget {
  const _CompleteJobDialog();

  @override
  State<_CompleteJobDialog> createState() => _CompleteJobDialogState();
}

class _CompleteJobDialogState extends State<_CompleteJobDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: AppDimensions.spacing),
          Text('Concluir Job'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Você está prestes a marcar este job como concluído. '
                'O cliente deverá aprovar o trabalho para você receber o pagamento.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha da Carteira',
              hintText: 'Digite sua senha',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, digite sua senha'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, _passwordController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _CancelOpenJobDialog extends StatefulWidget {
  const _CancelOpenJobDialog();

  @override
  State<_CancelOpenJobDialog> createState() => _CancelOpenJobDialogState();
}

class _CancelOpenJobDialogState extends State<_CancelOpenJobDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: AppDimensions.spacing),
          Expanded(child: Text('Cancelar Job')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tem certeza que deseja cancelar este job? O valor depositado será devolvido para sua carteira.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Esta ação não pode ser desfeita.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha da Carteira',
              hintText: 'Digite sua senha',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, digite sua senha'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, _passwordController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar Cancelamento'),
        ),
      ],
    );
  }
}

class _RejectJobDialog extends StatefulWidget {
  const _RejectJobDialog();

  @override
  State<_RejectJobDialog> createState() => _RejectJobDialogState();
}

class _RejectJobDialogState extends State<_RejectJobDialog> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(Icons.cancel, color: Colors.red),
          SizedBox(width: AppDimensions.spacing),
          Expanded(child: Text('Rejeitar Trabalho')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tem certeza que deseja rejeitar este trabalho? O trabalho voltará para o estado anterior, só sendo possivel aprovar quando o prestador finalizar novamente.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, size: 18, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use esta opção apenas se o trabalho não foi realizado adequadamente.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Senha da Carteira',
              hintText: 'Digite sua senha',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
              ),
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Voltar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_passwordController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Por favor, digite sua senha'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }
            Navigator.pop(context, _passwordController.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirmar Rejeição'),
        ),
      ],
    );
  }
}