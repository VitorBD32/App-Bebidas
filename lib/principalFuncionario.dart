import 'package:flutter/material.dart';

class PrincipalFuncionarioScreen extends StatelessWidget {
  const PrincipalFuncionarioScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tela Principal - Funcionário')),
      body: const Center(child: Text('Bem-vindo, Funcionário!')),
    );
  }
}
