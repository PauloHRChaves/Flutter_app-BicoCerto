// job_proposals_page.dart - SUBSTITUIR O ARQUIVO INTEIRO

import 'package:bico_certo/utils/string_formatter.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/models/job_model.dart';
import 'package:bico_certo/services/job_service.dart';

import '../../widgets/user_avatar.dart';
import 'job_details_page.dart';

class JobProposalsPage extends StatefulWidget {
  final Job job;

  const JobProposalsPage({
    super.key,
    required this.job,
  });

  @override
  State<JobProposalsPage> createState() => _JobProposalsPageState();
}

class _JobProposalsPageState extends State<JobProposalsPage> {
  final JobService _jobService = JobService();

  List<Map<String, dynamic>> _proposals = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  Future<void> _loadProposals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final proposals = await _jobService.getJobProposals(widget.job.jobId);

      setState(() {
        _proposals = proposals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptProposal(String proposalId) async {
    final password = await _showPasswordDialog('Aceitar Proposta');

    if (password == null || password.isEmpty) return;

    _showLoadingDialog();

    try {
      final result = await _jobService.acceptProposal(
        proposalId: proposalId,
        password: password,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessSnackBar(result['message'] ?? 'Proposta aceita com sucesso');
        Navigator.pop(context, true);
        _loadProposals();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Erro ao aceitar proposta');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Erro ao aceitar proposta: $e');
      }
    }
  }

  Future<void> _rejectProposal(String proposalId) async {
    final password = await _showPasswordDialog('Rejeitar Proposta');

    if (password == null || password.isEmpty) return;

    _showLoadingDialog();

    try {
      final result = await _jobService.rejectProposal(
        proposalId: proposalId,
        password: password,
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (result['success'] == true) {
        _showSuccessSnackBar(result['message'] ?? 'Proposta rejeitada');
        _loadProposals();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Erro ao rejeitar proposta');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showErrorSnackBar('Erro ao rejeitar proposta: $e');
      }
    }
  }

  Future<String?> _showPasswordDialog(String action) {
    final TextEditingController passwordController = TextEditingController();
    bool obscurePassword = true;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock, color: Colors.blue),
              const SizedBox(width: 12),
              Text(action),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Digite sua senha para confirmar a ação:',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Senha da Carteira',
                  hintText: 'Digite sua senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
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
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, digite sua senha'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, passwordController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
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
            const SizedBox(width: 12),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Propostas Recebidas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 76, 110),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Job Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 22, 76, 110),
                  const Color.fromARGB(255, 22, 76, 110).withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.job.metadata.data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    Text(
                      'Orçamento: R\$ ${StringFormatter.formatAmount(widget.job.maxBudget)}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.people, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${_proposals.length} propostas',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Proposals List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget()
                : _proposals.isEmpty
                ? _buildEmptyWidget()
                : RefreshIndicator(
              onRefresh: _loadProposals,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _proposals.length,
                itemBuilder: (context, index) {
                  return ProposalCard(
                    proposal: _proposals[index],
                    onAccept: () => _acceptProposal(
                      _proposals[index]['proposal_id'],
                    ),
                    onReject: () => _rejectProposal(
                      _proposals[index]['proposal_id'],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar propostas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProposals,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma proposta recebida',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aguarde que profissionais enviem propostas para o seu job',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ NOVO ProposalCard com Reputação
class ProposalCard extends StatefulWidget {
  final Map<String, dynamic> proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ProposalCard({
    super.key,
    required this.proposal,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<ProposalCard> {
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
      final metadata = widget.proposal['metadata'];
      final providerData = metadata?['data']?['provider'];
      final providerAddress = providerData?['address'];

      if (providerAddress == null) {
        setState(() => _isLoadingReputation = false);
        return;
      }

      final result = await _jobService.getUserReputation(providerAddress, false);

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
    final metadata = widget.proposal['metadata'];
    final providerData = metadata != null ? metadata['data']['provider'] : null;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  userId: providerData['user_id'],
                  userName: providerData['name'],
                  radius: 30,
                  backgroundColor: Colors.purple[700]!,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerData?['name'] ?? 'Profissional',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.work_outline,
                            size: 14,
                            color: Colors.purple[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Prestador',
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
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_reputation != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple[100]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ProviderStatItem(
                            label: 'Serviços',
                            value: '${_reputation!['totalJobs'] ?? 0}',
                            color: Colors.green[700]!,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: Column(
                            children: [
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
                        Container(
                          width: 1,
                          height: 50,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.purple[700],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getAccountAge(_reputation!['joinedAt']),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                'Membro',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const Divider(height: 32),

            if (metadata != null && metadata['data']['description'] != null) ...[
              const Text(
                'Descrição da Proposta:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                metadata['data']['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Valor e Prazo
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Valor',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'R\$ ${StringFormatter.formatAmount(widget.proposal['amount'])}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Prazo',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.proposal['estimated_time_days']} dias',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Enviada em: ${_formatDate(widget.proposal['created_at'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeitar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.onAccept,
                    icon: const Icon(Icons.check),
                    label: const Text('Aceitar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString.toString();
    }
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
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
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
    this.size = 16,
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