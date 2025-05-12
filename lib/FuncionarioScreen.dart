import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para usar json.decode

class FuncionarioScreen extends StatefulWidget {
  const FuncionarioScreen({Key? key}) : super(key: key);

  @override
  _FuncionarioScreenState createState() => _FuncionarioScreenState();
}

class _FuncionarioScreenState extends State<FuncionarioScreen> {
  List<Map> bebidas = [];
  List<String> categorias = [];
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _estoqueController = TextEditingController();
  String? _selectedCategoria;
  String?
  _selectedTipo; // Tipo de bebida selecionado (cerveja, energético, etc.)
  bool _isAdding = false; // Controla a visibilidade do formulário

  // URL do seu Realtime Database no Firebase
  final String apiUrl =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas.json';

  // Função para obter as categorias e as bebidas do banco de dados
  Future<void> _getBebidasECategorias() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          // Obter as categorias com base nas chaves do banco
          categorias = List<String>.from(data.keys);
        });
      } else {
        throw Exception('Falha ao carregar dados');
      }
    } catch (e) {
      print('Erro ao buscar dados: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao carregar dados')));
    }
  }

  // Função para adicionar uma nova bebida
  void _adicionarBebida() async {
    final nome = _nomeController.text.trim();
    final preco = _precoController.text.trim();
    final estoque = int.tryParse(_estoqueController.text.trim()) ?? 0;

    // Verifica se todos os campos obrigatórios estão preenchidos
    if (nome.isEmpty ||
        preco.isEmpty ||
        estoque <= 0 ||
        _selectedCategoria == null ||
        _selectedTipo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha todos os campos corretamente.'),
        ),
      );
      return;
    }

    // Criar um ID único para a bebida
    final String bebidaId = DateTime.now().millisecondsSinceEpoch.toString();

    // Criar o objeto de bebida conforme o tipo de bebida selecionado
    final bebida = {'nome': nome, 'preco': preco, 'estoque': estoque};

    // Definindo os campos específicos para cada tipo de bebida
    if (_selectedTipo == 'cervejas') {
      bebida.addAll({
        'descricao': '',
        'estilo': {'IPA': '', 'Lager': '', 'Stout': '', 'Weiss': ''},
        'marca': '',
        'volume': '',
      });
    } else if (_selectedTipo == 'energético') {
      bebida.addAll({'sabor': '', 'semAcucar': true, 'teorcafeina': ''});
    } else if (_selectedTipo == 'refrigerante') {
      bebida.addAll({'sabor': '', 'semAcucar': true});
    } else if (_selectedTipo == 'sucos artificiais') {
      bebida.addAll({'concentrado': true, 'sabor': ''});
    } else if (_selectedTipo == 'vodka') {
      bebida.addAll({'abv': 0, 'base': '', 'origem': ''});
    } else if (_selectedTipo == 'whiskys') {
      bebida.addAll({'abv': 0, 'idade': '', 'origem': '', 'tipo': ''});
    }

    // Enviar os dados para o Firebase
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/$bebidaId.json'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bebida),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bebida adicionada com sucesso!')),
        );
        _getBebidasECategorias(); // Recarrega a lista de bebidas e categorias
        setState(() {
          _isAdding = false; // Fechar o formulário de adicionar bebida
        });
        _nomeController.clear();
        _precoController.clear();
        _estoqueController.clear();
      } else {
        throw Exception('Falha ao adicionar bebida');
      }
    } catch (e) {
      print('Erro ao adicionar bebida: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao adicionar bebida')));
    }
  }

  // Função para cancelar o formulário de adição de bebida
  void _cancelarAdicao() {
    setState(() {
      _isAdding = false; // Fechar o formulário de adicionar bebida
    });
    _nomeController.clear();
    _precoController.clear();
    _estoqueController.clear();
  }

  @override
  void initState() {
    super.initState();
    _getBebidasECategorias(); // Obtém as bebidas e categorias ao iniciar a tela
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Bebidas')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_isAdding) ...[
              // Formulário de adição de bebida
              DropdownButton<String>(
                value: _selectedTipo,
                hint: const Text('Escolha o tipo de bebida'),
                items:
                    categorias.map((categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedTipo = newValue;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_selectedTipo != null) ...[
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Bebida',
                  ),
                ),
                TextField(
                  controller: _precoController,
                  decoration: const InputDecoration(labelText: 'Preço'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _estoqueController,
                  decoration: const InputDecoration(labelText: 'Estoque'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _adicionarBebida,
                  child: const Text('Adicionar Bebida'),
                ),
                TextButton(
                  onPressed: _cancelarAdicao,
                  child: const Text('Cancelar'),
                ),
              ],
            ] else ...[
              // Exibindo a lista de bebidas
              Expanded(
                child:
                    bebidas.isEmpty
                        ? const Center(
                          child: Text('Nenhuma bebida disponível.'),
                        )
                        : ListView.builder(
                          itemCount: bebidas.length,
                          itemBuilder: (context, index) {
                            var bebida = bebidas[index];
                            String nome =
                                bebida['nome'] ?? 'Nome não disponível';
                            String preco = bebida['preco'] ?? '0.00';
                            String estoque = bebida['estoque'].toString();
                            String bebidaId = bebida['id'];

                            return ListTile(
                              title: Text(nome),
                              subtitle: Text(
                                'Preço: R\$ $preco\nEstoque: $estoque',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      // Exemplo de edição
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      // Excluir bebida
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
            // Barra de navegação inferior
            BottomNavigationBar(
              backgroundColor: const Color.fromARGB(255, 6, 8, 10),
              selectedItemColor: const Color.fromARGB(255, 221, 37, 37),
              unselectedItemColor: const Color.fromARGB(153, 37, 179, 68),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.add),
                  label: 'Adicionar Bebida',
                ),
              ],
              onTap: (index) {
                if (index == 1) {
                  setState(() {
                    _isAdding = true; // Ativar o modo de adicionar bebida
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
