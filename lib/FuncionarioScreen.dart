import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Para utilizar Timer
import 'AdicionarBebidaScreen.dart'; // Importando a tela de adicionar bebida
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FuncionarioScreen extends StatefulWidget {
  const FuncionarioScreen({Key? key}) : super(key: key);

  @override
  _FuncionarioScreenState createState() => _FuncionarioScreenState();
}

class _FuncionarioScreenState extends State<FuncionarioScreen> {
  List<Map> bebidas = [];
  List<Map> bebidasFiltradas = [];
  bool _isLoading = true;
  String _selectedCategoria = 'Todas';
  String _searchQuery = '';
  final String apiUrl =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas.json';

  // Definir o Timer
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarBebidas(); // Inicia o auto-refresh
  }

  // Função para carregar as bebidas ao iniciar
  void _carregarBebidas() async {
    try {
      List<Map> bebidasList = await _getBebidas();
      setState(() {
        bebidas = bebidasList;
        bebidasFiltradas = bebidas;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar bebidas: $e')));
    }
  }

  // Função para carregar as bebidas do Firebase
  Future<List<Map>> _getBebidas() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Verifica se o Firebase retorna dados em formato Map
        if (data is Map) {
          // Verifica se os dados possuem entradas
          return data.entries.map((entry) {
            // Cada 'entry.value' será um mapa com os dados da bebida
            final bebida = entry.value;

            // Verifica se a bebida é um Map e se contém as chaves esperadas
            if (bebida is Map) {
              return Map<String, dynamic>.from(bebida)..['id'] = entry.key;
            } else {
              return {}; // Caso não seja um Map, retorna um mapa vazio
            }
          }).toList();
        } else {
          throw Exception('Dados retornados estão no formato inesperado.');
        }
      } else {
        throw Exception('Falha ao carregar bebidas');
      }
    } catch (e) {
      throw Exception('Erro ao buscar bebidas: $e');
    }
  }

  // Função para filtrar as bebidas
  void _filtrarBebidas() {
    setState(() {
      bebidasFiltradas =
          bebidas.where((bebida) {
            // Filtro pelo nome
            bool matchesNome = bebida['nome'].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

            // Filtro pela categoria
            bool matchesCategoria =
                _selectedCategoria == 'Todas' ||
                bebida['categoria'] == _selectedCategoria;

            return matchesNome && matchesCategoria;
          }).toList();
    });
  }

  // Função para excluir bebida do Firebase
  Future<void> _excluirBebida(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas/$id.json',
        ),
      );
      if (response.statusCode == 200) {
        _carregarBebidas(); // Recarrega após excluir
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bebida excluída com sucesso!')),
        );
      } else {
        throw Exception('Falha ao excluir bebida');
      }
    } catch (e) {
      throw Exception('Erro ao excluir bebida: $e');
    }
  }

  // Função para editar a bebida no Firebase
  void _editarBebida(Map bebida, String id) {
    TextEditingController nomeController = TextEditingController(
      text: bebida['nome'],
    );
    TextEditingController precoController = TextEditingController(
      text: bebida['preco'],
    );
    TextEditingController estoqueController = TextEditingController(
      text: bebida['estoque'].toString(),
    );
    TextEditingController descricaoController = TextEditingController(
      text: bebida['descricao'] ?? '',
    );
    TextEditingController volumeController = TextEditingController(
      text: bebida['volume'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Bebida'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                decoration: const InputDecoration(labelText: 'Nome da Bebida'),
              ),
              TextField(
                controller: precoController,
                decoration: const InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: estoqueController,
                decoration: const InputDecoration(labelText: 'Estoque'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              TextField(
                controller: volumeController,
                decoration: const InputDecoration(labelText: 'Volume'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Salva as alterações
                Map updatedBebida = {
                  'nome': nomeController.text,
                  'preco': precoController.text,
                  'estoque': int.tryParse(estoqueController.text) ?? 0,
                  'descricao': descricaoController.text,
                  'volume': volumeController.text,
                };
                _editarBebidaFirebase(id, updatedBebida);
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              child: const Text('Salvar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo sem salvar
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Função para editar a bebida no Firebase
  Future<void> _editarBebidaFirebase(String id, Map bebida) async {
    try {
      // Usando PATCH para atualizar apenas os campos que foram alterados
      final response = await http.patch(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas/$id.json',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bebida),
      );

      if (response.statusCode == 200) {
        // Atualiza a bebida local na lista
        setState(() {
          // Encontra o índice da bebida editada
          int index = bebidas.indexWhere((item) => item['id'] == id);
          if (index != -1) {
            // Atualiza a bebida na lista
            bebidas[index] = {
              ...bebidas[index],
              ...bebida,
            }; // Mantém o id e atualiza os campos modificados
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bebida editada com sucesso!')),
        );
      } else {
        throw Exception('Falha ao editar bebida');
      }
    } catch (e) {
      throw Exception('Erro ao editar bebida: $e');
    }
  }

  // Função para gerar relatório Excel
  Future<void> _gerarRelatorioExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // Adiciona cabeçalho
    sheet.appendRow(['Nome', 'Preço', 'Estoque', 'Volume']);

    // Adiciona as bebidas ao relatório
    for (var bebida in bebidas) {
      sheet.appendRow([
        bebida['nome'] ?? '',
        bebida['preco'] ?? '0.00',
        bebida['estoque']?.toString() ?? '0',
        bebida['volume'] ?? '',
      ]);
    }

    // Salva o arquivo Excel no dispositivo
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/relatorio_bebidas.xlsx');
    await file.writeAsBytes(await excel.encode() ?? []);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Relatório gerado com sucesso!')));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Bebidas e Estoque'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de pesquisa por nome
            TextField(
              onChanged: (query) {
                setState(() {
                  _searchQuery = query;
                  _filtrarBebidas();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Pesquisar por nome',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            // Filtro por categoria
            DropdownButton<String>(
              value: _selectedCategoria,
              onChanged: (newValue) {
                setState(() {
                  _selectedCategoria = newValue!;
                  _filtrarBebidas();
                });
              },
              items:
                  <String>[
                    'Todas',
                    'Cerveja',
                    'Whisky',
                    'Vodka',
                    'Refrigerante',
                    'Energético',
                    'Itens Variados',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),

            // Exibe a tabela de bebidas e estoque
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: bebidasFiltradas.length,
                        itemBuilder: (context, index) {
                          final bebida = bebidasFiltradas[index];
                          String nome = bebida['nome'] ?? 'Nome não disponível';
                          String preco = bebida['preco'] ?? '0.00';
                          String estoque = bebida['estoque']?.toString() ?? '0';
                          String id = bebida['id'] ?? '';

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
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
                                      _editarBebida(bebida, id);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _excluirBebida(id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),

            // Botões de funcionalidades do funcionário
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Navegar para a tela de adicionar bebida
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdicionarBebidaScreen(),
                      ),
                    ).then((_) => _carregarBebidas());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 50,
                    ),
                  ),
                  child: const Text('Adicionar Bebida'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _gerarRelatorioExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 50,
                    ),
                  ),
                  child: const Text('Gerar Relatório Excel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
