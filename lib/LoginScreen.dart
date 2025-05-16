import 'package:app_de_bebidas/FuncionarioScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'CriarContaScreen.dart'; // Tela de criação de conta
import 'principalCliente.dart'; // Tela principal para o cliente
import 'LoginScreenFuncionario.dart'; // Nova tela de login para funcionário
import 'EsqueciSenhaScreen.dart'; // Tela de "Esqueci a Senha"

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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                const LoginScreenFuncionario(), // Redireciona para a tela de login do funcionário
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seja Bem-Vindo'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Center(
        // Centraliza o conteúdo na tela
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo ou imagem, se desejado
                Icon(
                  Icons.person,
                  size: 100,
                  color: Colors.deepPurple,
                ), // Exemplo de ícone de logo

                const SizedBox(height: 40),
                // Campo de e-mail
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
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
                      prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Campo de senha
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
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
                      prefixIcon: Icon(Icons.lock, color: Colors.deepPurple),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Botões de Login
                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                      children: [
                        ElevatedButton(
                          onPressed:
                              _isLoading ? null : () => _loginCliente(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text(
                            'Login como Cliente',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          // Posiciona o botão no canto superior direito
                          alignment: Alignment.topRight,
                          child: ElevatedButton(
                            onPressed: () => _loginFuncionario(context),
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
                              'Login como Funcionário',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
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
                          child: const Text(
                            'Criar nova conta',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const EsqueciSenhaScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Esqueci minha senha',
                            style: TextStyle(
                              color: Colors.deepPurple,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
