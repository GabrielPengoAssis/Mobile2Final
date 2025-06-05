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
        'uid': uid, // Garante que os dados são do usuário logado
        'createdAt': Timestamp.now(),
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
      await _firestore.collection(collectionName).doc(docId).update(data);
    } catch (e) {
      print('Erro ao atualizar dados em $collectionName (docId: $docId): $e');
      rethrow;
    }
  }

  // Recuperação de Dados (Stream)
  Stream<QuerySnapshot> streamData(String collectionName) {
    String? uid = _getCurrentUid();
    if (uid == null) {
      // Retorna um stream vazio se o usuário não estiver logado
      return Stream.empty();
    }
    return _firestore.collection(collectionName).where('uid', isEqualTo: uid).snapshots();
  }

  // Recuperação de Dados (Future, para pesquisa específica)
  Future<List<DocumentSnapshot>> getFilteredData(String collectionName, String field, String query, {String? orderByField, bool descending = false}) async {
    String? uid = _getCurrentUid();
    if (uid == null) {
      throw Exception("Usuário não autenticado.");
    }
    try {
      Query firestoreQuery = _firestore.collection(collectionName).where('uid', isEqualTo: uid);

      // Pesquisa insensível a maiúsculas e minúsculas
      firestoreQuery = firestoreQuery
          .where(field, isGreaterThanOrEqualTo: query.toLowerCase())
          .where(field, isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff');

      if (orderByField != null) {
        firestoreQuery = firestoreQuery.orderBy(orderByField, descending: descending);
      }

      QuerySnapshot snapshot = await firestoreQuery.get();
      return snapshot.docs;
    } catch (e) {
      print('Erro ao buscar dados filtrados em $collectionName: $e');
      rethrow;
    }
  }
}