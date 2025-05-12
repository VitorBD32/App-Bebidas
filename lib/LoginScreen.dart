import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'CriarContaScreen.dart'; // Tela de criação de conta
import 'principalCliente.dart'; // Tela principal para o cliente
import 'FuncionarioScreen.dart'; // Tela principal para o funcionário

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  // Função para validar o email
  String? _validarEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Por favor, insira um e-mail.';
    }
    // Verifica se o email tem um formato válido
    RegExp regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
    if (!regex.hasMatch(email)) {
      return 'Por favor, insira um e-mail válido.';
    }
    return null;
  }

  // Função para validar a senha
  String? _validarSenha(String? senha) {
    if (senha == null || senha.isEmpty) {
      return 'Por favor, insira uma senha.';
    }
    if (senha.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  // Função de login com email e senha
  Future<void> _login(BuildContext context, String tipoUsuario) async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    final emailError = _validarEmail(email);
    final senhaError = _validarSenha(senha);

    // Verifica se há erro nos campos
    if (emailError != null || senhaError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailError ?? senhaError!)));
      return;
    }

    setState(() {
      _isLoading = true; // Inicia o carregamento
    });

    try {
      // Realiza o login com o Firebase usando email e senha
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: senha);
      final user = userCredential.user;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$tipoUsuario logado: ${user.displayName ?? "Usuário"}',
            ),
          ),
        );

        // Redireciona para a tela correta dependendo do tipo de usuário
        if (tipoUsuario == "Cliente") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PrincipalClienteScreen(),
            ),
          );
        } else if (tipoUsuario == "Funcionário") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const FuncionarioScreen()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao fazer login: $e')));
    } finally {
      setState(() {
        _isLoading = false; // Finaliza o carregamento após o login
      });
    }
  }

  // Função de login para cliente
  void _loginCliente(BuildContext context) {
    _login(context, "Cliente");
  }

  // Função de login para funcionário
  void _loginFuncionario(BuildContext context) {
    _login(context, "Funcionário");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
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
                ? const CircularProgressIndicator() // Mostra o carregamento enquanto realiza o login
                : Column(
                  children: [
                    ElevatedButton(
                      onPressed:
                          _isLoading ? null : () => _loginCliente(context),
                      child: const Text('Login como Cliente'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed:
                          _isLoading ? null : () => _loginFuncionario(context),
                      child: const Text('Login como Funcionário'),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CriarContaScreen(),
                          ),
                        );
                      },
                      child: const Text('Criar nova conta'),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
