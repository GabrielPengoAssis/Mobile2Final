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
  String _selectedCollection = 'products'; // Coleção padrão para pesquisa
  String _selectedField = 'name'; // Campo padrão para pesquisa (pode ser "name" para products, "title" para services)
  String _selectedOrderByField = 'name'; // Campo padrão para ordenação
  bool _descendingOrder = false;

  final Map<String, List<String>> _collectionFields = {
    'products': ['name', 'description', 'category'],
    'services': ['title', 'description'],
    'orders': ['productName', 'status'],
  };

  void _performSearch() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Normaliza o campo para pesquisa (minúsculas)
      List<DocumentSnapshot> results = await _firestoreService.getFilteredData(
        _selectedCollection,
        _selectedField,
        _searchController.text.toLowerCase(),
        orderByField: _selectedOrderByField,
        descending: _descendingOrder,
      );
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao pesquisar: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateAvailableFields() {
    setState(() {
      _selectedField = _collectionFields[_selectedCollection]![0]; // Seleciona o primeiro campo disponível
      _selectedOrderByField = _collectionFields[_selectedCollection]![0]; // Seleciona o primeiro campo disponível para ordenação
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_performSearch); // Pesquisa em tempo real
  }

  @override
  void dispose() {
    _searchController.removeListener(_performSearch);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesquisar Dados'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCollection,
              decoration: const InputDecoration(
                labelText: 'Selecionar Coleção',
                border: OutlineInputBorder(),
              ),
              items: _collectionFields.keys.map((String collection) {
                return DropdownMenuItem<String>(
                  value: collection,
                  child: Text(collection.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCollection = value!;
                  _updateAvailableFields();
                  _performSearch(); // Repetir pesquisa com nova coleção
                });
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedField,
              decoration: const InputDecoration(
                labelText: 'Campo para Pesquisar',
                border: OutlineInputBorder(),
              ),
              items: _collectionFields[_selectedCollection]!.map((String field) {
                return DropdownMenuItem<String>(
                  value: field,
                  child: Text(field),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedField = value!;
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Termo de Pesquisa',
                border: const OutlineInputBorder(),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      ),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedOrderByField,
              decoration: const InputDecoration(
                labelText: 'Ordenar Por',
                border: OutlineInputBorder(),
              ),
              items: _collectionFields[_selectedCollection]!.map((String field) {
                return DropdownMenuItem<String>(
                  value: field,
                  child: Text(field),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedOrderByField = value!;
                  _performSearch();
                });
              },
            ),
            Row(
              children: [
                Checkbox(
                  value: _descendingOrder,
                  onChanged: (bool? value) {
                    setState(() {
                      _descendingOrder = value ?? false;
                      _performSearch();
                    });
                  },
                ),
                const Text('Ordem Decrescente'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _searchResults.isEmpty && !_isLoading
                  ? const Center(child: Text('Nenhum resultado encontrado ou termo de pesquisa vazio.'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot doc = _searchResults[index];
                        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                        // Adapte a exibição do resultado com base na coleção
                        Widget resultItem;
                        if (_selectedCollection == 'products') {
                          resultItem = ListTile(
                            title: Text(data['name'] ?? 'N/A'),
                            subtitle: Text('Preço: R\$${data['price']?.toStringAsFixed(2) ?? '0.00'}'),
                          );
                        } else if (_selectedCollection == 'services') {
                          resultItem = ListTile(
                            title: Text(data['title'] ?? 'N/A'),
                            subtitle: Text('Custo: R\$${data['cost']?.toStringAsFixed(2) ?? '0.00'}'),
                          );
                        } else { // orders
                          resultItem = ListTile(
                            title: Text('Pedido: ${data['productName'] ?? 'N/A'}'),
                            subtitle: Text('Status: ${data['status'] ?? 'N/A'}'),
                          );
                        }
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: resultItem,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}