import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para monitorar o estado de autenticação do usuário
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Método de Login
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Tratar erros específicos do Firebase Auth
      print('Erro de login: ${e.message}');
      rethrow; // Relançar o erro para a UI lidar
    } catch (e) {
      print('Erro inesperado de login: $e');
      rethrow;
    }
  }

  // Método de Registro (com dados adicionais)
  Future<User?> registerWithEmailAndPassword(String email, String password, String name, String phone) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? newUser = result.user;

      if (newUser != null) {
        // Armazenar dados adicionais no Firestore
        await _firestore.collection('users').doc(newUser.uid).set({
          'uid': newUser.uid,
          'name': name,
          'phone': phone,
          'email': email,
          'createdAt': Timestamp.now(),
        });
      }
      return newUser;
    } on FirebaseAuthException catch (e) {
      print('Erro de registro: ${e.message}');
      rethrow;
    } catch (e) {
      print('Erro inesperado de registro: $e');
      rethrow;
    }
  }

  // Método de Recuperação de Senha
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Erro ao enviar e-mail de redefinição de senha: ${e.message}');
      rethrow;
    } catch (e) {
      print('Erro inesperado ao redefinir senha: $e');
      rethrow;
    }
  }

  // Método de Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erro ao fazer logout: $e');
    }
  }
}