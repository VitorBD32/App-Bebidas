import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdicionarBebidaScreen extends StatefulWidget {
  const AdicionarBebidaScreen({Key? key}) : super(key: key);

  @override
  _AdicionarBebidaScreenState createState() => _AdicionarBebidaScreenState();
}

class _AdicionarBebidaScreenState extends State<AdicionarBebidaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _precoController = TextEditingController();
  final _estoqueController = TextEditingController();
  final _volumeController = TextEditingController();
  String? _categoriaSelecionada;

  final List<String> categorias = [
    'Cerveja',
    'Whisky',
    'Vodka',
    'Refrigerante',
    'Energético',
    'Itens Variados',
  ];

  void _adicionarBebida() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final nome = _nomeController.text;
    final descricao = _descricaoController.text;
    final preco = _precoController.text;
    final estoque = _estoqueController.text;
    final volume = _volumeController.text;

    Map<String, dynamic> bebida = {
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'estoque': int.tryParse(estoque) ?? 0,
      'volume': volume.isEmpty ? null : volume,
      'categoria': _categoriaSelecionada,
    };

    _adicionarBebidaFirebase(bebida)
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bebida adicionada com sucesso!')),
            );
            Navigator.pop(context);
          }
        })
        .catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao adicionar bebida: $e')),
            );
          }
        })
        .whenComplete(() {});
  }

  Future<void> _adicionarBebidaFirebase(Map<String, dynamic> bebida) async {
    // Tipo explícito
    try {
      final response = await http.post(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas.json',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bebida),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        print("Erro RTDB (adicionar bebida): ${response.body}");
        throw Exception(
          'Falha ao adicionar bebida. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      print("Exceção (adicionar bebida): $e");
      throw Exception('Erro ao comunicar com Firebase: $e');
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _estoqueController.dispose();
    _volumeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Nova Bebida'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Detalhes da Bebida',
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
                        labelText: 'Nome da Bebida',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_bar),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o nome da bebida.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira a descrição.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _precoController,
                      decoration: const InputDecoration(
                        labelText: 'Preço (ex: 10.99)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira o preço.';
                        }
                        if (double.tryParse(value.replaceAll(',', '.')) ==
                            null) {
                          return 'Por favor, insira um preço válido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _estoqueController,
                      decoration: const InputDecoration(
                        labelText: 'Estoque',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, insira a quantidade em estoque.';
                        }
                        if (int.tryParse(value) == null ||
                            (int.tryParse(value)! < 0)) {
                          return 'Por favor, insira um número válido para o estoque.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _volumeController,
                      decoration: const InputDecoration(
                        labelText: 'Volume (ex: 750ml, 1L) - Opcional',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_drink_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _categoriaSelecionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      hint: const Text('Escolha a categoria'),
                      isExpanded: true,
                      items:
                          categorias.map((String categoria) {
                            return DropdownMenuItem<String>(
                              value: categoria,
                              child: Text(categoria),
                            );
                          }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _categoriaSelecionada = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione uma categoria.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Adicionar Bebida'),
                      onPressed: _adicionarBebida,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
