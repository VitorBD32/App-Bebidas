import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FuncionarioScreen.dart';
import 'LoginScreenAdm.dart';

class LoginScreenFuncionario extends StatefulWidget {
  const LoginScreenFuncionario({Key? key}) : super(key: key);

  @override
  _LoginScreenFuncionarioState createState() => _LoginScreenFuncionarioState();
}

class _LoginScreenFuncionarioState extends State<LoginScreenFuncionario> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _isLoading = false;

  String? _validarEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Por favor, insira um e-mail.';
    }
    final String trimmedEmail = email.trim();
    if (!trimmedEmail.toLowerCase().endsWith('@funcionario.com')) {
      return 'O e-mail deve ser de um funcionário.';
    }
    RegExp regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
    if (!regex.hasMatch(trimmedEmail)) {
      return 'Formato de e-mail inválido.';
    }
    return null;
  }

  String? _validarSenha(String? senha) {
    if (senha == null || senha.isEmpty) {
      return 'Por favor, insira uma senha.';
    }
    if (senha.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  Future<void> _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final senha = _senhaController.text.trim();

    final emailError = _validarEmail(email);
    final senhaError = _validarSenha(senha);

    if (emailError != null || senhaError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emailError ?? senhaError!)));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: senha);
      final user = userCredential.user;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Funcionário logado: ${user.displayName ?? "Usuário"}',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FuncionarioScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao fazer login: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final larguraCampo = MediaQuery.of(context).size.width * 0.8;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Funcionário'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.work, size: 100, color: Colors.green),
                const SizedBox(height: 40),

                SizedBox(
                  width: larguraCampo,
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'Digite seu e-mail',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.email, color: Colors.green),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: larguraCampo,
                  child: TextField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      hintText: 'Digite sua senha',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      prefixIcon: const Icon(Icons.lock, color: Colors.green),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _isLoading ? null : () => _login(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreenAdm(),
                      ),
                    );
                  },
                  child: const Text(
                    'Entrar como Administrador',
                    style: TextStyle(
                      color: Color.fromARGB(255, 38, 0, 255),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
