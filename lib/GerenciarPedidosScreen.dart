import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Importação essencial para notificações locais

class GerenciarPedidosScreen extends StatefulWidget {
  const GerenciarPedidosScreen({super.key});

  @override
  State<GerenciarPedidosScreen> createState() => _GerenciarPedidosScreenState();
}

class _GerenciarPedidosScreenState extends State<GerenciarPedidosScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin(); // Instância do plugin de notificações locais

  List<Map<String, dynamic>> pedidos = [];
  List<Map<String, dynamic>> motoristas = [];
  List<Map<String, dynamic>> _filteredPedidos =
      []; // Lista filtrada para exibição
  bool _isLoading = true;
  final TextEditingController _searchController =
      TextEditingController(); // Controlador para o campo de busca
  String _searchQuery = '';

  final String pedidosUrl =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/pedidos.json';
  final String funcionariosUrl =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/funcionarios.json';

  @override
  void initState() {
    // metodos inicializados ao abrir a pagina
    super.initState();
    _carregarDados();
    _initializeLocalNotifications();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Método chamado quando o texto do campo de busca muda
  void _onSearchChanged() {
    setState(() {
      _searchQuery =
          _searchController.text
              .toLowerCase(); // Armazena o termo em minúsculas
      _filterPedidos();
    });
  }

  // Função para filtrar os pedidos com base no termo de busca
  void _filterPedidos() {
    if (_searchQuery.isEmpty) {
      _filteredPedidos = List.from(
        pedidos,
      ); // Se a busca estiver vazia, mostra todos os pedidos
    } else {
      _filteredPedidos =
          pedidos.where((pedido) {
            final nomeCliente =
                '${pedido['nome'] ?? ''} ${pedido['sobrenome'] ?? ''}'
                    .toLowerCase();
            final idPedido =
                (pedido['idPedido'] ?? pedido['id'] ?? '')
                    .toString()
                    .toLowerCase();

            return nomeCliente.contains(_searchQuery) ||
                idPedido.contains(_searchQuery);
          }).toList();
    }
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      await Future.wait([_carregarPedidos(), _carregarMotoristas()]);
      _filterPedidos(); // Filtra os pedidos após carregá-los
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _carregarPedidos() async {
    final response = await http.get(Uri.parse(pedidosUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>?;
      pedidos = [];

      if (data != null) {
        pedidos =
            data.entries.map<Map<String, dynamic>>((entry) {
              final pedido = Map<String, dynamic>.from(entry.value);
              pedido['id'] = entry.key;
              return pedido;
            }).toList();
      }
    }
  }

  Future<void> _carregarMotoristas() async {
    final response = await http.get(Uri.parse(funcionariosUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>?;
      motoristas = [];

      if (data != null) {
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
  }

  // Inicializa as configurações do plugin de notificações
  void _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        print('Notificação local do Admin clicada: ${response.payload}');
      },
    );
  }

  // Função para mostrar a notificação local para o administrador
  Future<void> _showAdminNotification(
    String title,
    String body,
    String? payload,
  ) async {
    const AndroidNotificationDetails
    androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'admin_channel_id',
      'Gerenciamento de Pedidos', // Nome do canal visível ao usuário (admin)
      channelDescription:
          'Notificações sobre atualizações de status de pedidos.', // Descrição
      importance:
          Importance.max, // Importância alta para que apareça como heads-up
      priority: Priority.high, // Alta prioridade
      ticker: 'Pedido Atualizado',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      1, // ID único para esta notificação (pode ser qualquer int, diferente de 0 se 0 já for usado para outro propósito)
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
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

    String? motoristaSelecionado =
        motoristas.any((m) => m['id'] == pedido['motoristaId'])
            ? pedido['motoristaId']
            : null;

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
                      setState(() => motoristaSelecionado = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Crie um mapa com os dados a serem atualizados
                    final Map<String, dynamic> dadosParaAtualizar = {
                      'status': status,
                      'motoristaId': motoristaSelecionado,
                    };
                    // Obtenha o status ANTERIOR para usar na notificação, se desejar comparar
                    final String oldStatus = pedido['status'] ?? 'Desconhecido';

                    await _atualizarPedido(
                      pedido['id'],
                      dadosParaAtualizar,
                      oldStatus,
                      status,
                    ); // Passa o novo status
                    if (mounted) {
                      Navigator.pop(context);
                    }
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

  Future<void> _atualizarPedido(
    String id,
    Map<String, dynamic> dados,
    String oldStatus,
    String newStatus,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse(
          'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/pedidos/$id.json',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dados),
      );
      if (response.statusCode == 200) {
        // Recarrega os dados para atualizar a lista no UI
        await _carregarDados();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Pedido atualizado!')));

          _showAdminNotification(
            'Pedido #${id.substring(0, 5)}... Atualizado!',
            'Status mudou de "$oldStatus" para "$newStatus".',
            'pedido_atualizado_admin_$id',
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar pedido: ${response.statusCode}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar pedido: $e')));
      }
    }
  }

  String _nomeMotorista(String? idMotorista) {
    if (idMotorista == null) return '-';
    final motorista = motoristas.firstWhere(
      (m) => m['id'] == idMotorista,
      orElse: () => {'nome': '-'},
    );
    return motorista['nome'] ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Pedidos'), // Título fixo na AppBar
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por Nome do Cliente ou ID do Pedido',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged();
                          },
                        )
                        : null,
              ),
              onChanged: (query) {
                _onSearchChanged();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredPedidos.isEmpty
                      ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'Nenhum pedido encontrado.'
                              : 'Nenhum pedido encontrado para "$_searchQuery".',
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.all(0),
                        itemCount: _filteredPedidos.length,
                        itemBuilder: (context, index) {
                          final pedido = _filteredPedidos[index];
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
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
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
                                  Text(
                                    'Telefone: ${pedido['telefone'] ?? '-'}',
                                  ),
                                  Text(
                                    'Pagamento: ${pedido['modoPagamento'] ?? '-'}',
                                  ),
                                  if (pedido['observacoes'] != null &&
                                      pedido['observacoes']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      'Observações: ${pedido['observacoes']}',
                                    ),
                                  if (pedido['precoTotal'] != null)
                                    Text(
                                      'Total: R\$ ${pedido['precoTotal'].toStringAsFixed(2)}',
                                    ),
                                  if (pedido['itens'] != null &&
                                      pedido['itens'] is List)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Itens:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        ...List<Widget>.from(
                                          (pedido['itens'] as List).map((item) {
                                            final nome =
                                                item['nome'] ?? 'Produto';
                                            final qtd = item['quantidade'] ?? 1;
                                            return Text('- $nome (x$qtd)');
                                          }),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _editarPedidoDialog(pedido),
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
