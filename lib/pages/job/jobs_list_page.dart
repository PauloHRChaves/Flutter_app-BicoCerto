import 'package:bico_certo/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:bico_certo/models/job_model.dart';
import 'package:bico_certo/services/job_service.dart';
import 'package:bico_certo/pages/job/job_details_page.dart';

class JobsListPage extends StatefulWidget {
  final String? category;
  final String? searchTerm;

  const JobsListPage({
    super.key,
    this.category,
    this.searchTerm,
  });

  @override
  State<JobsListPage> createState() => _JobsListPageState();
}

class _JobsListPageState extends State<JobsListPage> {
  final JobService _jobService = JobService();
  final TextEditingController _searchController = TextEditingController();

  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  bool _isLoading = true;
  String? _error;
  String? _userWalletAddress;
  final AuthService _authService = AuthService();

  String? _currentSearchTerm;
  String? _selectedCategory;
  double? _minBudget;
  double? _maxBudget;
  String _sortBy = 'recent';

  final List<String> _categoryList = ['Reformas',
    'Assistência Técnica',
    'Aulas Particulares',
    'Design',
    'Consultoria',
    'Elétrica',
    'Faxina',
    'Pintura'];

  @override
  void initState() {
    super.initState();
    _currentSearchTerm = widget.searchTerm;
    _selectedCategory = widget.category;
    _searchController.text = widget.searchTerm ?? '';
    _loadUserWallet();
    _loadJobs();
  }

