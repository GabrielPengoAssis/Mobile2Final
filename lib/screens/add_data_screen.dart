import 'package:flutter/material.dart';
import 'package:mobile2/services/firestore_service.dart';

class AddDataScreen extends StatefulWidget {
  const AddDataScreen({super.key});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

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

  // Controllers para Orders
  final TextEditingController _orderProductNameController = TextEditingController();
  final TextEditingController _orderQuantityController = TextEditingController();
  final TextEditingController _orderTotalAmountController = TextEditingController();
  final TextEditingController _orderStatusController = TextEditingController();

  int _selectedCollectionIndex = 0; // 0: Products, 1: Services, 2: Orders

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _addData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Map<String, dynamic> data = {};
      String collectionName = '';

      switch (_selectedCollectionIndex) {
        case 0: // Products
          collectionName = 'products';
          data = {
            'name': _productNameController.text,
            'description': _productDescriptionController.text,
            'price': double.tryParse(_productPriceController.text) ?? 0.0,
            'category': _productCategoryController.text,
            // 'productId' será gerado automaticamente pelo Firestore add()
          };
          break;
        case 1: // Services
          collectionName = 'services';
          data = {
            'title': _serviceTitleController.text,
            'description': _serviceDescriptionController.text,
            'duration': int.tryParse(_serviceDurationController.text) ?? 0,
            'cost': double.tryParse(_serviceCostController.text) ?? 0.0,
            'available': _serviceAvailable,
            // 'serviceId' será gerado automaticamente
          };
          break;
        case 2: // Orders
          collectionName = 'orders';
          data = {
            'productName': _orderProductNameController.text,
            'quantity': int.tryParse(_orderQuantityController.text) ?? 0,
            'totalAmount': double.tryParse(_orderTotalAmountController.text) ?? 0.0,
            'orderDate': DateTime.now(), // Usar Timestamp.now() no FirestoreService
            'status': _orderStatusController.text,
            // 'orderId' será gerado automaticamente
          };
          break;
      }

      try {
        await _firestoreService.addData(collectionName, data);
        _showSnackBar('Dados inseridos com sucesso na coleção $collectionName!');
        // Limpar campos após sucesso
        _productNameController.clear();
        _productDescriptionController.clear();
        _productPriceController.clear();
        _productCategoryController.clear();
        _serviceTitleController.clear();
        _serviceDescriptionController.clear();
        _serviceDurationController.clear();
        _serviceCostController.clear();
        _serviceAvailable = false;
        _orderProductNameController.clear();
        _orderQuantityController.clear();
        _orderTotalAmountController.clear();
        _orderStatusController.clear();
        setState(() {}); // Força a reconstrução para atualizar o checkbox, se necessário
      } catch (e) {
        _showSnackBar('Falha ao inserir dados: $e', isError: true);
      }
    }
  }

  Widget _buildProductForm() {
    return Column(
      children: [
        TextFormField(
          controller: _productNameController,
          decoration: const InputDecoration(labelText: 'Nome do Produto'),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        TextFormField(
          controller: _productDescriptionController,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
        TextFormField(
          controller: _productPriceController,
          decoration: const InputDecoration(labelText: 'Preço'),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        TextFormField(
          controller: _productCategoryController,
          decoration: const InputDecoration(labelText: 'Categoria'),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
      ],
    );
  }

  Widget _buildServiceForm() {
    return Column(
      children: [
        TextFormField(
          controller: _serviceTitleController,
          decoration: const InputDecoration(labelText: 'Título do Serviço'),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        TextFormField(
          controller: _serviceDescriptionController,
          decoration: const InputDecoration(labelText: 'Descrição'),
        ),
        TextFormField(
          controller: _serviceDurationController,
          decoration: const InputDecoration(labelText: 'Duração (em minutos)'),
          keyboardType: TextInputType.number,
        ),
        TextFormField(
          controller: _serviceCostController,
          decoration: const InputDecoration(labelText: 'Custo'),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
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
    );
  }

  Widget _buildOrderForm() {
    return Column(
      children: [
        TextFormField(
          controller: _orderProductNameController,
          decoration: const InputDecoration(labelText: 'Nome do Produto/Serviço'),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        TextFormField(
          controller: _orderQuantityController,
          decoration: const InputDecoration(labelText: 'Quantidade'),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        TextFormField(
          controller: _orderTotalAmountController,
          decoration: const InputDecoration(labelText: 'Valor Total'),
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
        TextFormField(
          controller: _orderStatusController,
          decoration: const InputDecoration(labelText: 'Status do Pedido'),
          validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inserir Novos Dados'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                value: _selectedCollectionIndex,
                decoration: const InputDecoration(
                  labelText: 'Selecionar Coleção',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Produtos')),
                  DropdownMenuItem(value: 1, child: Text('Serviços')),
                  DropdownMenuItem(value: 2, child: Text('Pedidos')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCollectionIndex = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              // Exibe o formulário de acordo com a coleção selecionada
              if (_selectedCollectionIndex == 0) _buildProductForm(),
              if (_selectedCollectionIndex == 1) _buildServiceForm(),
              if (_selectedCollectionIndex == 2) _buildOrderForm(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addData,
                child: const Text('Adicionar Dados'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}