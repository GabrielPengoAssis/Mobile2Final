import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // Garante que o usuário esteja logado
  String? _getCurrentUid() {
    return currentUser?.uid;
  }

  // Inserção de Dados
  Future<void> addData(String collectionName, Map<String, dynamic> data) async {
    String? uid = _getCurrentUid();
    if (uid == null) {
      throw Exception("Usuário não autenticado.");
    }
    try {
      await _firestore.collection(collectionName).add({
        ...data,
        'uid': uid,
        'createdAt': Timestamp.now(),
        // Adiciona campos normalizados para pesquisa
        if (data.containsKey('name')) 'nameNormalized': data['name']?.toString().toLowerCase(),
        if (data.containsKey('title')) 'titleNormalized': data['title']?.toString().toLowerCase(),
        if (data.containsKey('description')) 'descriptionNormalized': data['description']?.toString().toLowerCase(),
        if (data.containsKey('category')) 'categoryNormalized': data['category']?.toString().toLowerCase(),
        if (data.containsKey('productName')) 'productNameNormalized': data['productName']?.toString().toLowerCase(),
        if (data.containsKey('status')) 'statusNormalized': data['status']?.toString().toLowerCase(),
      });
    } catch (e) {
      print('Erro ao adicionar dados em $collectionName: $e');
      rethrow;
    }
  }

  // Atualização de Dados
  Future<void> updateData(String collectionName, String docId, Map<String, dynamic> data) async {
    String? uid = _getCurrentUid();
    if (uid == null) {
      throw Exception("Usuário não autenticado.");
    }
    try {
      // Verifica se o documento pertence ao usuário logado antes de atualizar
      DocumentSnapshot doc = await _firestore.collection(collectionName).doc(docId).get();
      if (!doc.exists || doc.data() is! Map || (doc.data() as Map)['uid'] != uid) {
        throw Exception("Documento não encontrado ou você não tem permissão para atualizá-lo.");
      }
      
      // Adiciona campos normalizados durante a atualização
      Map<String, dynamic> updatedData = Map.from(data);
      if (data.containsKey('name')) updatedData['nameNormalized'] = data['name']?.toString().toLowerCase();
      if (data.containsKey('title')) updatedData['titleNormalized'] = data['title']?.toString().toLowerCase();
      if (data.containsKey('description')) updatedData['descriptionNormalized'] = data['description']?.toString().toLowerCase();
      if (data.containsKey('category')) updatedData['categoryNormalized'] = data['category']?.toString().toLowerCase();
      if (data.containsKey('productName')) updatedData['productNameNormalized'] = data['productName']?.toString().toLowerCase();
      if (data.containsKey('status')) updatedData['statusNormalized'] = data['status']?.toString().toLowerCase();
      
      await _firestore.collection(collectionName).doc(docId).update(updatedData);
    } catch (e) {
      print('Erro ao atualizar dados em $collectionName (docId: $docId): $e');
      rethrow;
    }
  }

  // Recuperação de Dados (Stream)
  Stream<QuerySnapshot> streamData(String collectionName) {
    String? uid = _getCurrentUid();
    if (uid == null) {
      return Stream.empty();
    }
    return _firestore.collection(collectionName).where('uid', isEqualTo: uid).snapshots();
  }

  // Método melhorado para pesquisa com fallback para diferentes estratégias
  Future<List<DocumentSnapshot>> getFilteredData(
    String collectionName, 
    String field, 
    String query, {
    String? orderByField, 
    bool descending = false
  }) async {
    String? uid = _getCurrentUid();
    if (uid == null) {
      throw Exception("Usuário não autenticado.");
    }

    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Estratégia 1: Tentar com índice composto (campo normalizado + ordenação)
      return await _searchWithCompositeIndex(collectionName, field, query, uid, orderByField, descending);
    } catch (e) {
      print('Falha na pesquisa com índice composto: $e');
      try {
        // Estratégia 2: Pesquisa simples sem ordenação
        return await _searchWithoutOrdering(collectionName, field, query, uid);
      } catch (e2) {
        print('Falha na pesquisa simples: $e2');
        // Estratégia 3: Pesquisa local (menos eficiente)
        return await _searchLocally(collectionName, field, query, uid, orderByField, descending);
      }
    }
  }

  // Estratégia 1: Pesquisa com índice composto
  Future<List<DocumentSnapshot>> _searchWithCompositeIndex(
    String collectionName, 
    String field, 
    String query, 
    String uid,
    String? orderByField, 
    bool descending
  ) async {
    String normalizedField = '${field}Normalized';
    String normalizedQuery = query.toLowerCase();
    
    Query firestoreQuery = _firestore.collection(collectionName)
        .where('uid', isEqualTo: uid)
        .where(normalizedField, isGreaterThanOrEqualTo: normalizedQuery)
        .where(normalizedField, isLessThanOrEqualTo: '$normalizedQuery\uf8ff');

    if (orderByField != null) {
      String normalizedOrderField = orderByField == field ? normalizedField : '${orderByField}Normalized';
      firestoreQuery = firestoreQuery.orderBy(normalizedOrderField, descending: descending);
    }

    QuerySnapshot snapshot = await firestoreQuery.get();
    return snapshot.docs;
  }

  // Estratégia 2: Pesquisa simples sem ordenação
  Future<List<DocumentSnapshot>> _searchWithoutOrdering(
    String collectionName, 
    String field, 
    String query, 
    String uid
  ) async {
    String normalizedField = '${field}Normalized';
    String normalizedQuery = query.toLowerCase();
    
    Query firestoreQuery = _firestore.collection(collectionName)
        .where('uid', isEqualTo: uid)
        .where(normalizedField, isGreaterThanOrEqualTo: normalizedQuery)
        .where(normalizedField, isLessThanOrEqualTo: '$normalizedQuery\uf8ff');

    QuerySnapshot snapshot = await firestoreQuery.get();
    return snapshot.docs;
  }

  // Estratégia 3: Pesquisa local (busca todos os documentos do usuário e filtra localmente)
  Future<List<DocumentSnapshot>> _searchLocally(
    String collectionName, 
    String field, 
    String query, 
    String uid,
    String? orderByField, 
    bool descending
  ) async {
    print('Usando pesquisa local para $collectionName');
    
    // Busca todos os documentos do usuário
    QuerySnapshot snapshot = await _firestore.collection(collectionName)
        .where('uid', isEqualTo: uid)
        .get();
    
    String normalizedQuery = query.toLowerCase();
    
    // Filtra localmente
    List<DocumentSnapshot> filteredDocs = snapshot.docs.where((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String? fieldValue = data[field]?.toString().toLowerCase();
      return fieldValue != null && fieldValue.contains(normalizedQuery);
    }).toList();
    
    // Ordena localmente se necessário
    if (orderByField != null) {
      filteredDocs.sort((a, b) {
        Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
        Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
        
        dynamic valueA = dataA[orderByField];
        dynamic valueB = dataB[orderByField];
        
        if (valueA == null && valueB == null) return 0;
        if (valueA == null) return descending ? 1 : -1;
        if (valueB == null) return descending ? -1 : 1;
        
        int comparison = valueA.toString().toLowerCase().compareTo(valueB.toString().toLowerCase());
        return descending ? -comparison : comparison;
      });
    }
    
    return filteredDocs;
  }

  // Método para migrar documentos existentes e adicionar campos normalizados
  Future<void> migrateExistingDocuments(String collectionName) async {
    String? uid = _getCurrentUid();
    if (uid == null) {
      throw Exception("Usuário não autenticado.");
    }

    try {
      QuerySnapshot snapshot = await _firestore.collection(collectionName)
          .where('uid', isEqualTo: uid)
          .get();

      WriteBatch batch = _firestore.batch();
      int updateCount = 0;

      for (DocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        Map<String, dynamic> updates = {};

        // Adiciona campos normalizados se não existirem
        if (data.containsKey('name') && !data.containsKey('nameNormalized')) {
          updates['nameNormalized'] = data['name']?.toString().toLowerCase();
        }
        if (data.containsKey('title') && !data.containsKey('titleNormalized')) {
          updates['titleNormalized'] = data['title']?.toString().toLowerCase();
        }
        if (data.containsKey('description') && !data.containsKey('descriptionNormalized')) {
          updates['descriptionNormalized'] = data['description']?.toString().toLowerCase();
        }
        if (data.containsKey('category') && !data.containsKey('categoryNormalized')) {
          updates['categoryNormalized'] = data['category']?.toString().toLowerCase();
        }
        if (data.containsKey('productName') && !data.containsKey('productNameNormalized')) {
          updates['productNameNormalized'] = data['productName']?.toString().toLowerCase();
        }
        if (data.containsKey('status') && !data.containsKey('statusNormalized')) {
          updates['statusNormalized'] = data['status']?.toString().toLowerCase();
        }

        if (updates.isNotEmpty) {
          batch.update(doc.reference, updates);
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print('Migrados $updateCount documentos em $collectionName');
      }
    } catch (e) {
      print('Erro na migração de $collectionName: $e');
      rethrow;
    }
  }

  // Método para deletar documento
  Future<void> deleteData(String collectionName, String docId) async {
    String? uid = _getCurrentUid();
    if (uid == null) {
      throw Exception("Usuário não autenticado.");
    }
    try {
      // Verifica se o documento pertence ao usuário logado antes de deletar
      DocumentSnapshot doc = await _firestore.collection(collectionName).doc(docId).get();
      if (!doc.exists || doc.data() is! Map || (doc.data() as Map)['uid'] != uid) {
        throw Exception("Documento não encontrado ou você não tem permissão para deletá-lo.");
      }
      await _firestore.collection(collectionName).doc(docId).delete();
    } catch (e) {
      print('Erro ao deletar dados em $collectionName (docId: $docId): $e');
      rethrow;
    }
  }
}