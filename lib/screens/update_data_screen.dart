import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile2/services/firestore_service.dart';

class UpdateDataScreen extends StatefulWidget {
  const UpdateDataScreen({super.key});

  @override
  State<UpdateDataScreen> createState() => _UpdateDataScreenState();
}

class _UpdateDataScreenState extends State<UpdateDataScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedCollectionIndex = 0; // 0: Products, 1: Services
  DocumentSnapshot? _selectedDocument;

  // Controllers para Products
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescriptionController = TextEditingController();
  final TextEditingController _productPriceController = TextEditingController();
  final TextEditingController _productCategoryController = TextEditingController();

  // Controllers para Services
  final TextEditingController _serviceTitleController = TextEditingController();
  final TextEditingController _serviceDescriptionController = TextEditingController();
  final TextEditingController _serviceDurationController = TextEditingController();
  final TextEditingController _serviceCostController = TextEditingController();
  bool _serviceAvailable = false;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _getCollectionName() {
    switch (_selectedCollectionIndex) {
      case 0:
        return 'products';
      case 1:
        return 'services';
      default:
        return 'products'; // Default
    }
  }

  void _loadDocumentData(DocumentSnapshot doc) {
    _selectedDocument = doc;
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    if (_selectedCollectionIndex == 0) { // Products
      _productNameController.text = data['name'] ?? '';
      _productDescriptionController.text = data['description'] ?? '';
      _productPriceController.text = (data['price'] ?? 0.0).toString();
      _productCategoryController.text = data['category'] ?? '';
    } else if (_selectedCollectionIndex == 1) { // Services
      _serviceTitleController.text = data['title'] ?? '';
      _serviceDescriptionController.text = data['description'] ?? '';
      _serviceDurationController.text = (data['duration'] ?? 0).toString();
      _serviceCostController.text = (data['cost'] ?? 0.0).toString();
      _serviceAvailable = data['available'] ?? false;
    }
  }

  Future<void> _updateData() async {
    if (_selectedDocument == null) {
      _showSnackBar('Selecione um item para atualizar.', isError: true);
      return;
    }

    Map<String, dynamic> updatedData = {};
    String collectionName = _getCollectionName();

    if (_selectedCollectionIndex == 0) { // Products
      updatedData = {
        'name': _productNameController.text,
        'description': _productDescriptionController.text,
        'price': double.tryParse(_productPriceController.text) ?? 0.0,
        'category': _productCategoryController.text,
      };
    } else if (_selectedCollectionIndex == 1) { // Services
      updatedData = {
        'title': _serviceTitleController.text,
        'description': _serviceDescriptionController.text,
        'duration': int.tryParse(_serviceDurationController.text) ?? 0,
        'cost': double.tryParse(_serviceCostController.text) ?? 0.0,
        'available': _serviceAvailable,
      };
    }

    try {
      await _firestoreService.updateData(
          collectionName, _selectedDocument!.id, updatedData);
      _showSnackBar('Dados atualizados com sucesso!');
      _clearFields();
      setState(() {
        _selectedDocument = null; // Limpa a seleção após a atualização
      });
    } catch (e) {
      _showSnackBar('Falha ao atualizar dados: $e', isError: true);
    }
  }

  void _clearFields() {
    _productNameController.clear();
    _productDescriptionController.clear();
    _productPriceController.clear();
    _productCategoryController.clear();
    _serviceTitleController.clear();
    _serviceDescriptionController.clear();
    _serviceDurationController.clear();
    _serviceCostController.clear();
    setState(() {
      _serviceAvailable = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atualizar Dados'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<int>(
              value: _selectedCollectionIndex,
              decoration: const InputDecoration(
                labelText: 'Selecionar Coleção',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Produtos')),
                DropdownMenuItem(value: 1, child: Text('Serviços')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCollectionIndex = value!;
                  _selectedDocument = null; // Limpa a seleção ao mudar a coleção
                  _clearFields();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.streamData(_getCollectionName()),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum item para atualizar.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String title = _selectedCollectionIndex == 0 ? (data['name'] ?? 'N/A') : (data['title'] ?? 'N/A');

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: _selectedDocument?.id == doc.id ? Colors.blue.shade100 : null,
                      child: ListTile(
                        title: Text(title),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _loadDocumentData(doc),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedDocument != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('Editar Item Selecionado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Renderiza o formulário de edição baseado na coleção selecionada
                  if (_selectedCollectionIndex == 0) ...[
                    TextFormField(
                        controller: _productNameController,
                        decoration: const InputDecoration(labelText: 'Nome do Produto')),
                    TextFormField(
                        controller: _productDescriptionController,
                        decoration: const InputDecoration(labelText: 'Descrição')),
                    TextFormField(
                        controller: _productPriceController,
                        decoration: const InputDecoration(labelText: 'Preço'),
                        keyboardType: TextInputType.number),
                    TextFormField(
                        controller: _productCategoryController,
                        decoration: const InputDecoration(labelText: 'Categoria')),
                  ] else if (_selectedCollectionIndex == 1) ...[
                    TextFormField(
                        controller: _serviceTitleController,
                        decoration: const InputDecoration(labelText: 'Título do Serviço')),
                    TextFormField(
                        controller: _serviceDescriptionController,
                        decoration: const InputDecoration(labelText: 'Descrição')),
                    TextFormField(
                        controller: _serviceDurationController,
                        decoration: const InputDecoration(labelText: 'Duração (minutos)'),
                        keyboardType: TextInputType.number),
                    TextFormField(
                        controller: _serviceCostController,
                        decoration: const InputDecoration(labelText: 'Custo'),
                        keyboardType: TextInputType.number),
                    Row(
                      children: [
                        Checkbox(
                          value: _serviceAvailable,
                          onChanged: (bool? value) {
                            setState(() {
                              _serviceAvailable = value ?? false;
                            });
                          },
                        ),
                        const Text('Disponível'),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateData,
                    child: const Text('Confirmar Atualização'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}