import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'AdicionarBebidaScreen.dart';
import 'GerenciarFuncionariosScreen.dart'; // <-- nova tela

class AdmScreen extends StatefulWidget {
  const AdmScreen({Key? key}) : super(key: key);

  @override
  _AdmScreenState createState() => _AdmScreenState();
}

class _AdmScreenState extends State<AdmScreen> {
  List<Map> bebidas = [];
  List<Map> bebidasFiltradas = [];
  bool _isLoading = true;
  String _selectedCategoria = 'Todas';
  String _searchQuery = '';
  final String apiUrl =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas.json';

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregarBebidas();
  }

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

  Future<List<Map>> _getBebidas() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          return data.entries.map((entry) {
            final bebida = entry.value;
            if (bebida is Map) {
              return Map<String, dynamic>.from(bebida)..['id'] = entry.key;
            } else {
              return {};
            }
          }).toList();
        } else {
          throw Exception('Formato inesperado dos dados.');
        }
      } else {
        throw Exception('Erro ao buscar bebidas.');
      }
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }

  void _filtrarBebidas() {
    setState(() {
      bebidasFiltradas =
          bebidas.where((bebida) {
            bool matchesNome = bebida['nome'].toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );
            bool matchesCategoria =
                _selectedCategoria == 'Todas' ||
                bebida['categoria'] == _selectedCategoria;
            return matchesNome && matchesCategoria;
          }).toList();
    });
  }

  Future<void> _excluirBebida(String id) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas/$id.json',
        ),
      );
      if (response.statusCode == 200) {
        _carregarBebidas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bebida excluída com sucesso!')),
        );
      } else {
        throw Exception('Erro ao excluir bebida.');
      }
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }

  void _editarBebida(Map bebida, String id) {
    final nomeController = TextEditingController(text: bebida['nome']);
    final precoController = TextEditingController(text: bebida['preco']);
    final estoqueController = TextEditingController(
      text: bebida['estoque'].toString(),
    );
    final descricaoController = TextEditingController(
      text: bebida['descricao'] ?? '',
    );
    final volumeController = TextEditingController(
      text: bebida['volume'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar Bebida'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
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
            actions: [
              TextButton(
                onPressed: () {
                  Map bebidaAtualizada = {
                    'nome': nomeController.text,
                    'preco': precoController.text,
                    'estoque': int.tryParse(estoqueController.text) ?? 0,
                    'descricao': descricaoController.text,
                    'volume': volumeController.text,
                  };
                  _editarBebidaFirebase(id, bebidaAtualizada);
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

  Future<void> _editarBebidaFirebase(String id, Map bebida) async {
    try {
      final response = await http.patch(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas/$id.json',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bebida),
      );
      if (response.statusCode == 200) {
        _carregarBebidas();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bebida editada com sucesso!')),
        );
      } else {
        throw Exception('Erro ao editar bebida.');
      }
    } catch (e) {
      throw Exception('Erro: $e');
    }
  }

  Future<void> _gerarRelatorioExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];
    sheet.appendRow(['Nome', 'Preço', 'Estoque', 'Volume']);
    for (var bebida in bebidas) {
      sheet.appendRow([
        bebida['nome'] ?? '',
        bebida['preco'] ?? '0.00',
        bebida['estoque']?.toString() ?? '0',
        bebida['volume'] ?? '',
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/relatorio_adm.xlsx');
    await file.writeAsBytes(await excel.encode() ?? []);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Relatório gerado.')));
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
        title: const Text('Administrador - Bebidas'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filtrar por Categoria',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.filter_list),
              ),
              value: _selectedCategoria,
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  _selectedCategoria = value!;
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
                  ].map((String categoria) {
                    return DropdownMenuItem<String>(
                      value: categoria,
                      child: Text(categoria),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: bebidasFiltradas.length,
                        itemBuilder: (context, index) {
                          final bebida = bebidasFiltradas[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(bebida['nome']),
                              subtitle: Text(
                                'Preço: R\$ ${bebida['preco']} - Estoque: ${bebida['estoque']}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed:
                                        () =>
                                            _editarBebida(bebida, bebida['id']),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed:
                                        () => _excluirBebida(bebida['id']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdicionarBebidaScreen(),
                      ),
                    ).then((_) => _carregarBebidas());
                  },
                  child: const Text(' + Adicionar Bebida'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
                ElevatedButton(
                  onPressed: _gerarRelatorioExcel,
                  child: const Text(' Gerar Excel'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GerenciarFuncionariosScreen(),
                      ),
                    );
                  },
                  child: const Text('Gerenciar Funcionários'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