  Future<void> _loadUserWallet() async {
    try {
      setState(() async {
        _userWalletAddress = await _authService.getAddress();
      });
    } catch (e) {
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiCategory = _selectedCategory;

      final jobs = await _jobService.getOpenJobs(
        category: apiCategory,
        searchTerm: _currentSearchTerm,
      );
      setState(() {
        _jobs = jobs;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Job> filtered = List.from(_jobs);

    if (_userWalletAddress != null) {
      filtered = filtered.where((job) {
        final jobClientAddress = job.client.toLowerCase();
        final userAddress = _userWalletAddress!.toLowerCase();
        return jobClientAddress != userAddress;
      }).toList();
    }

    if (_minBudget != null) {
      filtered = filtered.where((job) => job.maxBudget >= _minBudget!).toList();
    }
    if (_maxBudget != null) {
      filtered = filtered.where((job) => job.maxBudget <= _maxBudget!).toList();
    }

    switch (_sortBy) {
      case 'recent':
        filtered.sort((a, b) => b.deadline.compareTo(a.deadline));
        break;
      case 'budget_asc':
        filtered.sort((a, b) => a.maxBudget.compareTo(b.maxBudget));
        break;
      case 'budget_desc':
        filtered.sort((a, b) => b.maxBudget.compareTo(a.maxBudget));
        break;
      case 'proposals':
        filtered.sort((a, b) => a.proposalCount.compareTo(b.proposalCount));
        break;
    }

    setState(() {
      _filteredJobs = filtered;
    });
  }

  void _performSearch() {
    final searchTerm = _searchController.text.trim();
    setState(() {
      _currentSearchTerm = searchTerm.isEmpty ? null : searchTerm;
    });
    _loadJobs();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentSearchTerm = null;
    });
    _loadJobs();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterBottomSheet(
        selectedCategory: _selectedCategory,
        minBudget: _minBudget,
        maxBudget: _maxBudget,
        sortBy: _sortBy,
        categories: _categoryList,
        onApply: (category, minBudget, maxBudget, sortBy) {
          setState(() {
            _selectedCategory = category;
            _minBudget = minBudget;
            _maxBudget = maxBudget;
            _sortBy = sortBy;
          });
          _loadJobs();
          Navigator.pop(context);
        },
        onClear: () {
          setState(() {
            _selectedCategory = null;
            _minBudget = null;
            _maxBudget = null;
            _sortBy = 'recent';
          });
          _loadJobs();
          Navigator.pop(context);
        },
      ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedCategory != null) count++;
    if (_minBudget != null) count++;
    if (_maxBudget != null) count++;
    if (_sortBy != 'recent') count++;
    return count;
  }

  String _getTitle() {
    if (_currentSearchTerm != null && _currentSearchTerm!.isNotEmpty) {
      return 'Resultados para "$_currentSearchTerm"';
    }
    if (_selectedCategory != null) {
      return 'Jobs de $_selectedCategory';
    }
    return 'Todos os Jobs';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 76, 110),
        foregroundColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterBottomSheet,
              ),
              if (_getActiveFilterCount() > 0)
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
                      '${_getActiveFilterCount()}',
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
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar serviço...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _currentSearchTerm != null &&
                          _currentSearchTerm!.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 22, 76, 110),
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _performSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 74, 58, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          if (_getActiveFilterCount() > 0)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 8,
              ),
              color: Colors.grey[100],
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_selectedCategory != null)
                    Chip(
                      avatar: const Icon(Icons.category, size: 18),
                      label: Text(_selectedCategory!),
                      backgroundColor: Colors.blue[50],
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _selectedCategory = null;
                        });
                        _loadJobs();
                      },
                    ),
                  if (_minBudget != null || _maxBudget != null)
                    Chip(
                      avatar: const Icon(Icons.attach_money, size: 18),
                      label: Text(
                        'R\$ ${_minBudget?.toStringAsFixed(0) ?? '0'} - ${_maxBudget?.toStringAsFixed(0) ?? '∞'}',
                      ),
                      backgroundColor: Colors.green[50],
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _minBudget = null;
                          _maxBudget = null;
                        });
                        _applyFilters();
                      },
                    ),
                  if (_sortBy != 'recent')
                    Chip(
                      avatar: const Icon(Icons.sort, size: 18),
                      label: Text(_getSortLabel(_sortBy)),
                      backgroundColor: Colors.orange[50],
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _sortBy = 'recent';
                        });
                        _applyFilters();
                      },
                    ),
                ],
              ),
            ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildErrorWidget(screenWidth)
                : _filteredJobs.isEmpty
                ? _buildEmptyWidget(screenWidth)
                : RefreshIndicator(
              onRefresh: _loadJobs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredJobs.length,
                itemBuilder: (context, index) {
                  return JobCard(job: _filteredJobs[index]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'budget_asc':
        return 'Menor valor';
      case 'budget_desc':
        return 'Maior valor';
      case 'proposals':
        return 'Menos propostas';
      default:
        return 'Mais recentes';
    }
  }

  Widget _buildErrorWidget(double screenWidth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar jobs',
              style: TextStyle(fontSize: screenWidth * 0.05),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadJobs,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(double screenWidth) {
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
              'Nenhum resultado encontrado',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente ajustar os filtros ou buscar por outro termo',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCategory = null;
                  _minBudget = null;
                  _maxBudget = null;
                  _sortBy = 'recent';
                  _currentSearchTerm = null;
                  _searchController.clear();
                });
                _loadJobs();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Limpar todos os filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final double? minBudget;
  final double? maxBudget;
  final String sortBy;
  final List<String> categories;
  final Function(String?, double?, double?, String) onApply;
  final VoidCallback onClear;

  const _FilterBottomSheet({
    required this.selectedCategory,
    required this.minBudget,
    required this.maxBudget,
    required this.sortBy,
    required this.categories,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _selectedCategory;
  late double? _minBudget;
  late double? _maxBudget;
  late String _sortBy;

  final TextEditingController _minBudgetController = TextEditingController();
  final TextEditingController _maxBudgetController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.selectedCategory != null &&
        !widget.categories.contains(widget.selectedCategory)) {
      _selectedCategory = null;
    } else {
      _selectedCategory = widget.selectedCategory;
    }

    _minBudget = widget.minBudget;
    _maxBudget = widget.maxBudget;
    _sortBy = widget.sortBy;

    if (_minBudget != null) {
      _minBudgetController.text = _minBudget!.toStringAsFixed(0);
    }
    if (_maxBudget != null) {
      _maxBudgetController.text = _maxBudget!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
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
                    'Filtros',
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
                      'Categoria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
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
                      'Ordenar por',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSortOption('recent', 'Mais recentes', Icons.schedule),
                    _buildSortOption(
                        'budget_asc', 'Menor valor', Icons.arrow_upward),
                    _buildSortOption(
                        'budget_desc', 'Maior valor', Icons.arrow_downward),
                    _buildSortOption(
                        'proposals', 'Menos propostas', Icons.people_outline),
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
                          _selectedCategory,
                          _minBudget,
                          _maxBudget,
                          _sortBy,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color.fromARGB(255, 74, 58, 255),
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
          color: isSelected
              ? const Color.fromARGB(255, 74, 58, 255)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? const Color.fromARGB(255, 74, 58, 255)
              : Colors.grey[600],
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

class JobCard extends StatelessWidget {
  final Job job;

  const JobCard({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JobDetailsPage(job: job),
            ),
          );
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
                    child: Text(
                      job.metadata.data.title,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.category,
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                job.metadata.data.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: screenWidth * 0.037,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: screenWidth * 0.04,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.metadata.data.location,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people_outline,
                    size: screenWidth * 0.04,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${job.proposalCount} propostas',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orçamento máximo',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'R\$ ${job.maxBudget.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 74, 58, 255),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Ver detalhes',
                      style: TextStyle(color: Colors.white),
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
}