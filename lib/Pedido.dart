import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class PedidoScreen extends StatefulWidget {
  final List<Map> carrinho;

  const PedidoScreen({Key? key, required this.carrinho}) : super(key: key);

  @override
  _PedidoScreenState createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  final _nomeController = TextEditingController();
  final _sobrenomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _ruaController = TextEditingController();
  final _numeroController = TextEditingController();

  final _observacoesController =
      TextEditingController(); // Campo de Observações
  String? _rua = '';
  double _precoTotal = 0.0;
  String? _modoPagamentoSelecionado = 'Cartão de Crédito';

  // Lista de tipos de pagamento
  final List<String> modosPagamento = [
    'Cartão de Crédito',
    'Cartão de Débito',
    'Pix',
    'Dinheiro',
  ];

  // Função para calcular o total do pedido baseado no carrinho
  void _calcularPrecoTotal() {
    double total = 0.0;
    for (var item in widget.carrinho) {
      // Garante que o 'preco' seja um double antes de usar
      double preco = double.tryParse(item['preco'].toString()) ?? 0.0;
      int quantidade = item['quantidade'] ?? 1;
      total += preco * quantidade;
    }
    setState(() {
      _precoTotal = total;
    });
  }

  @override
  void initState() {
    super.initState();
    _calcularPrecoTotal();
  }

  // Função para adicionar pedido ao Firebase
  void _adicionarPedido() {
    final String idPedido = 'pedido_${DateTime.now().millisecondsSinceEpoch}';
    final nome = _nomeController.text;
    final sobrenome = _sobrenomeController.text;
    final telefone = _telefoneController.text;
    final cep = _cepController.text;
    final rua = _ruaController.text;
    final numero = _numeroController.text;
    final modoPagamento = _modoPagamentoSelecionado;
    final observacoes = _observacoesController.text;

    if (nome.isEmpty ||
        sobrenome.isEmpty ||
        telefone.isEmpty ||
        cep.isEmpty ||
        rua.isEmpty ||
        numero.isEmpty ||
        modoPagamento == null ||
        widget.carrinho.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    // Preparando o pedido
    Map pedido = {
      'idPedido': idPedido,
      'nome': nome,
      'sobrenome': sobrenome,
      'telefone': telefone,
      'cep': cep,
      'rua': rua,
      'numero': numero,
      'modoPagamento': modoPagamento,
      'precoTotal': _precoTotal,
      'status': 'Em preparação',
      'dataCriacao': DateTime.now().toIso8601String(),
      'itens':
          widget.carrinho.map((item) {
            return {
              'nome': item['nome'],
              'quantidade': item['quantidade'],
              'preco':
                  item['preco'], // Garante que o preço do item seja o valor original
            };
          }).toList(),
      'observacoes': observacoes.isEmpty ? 'Nenhuma observação' : observacoes,
    };

    // Enviar o pedido para o Firebase
    _adicionarPedidoFirebase(pedido)
        .then((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pedido adicionado com sucesso!')),
            );
            Navigator.pop(context); // Voltar para a tela anterior
          }
        })
        .catchError((e) {
          if (mounted) {
            // Adicionado mounted check
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao adicionar pedido: $e')),
            );
          }
        });
  }

  // Função para adicionar pedido ao Firebase
  Future<void> _adicionarPedidoFirebase(Map pedido) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/pedidos.json',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(pedido),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao adicionar pedido. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao adicionar pedido: $e');
    }
  }

  // Função para buscar o nome da rua automaticamente com o CEP
  Future<void> _buscarRuaPorCep(String cep) async {
    // Validação básica do CEP antes de fazer a requisição
    if (cep.length != 8 || int.tryParse(cep) == null) {
      setState(() {
        _rua = '';
        _ruaController.text = '';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cep/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == true) {
          setState(() {
            _rua = '';
            _ruaController.text = '';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('CEP não encontrado.')),
            );
          }
        } else if (data['logradouro'] != null) {
          setState(() {
            _rua = data['logradouro'];
            _ruaController.text = _rua!;
          });
        } else {
          setState(() {
            _rua = '';
            _ruaController.text = '';
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rua não encontrada para este CEP.'),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao buscar o CEP: ${response.statusCode}'),
            ),
          );
        }
        throw Exception('Erro ao buscar o CEP');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de conexão ao buscar CEP: $e')),
        );
      }
      throw Exception('Erro de conexão ao buscar o CEP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Pedido'),
        backgroundColor: Colors.deepPurple,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  (kToolbarHeight +
                      MediaQuery.of(context).padding.top +
                      MediaQuery.of(context).padding.bottom),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _sobrenomeController,
                    decoration: const InputDecoration(labelText: 'Sobrenome'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _telefoneController,
                    decoration: const InputDecoration(labelText: 'Telefone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cepController,
                    decoration: InputDecoration(
                      labelText: 'CEP',
                      suffixIcon:
                          _cepController.text.length == 8
                              ? IconButton(
                                icon: const Icon(Icons.search),
                                onPressed:
                                    () => _buscarRuaPorCep(_cepController.text),
                              )
                              : null,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (cep) {
                      if (cep.length == 8) {
                        _buscarRuaPorCep(cep);
                      } else {
                        setState(() {
                          _rua = '';
                          _ruaController.text = '';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ruaController,
                    decoration: const InputDecoration(labelText: 'Rua'),
                    enabled: false,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _numeroController,
                    decoration: const InputDecoration(labelText: 'Número'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _modoPagamentoSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Modo de Pagamento',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _modoPagamentoSelecionado = newValue;
                      });
                    },
                    items:
                        modosPagamento.map((String modo) {
                          return DropdownMenuItem<String>(
                            value: modo,
                            child: Text(modo),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _observacoesController,
                    decoration: const InputDecoration(
                      labelText: 'Observações (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Resumo do Pedido:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200, // tabela
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 16.0,
                        horizontalMargin: 12.0,
                        headingRowHeight: 40.0,
                        dataRowMinHeight: 48.0,
                        dataRowMaxHeight: 56.0,
                        headingTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        dividerThickness: 1,
                        columns: const [
                          DataColumn(label: Text('Produto')),
                          DataColumn(label: Center(child: Text('Qtd'))),
                          DataColumn(
                            label: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Preço U.'),
                            ),
                          ),
                          DataColumn(
                            label: Align(
                              alignment: Alignment.centerRight,
                              child: Text('Subtotal'),
                            ),
                          ),
                        ],
                        rows:
                            widget.carrinho.map((item) {
                              final String nome =
                                  item['nome']?.toString() ??
                                  'Produto Indisponível';
                              final int quantidade =
                                  (item['quantidade'] is int)
                                      ? item['quantidade']
                                      : ((item['quantidade'] is String)
                                          ? (int.tryParse(item['quantidade']) ??
                                              1)
                                          : 1);

                              final String precoString =
                                  item['preco']?.toString() ?? '0.0';
                              final double precoUnitario =
                                  double.tryParse(precoString) ?? 0.0;
                              final double subtotalItem =
                                  precoUnitario * quantidade;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      nome,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Text(
                                        quantidade.toString(),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'R\$ ${precoUnitario.toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'R\$ ${subtotalItem.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Total: R\$ ${_precoTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton(
                    onPressed: _adicionarPedido,
                    child: const Text('Adicionar Pedido'),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
