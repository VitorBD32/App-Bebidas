import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data'; // Import for Uint8List

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
            bool matchesNome =
                bebida['nome']?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false;
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

    // Get the current selected category or default to the first one if null
    String? currentCategory = bebida['categoria'];
    if (![
      'Cerveja',
      'Whisky',
      'Vodka',
      'Refrigerante',
      'Energético',
      'Itens Variados',
    ].contains(currentCategory)) {
      currentCategory =
          null; // Set to null if it's not a valid category from your list
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Editar Bebida'),
            content: SingleChildScrollView(
              // Added SingleChildScrollView for scrollability
              child: Column(
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
                  DropdownButtonFormField<String>(
                    value: currentCategory,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items:
                        <String>[
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
                    onChanged: (String? newValue) {
                      setState(() {
                        currentCategory = newValue;
                      });
                    },
                  ),
                ],
              ),
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
                    'categoria': currentCategory, // Update the category
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
    sheet.appendRow([
      'Nome',
      'Preço',
      'Estoque',
      'Volume',
      'Categoria',
    ]); // Added Category
    for (var bebida in bebidas) {
      sheet.appendRow([
        bebida['nome'] ?? '',
        bebida['preco'] ?? '0.00',
        bebida['estoque']?.toString() ?? '0',
        bebida['volume'] ?? '',
        bebida['categoria'] ?? '', // Added Category
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
        backgroundColor:
            Theme.of(context).colorScheme.primary, // Using theme color
        foregroundColor:
            Theme.of(context).colorScheme.onPrimary, // Using theme color
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
              decoration: const InputDecoration(
                labelText: 'Filtrar por Categoria',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_list),
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
                          Uint8List? imageBytes;
                          if (bebida['imagemBase64'] != null) {
                            try {
                              imageBytes = base64Decode(bebida['imagemBase64']);
                            } catch (e) {
                              print(
                                'Error decoding image for ${bebida['nome']}: $e',
                              );
                              imageBytes = null;
                            }
                          }

                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading:
                                  imageBytes != null
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        child: Image.memory(
                                          imageBytes,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                      ),
                              title: Text(
                                bebida['nome'] ?? 'Nome Indisponível',
                              ),
                              subtitle: Text(
                                'Preço: R\$ ${bebida['preco'] ?? '0.00'} - Estoque: ${bebida['estoque']?.toString() ?? '0'} - Cat.: ${bebida['categoria'] ?? 'N/A'}',
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
                                        () =>
                                            _editarBebida(bebida, bebida['id']),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
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
            // Centralize the Wrap widget
            Center(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center, // Added this line
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Adicionar Bebida'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdicionarBebidaScreen(),
                        ),
                      ).then((_) => _carregarBebidas());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text('Gerar Excel'),
                    onPressed: _gerarRelatorioExcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.people),
                    label: const Text('Gerenciar Funcionários'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GerenciarFuncionariosScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
