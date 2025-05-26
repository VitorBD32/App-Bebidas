import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CriarContaScreen extends StatefulWidget {
  const CriarContaScreen({Key? key}) : super(key: key);

  @override
  State<CriarContaScreen> createState() => _CriarContaScreenState();
}

class _CriarContaScreenState extends State<CriarContaScreen> {
  final _formKey = GlobalKey<FormState>(); // Chave para o formulário
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _dataNascimentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  // Função para salvar dados adicionais do cliente no Realtime Database
  Future<void> _salvarDadosAdicionaisDoCliente(
    String uid,
    Map<String, dynamic> dadosCliente,
  ) async {
    final url = Uri.parse(
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/clientes/$uid.json',
    );
    try {
      final response = await http.put(
        // Usamos PUT para definir/substituir os dados no caminho do UID
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dadosCliente),
      );

      if (response.statusCode >= 400) {
        print('Erro RTDB (salvar dados cliente): ${response.body}');
        throw Exception(
          'Falha ao salvar dados adicionais. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Exceção ao salvar dados do cliente: $e');
      throw Exception(
        'Erro ao comunicar com o banco de dados para salvar perfil: $e',
      );
    }
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final senha = _senhaController.text.trim();
      final nome = _nomeController.text.trim();
      final cpf = _cpfController.text.trim();
      final dataNascimento = _dataNascimentoController.text.trim();

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: senha);

      User? user = userCredential.user;

      if (user != null) {
        Map<String, dynamic> dadosCliente = {
          'nome': nome,
          'cpf': cpf,
          'dataNascimento': dataNascimento,
          'email': email,
          'uid': user.uid,
          'criadoEm': DateTime.now().toIso8601String(),
        };

        await _salvarDadosAdicionaisDoCliente(user.uid, dadosCliente);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta criada e perfil salvo com sucesso!'),
            ),
          );
          Navigator.pop(context); // Volta para a tela de login
        }
      } else {
        throw Exception('Usuário não criado no Firebase Auth.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar conta: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Nova Conta'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Crie sua conta',
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Completo',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira seu nome completo.';
                        }
                        if (value.trim().split(' ').length < 2) {
                          return 'Por favor, insira nome e sobrenome.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cpfController,
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira seu CPF.';
                        }
                        if (value.replaceAll(RegExp(r'[^0-9]'), '').length !=
                            11) {
                          return 'CPF deve conter 11 dígitos.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dataNascimentoController,
                      decoration: const InputDecoration(
                        labelText: 'Data de Nascimento (DD/MM/AAAA)',
                        border: OutlineInputBorder(),
                        hintText: 'Ex: 01/01/1990',
                      ),
                      keyboardType: TextInputType.datetime,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira sua data de nascimento.';
                        }
                        try {
                          final parts = value.split('/');
                          if (parts.length != 3) throw FormatException();
                          final day = int.parse(parts[0]);
                          final month = int.parse(parts[1]);
                          final year = int.parse(parts[2]);
                          // Validação básica do ano para evitar anos muito distantes
                          if (year < 1900 || year > DateTime.now().year) {
                            return 'Ano de nascimento inválido.';
                          }
                          DateTime(
                            year,
                            month,
                            day,
                          ); // Tenta criar a data para validar
                        } catch (e) {
                          return 'Formato de data inválido. Use DD/MM/AAAA.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira seu e-mail.';
                        }

                        final String trimmedEmail = value.trim();

                        // Sua verificação básica de formato
                        if (!trimmedEmail.contains('@') ||
                            !trimmedEmail.contains('.')) {
                          return 'Por favor, insira um e-mail válido (faltando @ ou .).';
                        }

                        // Converte para minúsculas para a verificação de domínio
                        final String lowercasedEmail =
                            trimmedEmail.toLowerCase();

                        List<String> parts = lowercasedEmail.split('@');

                        if (parts.length > 1) {
                          String domainPart = parts[1];
                          if (domainPart.isEmpty) {
                            return 'Domínio do e-mail inválido.';
                          }
                          if (domainPart.contains("funcionario") ||
                              domainPart.contains("administracao")) {
                            return 'E-mails com "funcionario" ou "administracao" não são permitidos.';
                          }
                          if (!domainPart.contains('.')) {
                            return 'Domínio do e-mail inválido (ex: dominio.com).';
                          }
                        } else {
                          return 'Formato de e-mail inválido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaController,
                      decoration: const InputDecoration(
                        labelText: 'Senha (mínimo 6 caracteres)',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, insira sua senha.';
                        }
                        if (value.length < 6) {
                          return 'A senha deve ter no mínimo 6 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: _criarConta,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: const Text('Criar Conta'),
                        ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                Navigator.pop(context);
                              },
                      child: const Text('Já tem uma conta? Faça login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
