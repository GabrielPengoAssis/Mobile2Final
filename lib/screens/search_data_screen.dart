import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile2/services/firestore_service.dart';

class SearchDataScreen extends StatefulWidget {
  const SearchDataScreen({super.key});

  @override
  State<SearchDataScreen> createState() => _SearchDataScreenState();
}

class _SearchDataScreenState extends State<SearchDataScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  String _selectedCollection = 'products';
  String _selectedField = 'name';
  String _selectedOrderByField = 'name';
  bool _descendingOrder = false;
  String _errorMessage = '';

  final Map<String, List<String>> _collectionFields = {
    'products': ['name', 'description', 'category'],
    'services': ['title', 'description'],
    'orders': ['productName', 'status'],
  };

  final Map<String, String> _collectionLabels = {
    'products': 'Produtos',
    'services': 'Serviços',
    'orders': 'Pedidos',
  };

  final Map<String, String> _fieldLabels = {
    'name': 'Nome',
    'description': 'Descrição',
    'category': 'Categoria',
    'title': 'Título',
    'productName': 'Nome do Produto',
    'status': 'Status',
  };

  void _performSearch() async {
    final searchTerm = _searchController.text.trim();
    
    // Clear previous error
    setState(() {
      _errorMessage = '';
    });

    if (searchTerm.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    // Debounce: add a small delay to avoid too many requests
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if search term hasn't changed during delay
    if (_searchController.text.trim() != searchTerm) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      List<DocumentSnapshot> results = await _firestoreService.getFilteredData(
        _selectedCollection,
        _selectedField,
        searchTerm.toLowerCase(),
        orderByField: _selectedOrderByField,
        descending: _descendingOrder,
      );
      
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao pesquisar: ${e.toString()}';
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateAvailableFields() {
    final availableFields = _collectionFields[_selectedCollection]!;
    setState(() {
      _selectedField = availableFields.first;
      _selectedOrderByField = availableFields.first;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _errorMessage = '';
    });
  }

  Widget _buildResultItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    switch (_selectedCollection) {
      case 'products':
        return ListTile(
          leading: const Icon(Icons.shopping_bag, color: Colors.blue),
          title: Text(
            data['name'] ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['description'] != null && data['description'].toString().isNotEmpty)
                Text(
                  data['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 4),
              Text(
                'Preço: R\$ ${data['price']?.toStringAsFixed(2) ?? '0,00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          trailing: data['category'] != null 
              ? Chip(
                  label: Text(
                    data['category'],
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue[50],
                )
              : null,
        );
      
      case 'services':
        return ListTile(
          leading: const Icon(Icons.design_services, color: Colors.orange),
          title: Text(
            data['title'] ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['description'] != null && data['description'].toString().isNotEmpty)
                Text(
                  data['description'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              const SizedBox(height: 4),
              Text(
                'Custo: R\$ ${data['cost']?.toStringAsFixed(2) ?? '0,00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      
      case 'orders':
        final status = data['status'] ?? 'N/A';
        Color statusColor = Colors.grey;
        IconData statusIcon = Icons.help;
        
        switch (status.toLowerCase()) {
          case 'pending':
          case 'pendente':
            statusColor = Colors.orange;
            statusIcon = Icons.pending;
            break;
          case 'completed':
          case 'concluído':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            break;
          case 'cancelled':
          case 'cancelado':
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            break;
        }
        
        return ListTile(
          leading: Icon(Icons.shopping_cart, color: Colors.purple),
          title: Text(
            'Pedido: ${data['productName'] ?? 'N/A'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                'Status: $status',
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          trailing: Text(
            doc.id.substring(0, 8),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
        );
      
      default:
        return ListTile(
          title: Text('Documento ID: ${doc.id}'),
          subtitle: Text('Dados: ${data.toString()}'),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    // Remove automatic search on every keystroke for better performance
    // _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesquisar Dados'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Collection Selection
            DropdownButtonFormField<String>(
              value: _selectedCollection,
              decoration: const InputDecoration(
                labelText: 'Selecionar Coleção',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
              items: _collectionFields.keys.map((String collection) {
                return DropdownMenuItem<String>(
                  value: collection,
                  child: Text(_collectionLabels[collection] ?? collection.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCollection = value!;
                  _updateAvailableFields();
                  _clearSearch();
                });
              },
            ),
            
            const SizedBox(height: 12),
            
            // Field Selection
            DropdownButtonFormField<String>(
              value: _selectedField,
              decoration: const InputDecoration(
                labelText: 'Campo para Pesquisar',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              items: _collectionFields[_selectedCollection]!.map((String field) {
                return DropdownMenuItem<String>(
                  value: field,
                  child: Text(_fieldLabels[field] ?? field),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedField = value!;
                });
              },
            ),
            
            const SizedBox(height: 12),
            
            // Search Input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Termo de Pesquisa',
                hintText: 'Digite para pesquisar...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _performSearch,
                      tooltip: 'Pesquisar',
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: 'Limpar',
                      ),
                  ],
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
            
            const SizedBox(height: 12),
            
            // Sorting Options
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedOrderByField,
                    decoration: const InputDecoration(
                      labelText: 'Ordenar Por',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sort),
                    ),
                    items: _collectionFields[_selectedCollection]!.map((String field) {
                      return DropdownMenuItem<String>(
                        value: field,
                        child: Text(_fieldLabels[field] ?? field),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedOrderByField = value!;
                      });
                      if (_searchResults.isNotEmpty) {
                        _performSearch();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text('Ordem', style: TextStyle(fontSize: 12)),
                    Row(
                      children: [
                        Checkbox(
                          value: _descendingOrder,
                          onChanged: (bool? value) {
                            setState(() {
                              _descendingOrder = value ?? false;
                            });
                            if (_searchResults.isNotEmpty) {
                              _performSearch();
                            }
                          },
                        ),
                        const Text('Desc', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Error Message
            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Results
            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Pesquisando...'),
          ],
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Digite um termo para pesquisar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhum resultado encontrado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente usar termos diferentes',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            '${_searchResults.length} resultado(s) encontrado(s)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final doc = _searchResults[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 2,
                child: _buildResultItem(doc),
              );
            },
          ),
        ),
      ],
    );
  }
}