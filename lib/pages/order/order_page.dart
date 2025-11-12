import 'package:bico_certo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/services/proposal_service.dart';
import 'package:bico_certo/services/job_service.dart';
import 'package:bico_certo/models/job_model.dart';
import 'package:bico_certo/routes.dart';
import 'package:bico_certo/widgets/bottom_navbar.dart';

import '../../utils/string_formatter.dart';
import '../../widgets/status_badge.dart';
import '../job/job_details_page.dart';
import '../job/job_proposals_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProposalService _proposalService = ProposalService();
  final JobService _jobService = JobService();
  final AuthService _authService = AuthService();

  bool _isLoadingProposals = true;
  bool _isLoadingJobs = true;

  List<Map<String, dynamic>> _myProposals = [];
  List<Map<String, dynamic>> _filteredProposals = [];
  List<Job> _myJobs = [];
  List<Job> _filteredJobs = [];

  String? _errorProposals;
  String? _errorJobs;

  Set<String> _selectedStatuses = {'pending', 'accepted'};
  double? _minProposalAmount;
  double? _maxProposalAmount;
  String _proposalSortBy = 'recent';

  String? _selectedJobCategory;
  double? _minJobBudget;
  double? _maxJobBudget;
  int? _minProposalCount;
  int? _maxProposalCount;
  String _jobSortBy = 'recent';
  Set<JobStatus> _selectedJobStatuses = {JobStatus.open, JobStatus.inProgress};

  final List<String> _categoryList = [
    'Reformas',
    'Assistência Técnica',
    'Aulas Particulares',
    'Design',
    'Consultoria',
    'Elétrica',
    'Faxina',
    'Pintura'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyProposals(),
      _loadMyJobs(),
    ]);
  }

  Future<void> _loadMyProposals() async {
    setState(() {
      _isLoadingProposals = true;
      _errorProposals = null;
    });

    try {
      final result = await _proposalService.getMyProposals();

      if (result['success'] == true) {
        setState(() {
          _myProposals = List<Map<String, dynamic>>.from(result['proposals'] ?? []);
          _applyProposalFilters();
          _isLoadingProposals = false;
        });
      } else {
        setState(() {
          _errorProposals = result['message'] ?? 'Erro ao carregar propostas';
          _isLoadingProposals = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorProposals = 'Erro ao carregar propostas: $e';
        _isLoadingProposals = false;
      });
    }
  }

  Future<void> _loadMyJobs() async {
    setState(() {
      _isLoadingJobs = true;
      _errorJobs = null;
    });

    try {
      final jobs = await _jobService.getMyJobs();
      setState(() {
        _myJobs = jobs;
        _applyJobFilters();
        _isLoadingJobs = false;
      });
    } catch (e) {
      setState(() {
        _errorJobs = 'Erro ao carregar jobs: $e';
        _isLoadingJobs = false;
      });
    }
  }

  void _applyProposalFilters() {
    List<Map<String, dynamic>> filtered = List.from(_myProposals);

    filtered = filtered.where((proposal) {
      final status = (proposal['status'] ?? 'pending').toString().toLowerCase();
      return _selectedStatuses.contains(status);
    }).toList();

    if (_minProposalAmount != null) {
      filtered = filtered.where((proposal) {
        final amount = _parseAmount(proposal['amount']);
        return amount >= _minProposalAmount!;
      }).toList();
    }
    if (_maxProposalAmount != null) {
      filtered = filtered.where((proposal) {
        final amount = _parseAmount(proposal['amount']);
        return amount <= _maxProposalAmount!;
      }).toList();
    }

    switch (_proposalSortBy) {
      case 'recent':
        filtered.sort((a, b) {
          final dateA = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
          final dateB = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
          return dateB.compareTo(dateA);
        });
        break;
      case 'amount_asc':
        filtered.sort((a, b) {
          final amountA = _parseAmount(a['amount']);
          final amountB = _parseAmount(b['amount']);
          return amountA.compareTo(amountB);
        });
        break;
      case 'amount_desc':
        filtered.sort((a, b) {
          final amountA = _parseAmount(a['amount']);
          final amountB = _parseAmount(b['amount']);
          return amountB.compareTo(amountA);
        });
        break;
    }

    setState(() {
      _filteredProposals = filtered;
    });
  }

  void _applyJobFilters() {
    List<Job> filtered = List.from(_myJobs);

    if (_selectedJobStatuses.isNotEmpty) {
      filtered = filtered.where((job) => _selectedJobStatuses.contains(job.status)).toList();
    }

    if (_selectedJobCategory != null) {
      filtered = filtered.where((job) => job.category == _selectedJobCategory).toList();
    }

    if (_minJobBudget != null) {
      filtered = filtered.where((job) => job.maxBudget >= _minJobBudget!).toList();
    }

    if (_maxJobBudget != null) {
      filtered = filtered.where((job) => job.maxBudget <= _maxJobBudget!).toList();
    }

    if (_minProposalCount != null) {
      filtered = filtered.where((job) => job.proposalCount >= _minProposalCount!).toList();
    }
    if (_maxProposalCount != null) {
      filtered = filtered.where((job) => job.proposalCount <= _maxProposalCount!).toList();
    }

    switch (_jobSortBy) {
      case 'recent':
        filtered.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
        break;
      case 'budget_asc':
        filtered.sort((a, b) => a.maxBudget.compareTo(b.maxBudget));
        break;
      case 'budget_desc':
        filtered.sort((a, b) => b.maxBudget.compareTo(a.maxBudget));
        break;
      case 'proposals_asc':
        filtered.sort((a, b) => a.proposalCount.compareTo(b.proposalCount));
        break;
      case 'proposals_desc':
        filtered.sort((a, b) => b.proposalCount.compareTo(b.proposalCount));
        break;
    }

    setState(() {
      _filteredJobs = filtered;
    });
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  void _showProposalFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProposalFilterBottomSheet(
        selectedStatuses: _selectedStatuses,
        minAmount: _minProposalAmount,
        maxAmount: _maxProposalAmount,
        sortBy: _proposalSortBy,
        onApply: (statuses, minAmount, maxAmount, sortBy) {
          setState(() {
            _selectedStatuses = statuses;
            _minProposalAmount = minAmount;
            _maxProposalAmount = maxAmount;
            _proposalSortBy = sortBy;
          });
          _applyProposalFilters();
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _selectedStatuses = {'pending', 'accepted', 'rejected'};
            _minProposalAmount = null;
            _maxProposalAmount = null;
            _proposalSortBy = 'recent';
          });
          _applyProposalFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showJobFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _JobFilterBottomSheet(
        selectedStatuses: _selectedJobStatuses,
        selectedCategory: _selectedJobCategory,
        minBudget: _minJobBudget,
        maxBudget: _maxJobBudget,
        minProposalCount: _minProposalCount,
        maxProposalCount: _maxProposalCount,
        sortBy: _jobSortBy,
        categories: _categoryList,
        onApply: (statuses, category, minBudget, maxBudget, minProposals, maxProposals, sortBy) {
          setState(() {
            _selectedJobStatuses = statuses;
            _selectedJobCategory = category;
            _minJobBudget = minBudget;
            _maxJobBudget = maxBudget;
            _minProposalCount = minProposals;
            _maxProposalCount = maxProposals;
            _jobSortBy = sortBy;
          });
          _applyJobFilters();
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _selectedJobStatuses = {JobStatus.open};
            _selectedJobCategory = null;
            _minJobBudget = null;
            _maxJobBudget = null;
            _minProposalCount = null;
            _maxProposalCount = null;
            _jobSortBy = 'recent';
          });
          _applyJobFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  int _getActiveProposalFilterCount() {
    int count = 0;
    if (_selectedStatuses.length < 4) count++;
    if (_minProposalAmount != null) count++;
    if (_maxProposalAmount != null) count++;
    if (_proposalSortBy != 'recent') count++;
    return count;
  }

  int _getActiveJobFilterCount() {
    int count = 0;
    if (_selectedJobStatuses.length != 1 || !_selectedJobStatuses.contains(JobStatus.open)) count++;
    if (_selectedJobCategory != null) count++;
    if (_minJobBudget != null) count++;
    if (_maxJobBudget != null) count++;
    if (_minProposalCount != null) count++;
    if (_maxProposalCount != null) count++;
    if (_jobSortBy != 'recent') count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meus Trabalhos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 76, 110),
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  if (_tabController.index == 0) {
                    _showProposalFilterBottomSheet();
                  } else {
                    _showJobFilterBottomSheet();
                  }
                },
              ),
              if ((_tabController.index == 0 && _getActiveProposalFilterCount() > 0) ||
                  (_tabController.index == 1 && _getActiveJobFilterCount() > 0))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_tabController.index == 0 ? _getActiveProposalFilterCount() : _getActiveJobFilterCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(
              icon: Icon(Icons.send),
              text: 'Minhas Propostas',
            ),
            Tab(
              icon: Icon(Icons.work),
              text: 'Meus Jobs',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProposalsTab(),
          _buildJobsTab(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.sessionCheck,
                  (route) => route.isFirst,
            );
          } else if (index == 2) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.chatRoomsPage,
                  (route) => route.isFirst,
            );
          } else if (index == 3) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.profilePage,
                  (route) => route.isFirst,
            );
          }
        },
      ),
    );
  }

  Widget _buildProposalsTab() {
    if (_isLoadingProposals) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorProposals != null) {
      return _buildErrorWidget(_errorProposals!, _loadMyProposals);
    }

    return Column(
      children: [
        if (_getActiveProposalFilterCount() > 0) _buildProposalFilterChips(),
        Expanded(
          child: _filteredProposals.isEmpty
              ? _buildEmptyProposalsWidget()
              : RefreshIndicator(
            onRefresh: _loadMyProposals,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredProposals.length,
              itemBuilder: (context, index) {
                return ProposalCard(
                  proposal: _filteredProposals[index],
                  onUpdate: _loadMyProposals,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailsPage(job: Job.fromJson(_filteredProposals[index]['job'])),
                      ),
                    );

                    if (result == true) {
                      _loadMyProposals();
                    }
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobsTab() {
    if (_isLoadingJobs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorJobs != null) {
      return _buildErrorWidget(_errorJobs!, _loadMyJobs);
    }

    return Column(
      children: [
        if (_getActiveJobFilterCount() > 0) _buildJobFilterChips(),
        Expanded(
          child: _filteredJobs.isEmpty
              ? _buildEmptyJobsWidget()
              : RefreshIndicator(
            onRefresh: _loadMyJobs,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredJobs.length,
              itemBuilder: (context, index) {
                return JobCard(job: _filteredJobs[index], onUpdate: _loadMyJobs);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProposalFilterChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedStatuses.length < 4)
            Chip(
              avatar: const Icon(Icons.check_circle, size: 18),
              label: Text('${_selectedStatuses.length} status'),
              backgroundColor: Colors.blue[50],
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedStatuses = {'pending', 'accepted', 'rejected'};
                });
                _applyProposalFilters();
              },
            ),
          if (_minProposalAmount != null || _maxProposalAmount != null)
            Chip(
              avatar: const Icon(Icons.attach_money, size: 18),
              label: Text(
                'R\$ ${_minProposalAmount?.toStringAsFixed(0) ?? '0'} - ${_maxProposalAmount?.toStringAsFixed(0) ?? '∞'}',
              ),
              backgroundColor: Colors.green[50],
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _minProposalAmount = null;
                  _maxProposalAmount = null;
                });
                _applyProposalFilters();
              },
            ),
          if (_proposalSortBy != 'recent')
            Chip(
              avatar: const Icon(Icons.sort, size: 18),
              label: Text(_getProposalSortLabel(_proposalSortBy)),
              backgroundColor: Colors.orange[50],
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _proposalSortBy = 'recent';
                });
                _applyProposalFilters();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildJobFilterChips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_selectedJobStatuses.length != 1 || !_selectedJobStatuses.contains(JobStatus.open))
            Chip(
              avatar: const Icon(Icons.filter_alt, size: 18),
              label: Text('${_selectedJobStatuses.length} status'),
              backgroundColor: Colors.purple.shade50,
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedJobStatuses = {JobStatus.open, JobStatus.inProgress};
                });
                _applyJobFilters();
              },
            ),
          if (_selectedJobCategory != null)
            Chip(
              avatar: const Icon(Icons.category, size: 18),
              label: Text(_selectedJobCategory!),
              backgroundColor: Colors.blue.shade50,
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _selectedJobCategory = null;
                });
                _applyJobFilters();
              },
            ),
          if (_minJobBudget != null || _maxJobBudget != null)
            Chip(
              avatar: const Icon(Icons.attach_money, size: 18),
              label: Text(
                'R\$ ${_minJobBudget?.toStringAsFixed(0) ?? '0'} - ${_maxJobBudget?.toStringAsFixed(0) ?? '∞'}',
              ),
              backgroundColor: Colors.green.shade50,
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _minJobBudget = null;
                  _maxJobBudget = null;
                });
                _applyJobFilters();
              },
            ),
          if (_minProposalCount != null || _maxProposalCount != null)
            Chip(
              avatar: const Icon(Icons.people, size: 18),
              label: Text(
                '${_minProposalCount ?? '0'} - ${_maxProposalCount ?? '∞'} propostas',
              ),
              backgroundColor: Colors.purple.shade50,
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _minProposalCount = null;
                  _maxProposalCount = null;
                });
                _applyJobFilters();
              },
            ),
          if (_jobSortBy != 'recent')
            Chip(
              avatar: const Icon(Icons.sort, size: 18),
              label: Text(_getJobSortLabel(_jobSortBy)),
              backgroundColor: Colors.orange.shade50,
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () {
                setState(() {
                  _jobSortBy = 'recent';
                });
                _applyJobFilters();
              },
            ),
        ],
      ),
    );
  }

  String _getProposalSortLabel(String sortBy) {
    switch (sortBy) {
      case 'amount_asc':
        return 'Menor valor';
      case 'amount_desc':
        return 'Maior valor';
      default:
        return 'Mais recentes';
    }
  }

  String _getJobSortLabel(String sortBy) {
    switch (sortBy) {
      case 'budget_asc':
        return 'Menor orçamento';
      case 'budget_desc':
        return 'Maior orçamento';
      case 'proposals_asc':
        return 'Menos propostas';
      case 'proposals_desc':
        return 'Mais propostas';
      default:
        return 'Mais recentes';
    }
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar dados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProposalsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getActiveProposalFilterCount() > 0
                  ? 'Nenhuma proposta encontrada'
                  : 'Nenhuma proposta enviada',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getActiveProposalFilterCount() > 0
                  ? 'Tente ajustar os filtros'
                  : 'Quando você enviar propostas para jobs, elas aparecerão aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            if (_getActiveProposalFilterCount() > 0)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedStatuses = {'pending', 'accepted', 'rejected'};
                    _minProposalAmount = null;
                    _maxProposalAmount = null;
                    _proposalSortBy = 'recent';
                  });
                  _applyProposalFilters();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar filtros'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.sessionCheck,
                        (route) => route.isFirst,
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('Buscar Jobs'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 74, 58, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyJobsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _getActiveJobFilterCount() > 0
                  ? 'Nenhum job encontrado'
                  : 'Nenhum job criado',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getActiveJobFilterCount() > 0
                  ? 'Tente ajustar os filtros'
                  : 'Quando você criar jobs, eles aparecerão aqui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            if (_getActiveJobFilterCount() > 0)
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedJobCategory = null;
                    _minJobBudget = null;
                    _maxJobBudget = null;
                    _minProposalCount = null;
                    _maxProposalCount = null;
                    _jobSortBy = 'recent';
                  });
                  _applyJobFilters();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Limpar filtros'),
              )
            else
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.orderInfoPage);
                },
                icon: const Icon(Icons.add),
                label: const Text('Criar Novo Job'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 74, 58, 255),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProposalFilterBottomSheet extends StatefulWidget {
  final Set<String> selectedStatuses;
  final double? minAmount;
  final double? maxAmount;
  final String sortBy;
  final Function(Set<String>, double?, double?, String) onApply;
  final VoidCallback onClear;

  const _ProposalFilterBottomSheet({
    required this.selectedStatuses,
    required this.minAmount,
    required this.maxAmount,
    required this.sortBy,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_ProposalFilterBottomSheet> createState() => _ProposalFilterBottomSheetState();
}

class _ProposalFilterBottomSheetState extends State<_ProposalFilterBottomSheet> {
  late Set<String> _selectedStatuses;
  late double? _minAmount;
  late double? _maxAmount;
  late String _sortBy;

  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  final Map<String, String> _statusLabels = {
    'pending': 'Pendente',
    'accepted': 'Aceita',
    'rejected': 'Rejeitada',
    'canceled': 'Cancelada',
  };

  @override
  void initState() {
    super.initState();
    _selectedStatuses = Set.from(widget.selectedStatuses);
    _minAmount = widget.minAmount;
    _maxAmount = widget.maxAmount;
    _sortBy = widget.sortBy;

    if (_minAmount != null) {
      _minAmountController.text = _minAmount!.toStringAsFixed(0);
    }
    if (_maxAmount != null) {
      _maxAmountController.text = _maxAmount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros - Propostas',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._statusLabels.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(entry.value),
                        value: _selectedStatuses.contains(entry.key),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedStatuses.add(entry.key);
                            } else {
                              _selectedStatuses.remove(entry.key);
                            }
                          });
                        },
                        activeColor: const Color.fromARGB(255, 74, 58, 255),
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'Faixa de Valor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Mínimo',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) {
                              _minAmount = double.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Máximo',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) {
                              _maxAmount = double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ordenar por',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSortOption('recent', 'Mais recentes', Icons.schedule),
                    _buildSortOption('amount_asc', 'Menor valor', Icons.arrow_upward),
                    _buildSortOption('amount_desc', 'Maior valor', Icons.arrow_downward),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClear,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          _selectedStatuses,
                          _minAmount,
                          _maxAmount,
                          _sortBy,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 74, 58, 255),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aplicar Filtros',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Colors.blue[50] : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color.fromARGB(255, 74, 58, 255) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color.fromARGB(255, 74, 58, 255) : Colors.grey[600],
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color.fromARGB(255, 74, 58, 255) : null,
          ),
        ),
        trailing: isSelected
            ? const Icon(
          Icons.check_circle,
          color: Color.fromARGB(255, 74, 58, 255),
        )
            : null,
        onTap: () {
          setState(() {
            _sortBy = value;
          });
        },
      ),
    );
  }
}

