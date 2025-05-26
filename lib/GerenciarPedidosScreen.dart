import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GerenciarPedidosScreen extends StatefulWidget {
  const GerenciarPedidosScreen({super.key});

  @override
  State<GerenciarPedidosScreen> createState() => _GerenciarPedidosScreenState();
}

class _GerenciarPedidosScreenState extends State<GerenciarPedidosScreen> {
  List<Map<String, dynamic>> pedidos = [];
  List<Map<String, dynamic>> motoristas = [];
  bool _isLoading = true;

  final String pedidosUrl =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/pedidos.json';
  final String funcionariosUrl =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/funcionarios.json';

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_carregarPedidos(), _carregarMotoristas()]);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarPedidos() async {
    final response = await http.get(Uri.parse(pedidosUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      pedidos =
          data.entries.map<Map<String, dynamic>>((entry) {
            final pedido = Map<String, dynamic>.from(entry.value);
            pedido['id'] = entry.key;
            return pedido;
          }).toList();
    }
  }

  Future<void> _carregarMotoristas() async {
    final response = await http.get(Uri.parse(funcionariosUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      motoristas =
          data.entries
              .map<Map<String, dynamic>>((entry) {
                final funcionario = Map<String, dynamic>.from(entry.value);
                funcionario['id'] = entry.key;
                return funcionario;
              })
              .where(
                (f) => f['funcao']?.toString().toLowerCase() == 'motorista',
              )
              .toList();
    }
  }

  void _editarPedidoDialog(Map<String, dynamic> pedido) {
    List<String> statusOptions = [
      'Em preparo',
      'Em rota de entrega',
      'Entregue',
    ];

    String status =
        statusOptions.contains(pedido['status'])
            ? pedido['status']
            : 'Em preparo';

    String? motoristaSelecionado = pedido['motoristaId'];

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Pedido'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items:
                        statusOptions
                            .map(
                              (s) => DropdownMenuItem<String>(
                                value: s,
                                child: Text(s),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => status = value);
                      }
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: motoristaSelecionado,
                    decoration: const InputDecoration(labelText: 'Motorista'),
                    items:
                        motoristas
                            .map(
                              (motorista) => DropdownMenuItem<String>(
                                value: motorista['id'],
                                child: Text(motorista['nome'] ?? 'Sem nome'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => motoristaSelecionado = value);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await _atualizarPedido(pedido['id'], {
                      'status': status,
                      'motoristaId': motoristaSelecionado,
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _atualizarPedido(String id, Map<String, dynamic> dados) async {
    try {
      final response = await http.patch(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/pedidos/$id.json',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 200) {
        await _carregarPedidos();
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Pedido atualizado!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao atualizar pedido: $e')));
    }
  }

  String _nomeMotorista(String? idMotorista) {
    final motorista = motoristas.firstWhere(
      (m) => m['id'] == idMotorista,
      orElse: () => {},
    );
    return motorista['nome'] ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Pedidos'),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : pedidos.isEmpty
              ? const Center(child: Text('Nenhum pedido encontrado.'))
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pedidos.length,
                itemBuilder: (context, index) {
                  final pedido = pedidos[index];
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        'Pedido de: ${pedido['nome'] ?? '-'} ${pedido['sobrenome'] ?? '-'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ID do Pedido: ${pedido['idPedido'] ?? pedido['id'] ?? '-'}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text('Status: ${pedido['status'] ?? '-'}'),
                          Text(
                            'Motorista: ${_nomeMotorista(pedido['motoristaId'])}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Endereço: ${pedido['rua'] ?? '-'}, Nº: ${pedido['numero'] ?? '-'}, CEP: ${pedido['cep'] ?? '-'}',
                          ),
                          Text('Telefone: ${pedido['telefone'] ?? '-'}'),
                          Text('Pagamento: ${pedido['modoPagamento'] ?? '-'}'),
                          if (pedido['observacoes'] != null &&
                              pedido['observacoes'].toString().isNotEmpty)
                            Text('Observações: ${pedido['observacoes']}'),
                          if (pedido['precoTotal'] != null)
                            Text(
                              'Total: R\$ ${(pedido['precoTotal'] / 100).toStringAsFixed(2)}',
                            ),
                          if (pedido['itens'] != null &&
                              pedido['itens'] is List)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                const Text(
                                  'Itens:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                ...List<Widget>.from(
                                  (pedido['itens'] as List).map((item) {
                                    final nome = item['nome'] ?? 'Produto';
                                    final qtd = item['quantidade'] ?? 1;
                                    return Text('- $nome (x$qtd)');
                                  }),
                                ),
                              ],
                            ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editarPedidoDialog(pedido),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
