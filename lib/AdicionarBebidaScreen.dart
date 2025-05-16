import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdicionarBebidaScreen extends StatefulWidget {
  const AdicionarBebidaScreen({Key? key}) : super(key: key);

  @override
  _AdicionarBebidaScreenState createState() => _AdicionarBebidaScreenState();
}

class _AdicionarBebidaScreenState extends State<AdicionarBebidaScreen> {
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

  // Função para adicionar bebida
  void _adicionarBebida() {
    final nome = _nomeController.text;
    final descricao = _descricaoController.text;
    final preco = _precoController.text;
    final estoque = _estoqueController.text;
    final volume = _volumeController.text;

    if (nome.isEmpty ||
        descricao.isEmpty ||
        preco.isEmpty ||
        estoque.isEmpty ||
        _categoriaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    Map bebida = {
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'estoque': int.tryParse(estoque) ?? 0,
      'volume': volume,
      'categoria': _categoriaSelecionada,
    };

    // Adicionar bebida ao Firebase
    _adicionarBebidaFirebase(bebida)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bebida adicionada com sucesso!')),
          );
          Navigator.pop(context); // Voltar para a tela anterior
        })
        .catchError((e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao adicionar bebida: $e')),
          );
        });
  }

  // Função para adicionar bebida ao Firebase
  Future<void> _adicionarBebidaFirebase(Map bebida) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas.json',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bebida),
      );
      if (response.statusCode != 200) {
        throw Exception('Falha ao adicionar bebida');
      }
    } catch (e) {
      throw Exception('Erro ao adicionar bebida: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Bebida'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome da Bebida'),
            ),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
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
            TextField(
              controller: _volumeController,
              decoration: const InputDecoration(labelText: 'Volume'),
            ),
            DropdownButton<String>(
              value: _categoriaSelecionada,
              hint: const Text('Escolha a categoria'),
              items:
                  categorias.map((categoria) {
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
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _adicionarBebida,
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
