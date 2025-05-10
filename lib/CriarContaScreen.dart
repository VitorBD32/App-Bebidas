import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'LoginScreen.dart';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({Key? key}) : super(key: key);

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  // Função para criar uma nova conta
  Future<void> _criarConta() async {
    setState(() {
      _isLoading = true; // Inicia o carregamento
    });

    try {
      final email = _emailController.text.trim();
      final senha = _senhaController.text.trim();

      // Cria a conta com o Firebase usando email e senha
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conta criada com sucesso!')),
      );

      // Redireciona para a tela de login após criação da conta
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar conta: $e')));
    } finally {
      setState(() {
        _isLoading = false; // Finaliza o carregamento após a criação da conta
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _senhaController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _criarConta,
                  child: const Text('Criar Conta'),
                ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // Volta para a tela de login
                Navigator.pop(context);
              },
              child: const Text('Já tem uma conta? Faça login'),
            ),
          ],
        ),
      ),
    );
  }
}