class _JobFilterBottomSheet extends StatefulWidget {
  final Set<JobStatus> selectedStatuses;
  final String? selectedCategory;
  final double? minBudget;
  final double? maxBudget;
  final int? minProposalCount;
  final int? maxProposalCount;
  final String sortBy;
  final List<String> categories;
  final Function(Set<JobStatus>, String?, double?, double?, int?, int?, String) onApply;
  final VoidCallback onClear;

  const _JobFilterBottomSheet({
    required this.selectedStatuses,
    required this.selectedCategory,
    required this.minBudget,
    required this.maxBudget,
    required this.minProposalCount,
    required this.maxProposalCount,
    required this.sortBy,
    required this.categories,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_JobFilterBottomSheet> createState() => _JobFilterBottomSheetState();
}

class _JobFilterBottomSheetState extends State<_JobFilterBottomSheet> {
  late Set<JobStatus> _selectedStatuses;
  late String? _selectedCategory;
  late double? _minBudget;
  late double? _maxBudget;
  late int? _minProposalCount;
  late int? _maxProposalCount;
  late String _sortBy;

  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();
  final TextEditingController _minProposalController = TextEditingController();
  final TextEditingController _maxProposalController = TextEditingController();

  final List<JobStatus> _allowedStatuses = [
    JobStatus.open,
    JobStatus.inProgress,
    JobStatus.completed,
    JobStatus.approved,
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatuses = Set.from(widget.selectedStatuses);
    _selectedCategory = widget.selectedCategory;
    _minBudget = widget.minBudget;
    _maxBudget = widget.maxBudget;
    _minProposalCount = widget.minProposalCount;
    _maxProposalCount = widget.maxProposalCount;
    _sortBy = widget.sortBy;

    if (_minBudget != null) {
      _minBudgetController.text = _minBudget!.toStringAsFixed(0);
    }
    if (_maxBudget != null) {
      _maxBudgetController.text = _maxBudget!.toStringAsFixed(0);
    }
    if (_minProposalCount != null) {
      _minProposalController.text = _minProposalCount.toString();
    }
    if (_maxProposalCount != null) {
      _maxProposalController.text = _maxProposalCount.toString();
    }
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    _minProposalController.dispose();
    _maxProposalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtros - Jobs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._allowedStatuses.map((status) {
                      return CheckboxListTile(
                        title: Text(status.displayName),
                        subtitle: Text(
                          _getStatusDescription(status),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        value: _selectedStatuses.contains(status),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedStatuses.add(status);
                            } else {
                              _selectedStatuses.remove(status);
                            }
                          });
                        },
                        activeColor: status.color,
                      );
                    }),
                    const SizedBox(height: 24),
                    const Text(
                      'Categoria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        hintText: 'Todas as categorias',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas as categorias'),
                        ),
                        ...widget.categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Faixa de Orçamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minBudgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Mínimo',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) {
                              _minBudget = double.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxBudgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Máximo',
                              prefixText: 'R\$ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) {
                              _maxBudget = double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Número de Propostas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minProposalController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Mínimo',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) {
                              _minProposalCount = int.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxProposalController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Máximo',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            onChanged: (value) {
                              _maxProposalCount = int.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Ordenar por',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSortOption('recent', 'Mais recentes', Icons.schedule),
                    _buildSortOption('budget_asc', 'Menor orçamento', Icons.arrow_upward),
                    _buildSortOption('budget_desc', 'Maior orçamento', Icons.arrow_downward),
                    _buildSortOption('proposals_asc', 'Menos propostas', Icons.trending_down),
                    _buildSortOption('proposals_desc', 'Mais propostas', Icons.trending_up),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClear,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(
                          _selectedStatuses,
                          _selectedCategory,
                          _minBudget,
                          _maxBudget,
                          _minProposalCount,
                          _maxProposalCount,
                          _sortBy,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 74, 58, 255),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Aplicar Filtros',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _getStatusDescription(JobStatus status) {
    switch (status) {
      case JobStatus.open:
        return 'Aguardando propostas';
      case JobStatus.inProgress:
        return 'Trabalho em andamento';
      case JobStatus.completed:
        return 'Aguardando aprovação';
      case JobStatus.approved:
        return 'Finalizado e aprovado';
      default:
        return '';
    }
  }


  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Colors.blue[50] : Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color.fromARGB(255, 74, 58, 255) : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color.fromARGB(255, 74, 58, 255) : Colors.grey[600],
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color.fromARGB(255, 74, 58, 255) : null,
          ),
        ),
        trailing: isSelected
            ? const Icon(
          Icons.check_circle,
          color: Color.fromARGB(255, 74, 58, 255),
        )
            : null,
        onTap: () {
          setState(() {
            _sortBy = value;
          });
        },
      ),
    );
  }
}

