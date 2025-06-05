import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sobre o Aplicativo'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tema Escolhido: Gerenciamento de Dados Pessoais com Firebase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Objetivo do Aplicativo:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'Este aplicativo tem como objetivo demonstrar as funcionalidades de autenticação e CRUD (Criação, Leitura, Atualização e Exclusão) de dados utilizando o Flutter e o Firebase (Authentication e Firestore). Ele permite que os usuários gerenciem seus próprios dados de forma segura e eficiente, com exemplos de diferentes tipos de informações (produtos, serviços, pedidos).',
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Desenvolvedor:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'Seu Nome Completo', // **Mude para o seu nome**
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'Tecnologias Utilizadas:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              'Flutter SDK, Firebase Authentication, Firebase Firestore, Firebase Hosting.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}