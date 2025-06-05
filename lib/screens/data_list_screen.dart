import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile2/services/firestore_service.dart';

class DataListScreen extends StatefulWidget {
  const DataListScreen({super.key});

  @override
  State<DataListScreen> createState() => _DataListScreenState();
}

class _DataListScreenState extends State<DataListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedCollectionIndex = 0; // 0: Products, 1: Services, 2: Orders

  String _getCollectionName() {
    switch (_selectedCollectionIndex) {
      case 0:
        return 'products';
      case 1:
        return 'services';
      case 2:
        return 'orders';
      default:
        return 'products'; // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Dados'),
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
                DropdownMenuItem(value: 2, child: Text('Pedidos')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCollectionIndex = value!;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.streamData(_getCollectionName()),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum dado encontrado para esta coleção.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                    // Exibição dos dados, adaptada para cada coleção
                    Widget listItem;
                    if (_selectedCollectionIndex == 0) { // Products
                      listItem = Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(data['name'] ?? 'Sem Nome'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Descrição: ${data['description'] ?? 'N/A'}'),
                              Text('Preço: R\$${data['price']?.toStringAsFixed(2) ?? '0.00'}'),
                              Text('Categoria: ${data['category'] ?? 'N/A'}'),
                            ],
                          ),
                        ),
                      );
                    } else if (_selectedCollectionIndex == 1) { // Services
                      listItem = Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(data['title'] ?? 'Sem Título'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Descrição: ${data['description'] ?? 'N/A'}'),
                              Text('Duração: ${data['duration'] ?? '0'} minutos'),
                              Text('Custo: R\$${data['cost']?.toStringAsFixed(2) ?? '0.00'}'),
                              Text('Disponível: ${data['available'] ? 'Sim' : 'Não'}'),
                            ],
                          ),
                        ),
                      );
                    } else { // Orders
                      listItem = Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text('Pedido: ${data['productName'] ?? 'N/A'}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Quantidade: ${data['quantity'] ?? '0'}'),
                              Text('Total: R\$${data['totalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
                              Text('Data: ${data['orderDate'] != null ? (data['orderDate'] as Timestamp).toDate().toLocal().toString().split(' ')[0] : 'N/A'}'),
                              Text('Status: ${data['status'] ?? 'N/A'}'),
                            ],
                          ),
                        ),
                      );
                    }
                    return listItem;
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}