class ProposalCard extends StatelessWidget {
  final Map<String, dynamic> proposal;
  final VoidCallback? onTap;
  final VoidCallback? onUpdate;

  const ProposalCard({
    super.key,
    required this.proposal,
    this.onTap,
    this.onUpdate,
  });

  Map<String, dynamic>? _getApprovalDeadlineInfo() {
    try {
      final job = proposal['job'];
      if (job == null) return null;

      final jobStatus = job['status']?.toString().toLowerCase();
      if (jobStatus != 'completed') return null;

      final completedAtStr = job['completed_at']?.toString();
      if (completedAtStr == null || completedAtStr.isEmpty) return null;

      final completedAt = DateTime.parse(completedAtStr);
      final approvalDeadline = completedAt.add(const Duration(days: 3));
      final now = DateTime.now();
      final timeRemaining = approvalDeadline.difference(now);

      return {
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

  Color _getJobStatusColor(String status) {
    final jobStatus = JobStatus.fromString(status);
    return jobStatus.color;
  }

  String _getJobStatusText(String status) {
    final jobStatus = JobStatus.fromString(status);
    return jobStatus.displayName;
  }

  bool _isActiveProposal(String status) {
    final statusLower = status.toLowerCase();
    return statusLower == 'pending' || statusLower == 'accepted';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final status = proposal['status'] ?? 'pending';
    final job = proposal['job'];
    final isActive = _isActiveProposal(status);
    final jobStatus = job?['status']?.toString() ?? 'none';
    final approvalInfo = isActive ? _getApprovalDeadlineInfo() : null;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (job != null) ...[
                          Text(
                            job['metadata']?['data']?['title']?.toString() ?? 'N/A',
                            style: TextStyle(
                              fontSize: screenWidth * 0.042,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            job['service_type'] ?? '',
                            style: TextStyle(
                              fontSize: screenWidth * 0.028,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ProposalStatusBadge(
                    status: status,
                    fontSize: screenWidth * 0.03,
                  ),
                ],
              ),
              if (isActive && jobStatus != 'none') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getJobStatusColor(jobStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getJobStatusColor(jobStatus).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.work_outline,
                        size: 14,
                        color: _getJobStatusColor(jobStatus),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Job: ${_getJobStatusText(jobStatus)}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.w600,
                          color: _getJobStatusColor(jobStatus),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (approvalInfo != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: approvalInfo['isExpired']
                          ? [Colors.red[50]!, Colors.red[100]!]
                          : [Colors.amber[50]!, Colors.orange[50]!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: approvalInfo['isExpired'] ? Colors.red[300]! : Colors.orange[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            approvalInfo['isExpired'] ? Icons.warning : Icons.timer,
                            size: 16,
                            color: approvalInfo['isExpired'] ? Colors.red[700] : Colors.orange[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              approvalInfo['isExpired']
                                  ? 'Prazo de aprovação expirado!'
                                  : 'Aguardando aprovação do cliente',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeight.bold,
                                color: approvalInfo['isExpired'] ? Colors.red[900] : Colors.orange[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: approvalInfo['isExpired'] ? Colors.red[600] : Colors.orange[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            approvalInfo['isExpired']
                                ? 'Expirou há ${approvalInfo['hoursRemaining']} horas'
                                : _formatTimeRemaining(approvalInfo['timeRemaining']),
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              color: approvalInfo['isExpired'] ? Colors.red[700] : Colors.orange[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'R\$ ${StringFormatter.formatAmount(proposal['amount'])}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.schedule,
                    size: screenWidth * 0.04,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${proposal['estimated_time_days']} dias',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: screenWidth * 0.035,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Enviada em: ${_formatDate(proposal['created_at'])}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onUpdate;

  const JobCard({super.key, required this.job, this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final isOpen = job.status == JobStatus.open;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsPage(job: job),
            ),
          );

          if (result == true && onUpdate != null) {
            onUpdate!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.metadata.data.title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.042,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          job.category,
                          style: TextStyle(
                            fontSize: screenWidth * 0.028,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  JobStatusBadge(
                    status: job.status,
                    fontSize: screenWidth * 0.03,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 1,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 12),
              Text(
                job.metadata.data.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: screenWidth * 0.037,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              if (isOpen) ...[
                Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: screenWidth * 0.04,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${job.proposalCount} ${job.proposalCount == 1 ? 'proposta' : 'propostas'}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        !isOpen ? 'Custo' : 'Orçamento máximo',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'R\$ ${StringFormatter.formatAmount(job.maxBudget)}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.042,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isOpen) ...[
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobProposalsPage(job: job),
                          ),
                        );

                        if (result == true && onUpdate != null) {
                          onUpdate!();
                        }
                      },
                      icon: const Icon(Icons.list_alt, size: 16),
                      label: const Text('Ver propostas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 74, 58, 255),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}