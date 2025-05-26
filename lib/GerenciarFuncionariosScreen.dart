import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GerenciarFuncionariosScreen extends StatefulWidget {
  const GerenciarFuncionariosScreen({super.key});

  @override
  State<GerenciarFuncionariosScreen> createState() =>
      _GerenciarFuncionariosScreenState();
}

class _GerenciarFuncionariosScreenState
    extends State<GerenciarFuncionariosScreen> {
  List<Map<String, dynamic>> funcionarios = [];
  List<Map<String, dynamic>> funcionariosFiltrados = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final String url =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/funcionarios.json';

  @override
  void initState() {
    super.initState();
    _carregarFuncionarios();
  }

  Future<void> _carregarFuncionarios() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data is Map) {
          funcionarios =
              data.entries.map<Map<String, dynamic>>((entry) {
                final funcionario = Map<String, dynamic>.from(entry.value);
                funcionario['id'] = entry.key;
                return funcionario;
              }).toList();
        } else {
          funcionarios = [];
        }
        _filtrarFuncionarios();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar funcionários: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filtrarFuncionarios() {
    setState(() {
      funcionariosFiltrados =
          funcionarios.where((funcionario) {
            final nome = funcionario['nome']?.toString().toLowerCase() ?? '';
            return nome.contains(_searchQuery.toLowerCase());
          }).toList();
    });
  }

  void _mostrarDialogoFuncionario({Map<String, dynamic>? funcionario}) {
    final nomeController = TextEditingController(
      text: funcionario?['nome'] ?? '',
    );
    final cpfController = TextEditingController(
      text: funcionario?['cpf'] ?? '',
    );
    final funcaoController = TextEditingController(
      text: funcionario?['funcao'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(
              funcionario == null
                  ? 'Adicionar Funcionário'
                  : 'Editar Funcionário',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  TextField(
                    controller: cpfController,
                    decoration: const InputDecoration(labelText: 'CPF'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: funcaoController,
                    decoration: const InputDecoration(labelText: 'Função'),
                  ),
                  if (funcionario != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Matrícula: ${funcionario['matricula'] ?? "Não definida"}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  String nome = nomeController.text.trim();
                  String cpf = cpfController.text.trim();
                  String funcao = funcaoController.text.trim();

                  if (nome.isEmpty || cpf.length != 11) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Preencha corretamente os campos (CPF com 11 dígitos).',
                        ),
                      ),
                    );
                    return;
                  }

                  if (funcionario == null) {
                    _adicionarFuncionario({
                      'nome': nome,
                      'cpf': cpf,
                      'funcao': funcao,
                      // matrícula será gerada automaticamente
                    });
                  } else {
                    _editarFuncionario(funcionario['id'], {
                      'nome': nome,
                      'cpf': cpf,
                      'funcao': funcao,
                      // matrícula não pode ser editada
                    });
                  }

                  Navigator.pop(context);
                },
                child: const Text('Salvar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
    );
  }

  Future<int> _gerarProximaMatricula() async {
    // Pega o maior valor de matrícula atualmente cadastrado e soma 1
    int maiorMatricula = 0;
    for (var func in funcionarios) {
      if (func['matricula'] != null) {
        final mat = int.tryParse(func['matricula'].toString()) ?? 0;
        if (mat > maiorMatricula) maiorMatricula = mat;
      }
    }
    return maiorMatricula + 1;
  }

  Future<void> _adicionarFuncionario(Map<String, String> funcionario) async {
    try {
      final matricula = await _gerarProximaMatricula();
      funcionario['matricula'] = matricula.toString();

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(funcionario),
      );
      if (response.statusCode == 200) {
        await _carregarFuncionarios();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário adicionado!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar funcionário: $e')),
      );
    }
  }

  Future<void> _editarFuncionario(
    String id,
    Map<String, String> funcionario,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/funcionarios/$id.json',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(funcionario),
      );
      if (response.statusCode == 200) {
        await _carregarFuncionarios();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário atualizado!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao editar funcionário: $e')));
    }
  }

  Future<void> _removerFuncionario(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/funcionarios/$id.json',
        ),
      );
      if (response.statusCode == 200) {
        await _carregarFuncionarios();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Funcionário removido!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover funcionário: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Funcionários'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Pesquisar por nome',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filtrarFuncionarios();
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : funcionariosFiltrados.isEmpty
                      ? const Center(
                        child: Text('Nenhum funcionário encontrado.'),
                      )
                      : ListView.builder(
                        itemCount: funcionariosFiltrados.length,
                        itemBuilder: (context, index) {
                          final funcionario = funcionariosFiltrados[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(funcionario['nome'] ?? 'Sem nome'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CPF: ${funcionario['cpf']}'),
                                  Text(
                                    'Função: ${funcionario['funcao'] ?? '-'}',
                                  ),
                                  Text(
                                    'Matrícula: ${funcionario['matricula'] ?? '-'}',
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed:
                                        () => _mostrarDialogoFuncionario(
                                          funcionario: funcionario,
                                        ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed:
                                        () => _removerFuncionario(
                                          funcionario['id'],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoFuncionario(),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Funcionário'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 40,
                ),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
