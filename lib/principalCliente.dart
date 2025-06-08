import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app_de_bebidas/Pedido.dart';
import 'package:app_de_bebidas/LoginScreen.dart';

class PrincipalClienteScreen extends StatefulWidget {
  const PrincipalClienteScreen({Key? key}) : super(key: key);

  @override
  _PrincipalClienteScreenState createState() => _PrincipalClienteScreenState();
}

class _PrincipalClienteScreenState extends State<PrincipalClienteScreen> {
  // A instância do plugin de notificações locais foi removida.
  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  //     FlutterLocalNotificationsPlugin();

  List<Map> bebidas = [];
  List<Map> bebidasFiltradas = [];
  List<Map> carrinho = [];
  String pedidoStatus = 'Aguardando';
  bool _isLoading = true;
  String searchQuery = '';
  String selectedCategory = 'Todas';
  List<String> categorias = [
    'Todas',
    'Cerveja',
    'Whisky',
    'Vodka',
    'Refrigerante',
    'Energético',
    'Itens Variados',
  ];

  final String apiUrl =
      'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas.json';

  // Função para carregar as bebidas do Firebase
  void _carregarBebidas() async {
    try {
      List<Map> bebidasList = await _getBebidas();
      setState(() {
        bebidas = bebidasList;
        bebidasFiltradas = bebidas;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar bebidas: $e')));
      }
    }
  }

  Future<List<Map>> _getBebidas() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is Map) {
          return data.entries.map((entry) {
            final bebida = Map<String, dynamic>.from(entry.value);
            bebida['id'] = entry.key; // Adiciona o ID do Firebase à bebida
            return bebida;
          }).toList();
        } else {
          throw Exception('Formato de dados inesperado');
        }
      } else {
        throw Exception('Falha ao carregar as bebidas');
      }
    } catch (e) {
      throw Exception('Erro ao buscar as bebidas: $e');
    }
  }

  // Função para salvar os dados no SharedPreferences
  void _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> carrinhoStr = carrinho.map((e) => json.encode(e)).toList();
    prefs.setStringList('carrinho', carrinhoStr);
    prefs.setString('pedidoStatus', pedidoStatus);
  }

  void _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? carrinhoStr = prefs.getStringList('carrinho');
    if (carrinhoStr != null) {
      setState(() {
        carrinho =
            carrinhoStr
                .map((e) => json.decode(e) as Map<String, dynamic>)
                .toList();
      });
    }
    String? status = prefs.getString('pedidoStatus');
    if (status != null) {
      setState(() {
        pedidoStatus = status;
      });
    }
  }

  void _logout() async {
    _salvarDados();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    setState(() {
      carrinho = [];
      pedidoStatus = 'Aguardando';
    });
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _adicionarAoCarrinho(Map bebida) {
    setState(() {
      carrinho.add(bebida);
    });
    _salvarDados();
  }

  void _removerDoCarrinho(Map bebida) {
    setState(() {
      carrinho.remove(bebida);
    });
    _salvarDados();
    _mostrarMensagemDeRemocao(bebida);
  }

  void _mostrarMensagemDeRemocao(Map bebida) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Remoção"),
          content: Text("${bebida['nome']} foi removida do carrinho."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _filtrarBebidas(String query) {
    setState(() {
      searchQuery = query;
      bebidasFiltradas =
          bebidas.where((bebida) {
            return bebida['nome'].toLowerCase().contains(query.toLowerCase());
          }).toList();
    });
  }

  void _filtrarPorCategoria(String categoria) {
    setState(() {
      selectedCategory = categoria;
      if (categoria == 'Todas') {
        bebidasFiltradas = bebidas;
      } else {
        bebidasFiltradas =
            bebidas.where((bebida) {
              return bebida['categoria'] == categoria;
            }).toList();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
    _carregarBebidas();
  }

  @override
  void dispose() {
    _salvarDados();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bebidas - Cliente'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de pesquisa
            TextField(
              onChanged: (query) {
                _filtrarBebidas(query);
              },
              decoration: const InputDecoration(
                labelText: 'Pesquisar Bebida',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // Escolhedor de categoria
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Filtrar por Categoria',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              value: selectedCategory,
              isExpanded: true,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _filtrarPorCategoria(newValue);
                }
              },
              items:
                  categorias.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            // Exibindo a lista de bebidas
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : bebidasFiltradas.isEmpty
                      ? const Center(child: Text('Nenhuma bebida encontrada.'))
                      : ListView.builder(
                        itemCount: bebidasFiltradas.length,
                        itemBuilder: (context, index) {
                          var bebida = bebidasFiltradas[index];
                          String nome = bebida['nome'] ?? 'Nome não disponível';
                          String preco = bebida['preco'] ?? '0.00';
                          String? imagemBase64 = bebida['imagemBase64'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
                              title: Text(nome),
                              subtitle: Text('Preço: R\$ $preco'),
                              leading:
                                  imagemBase64 != null &&
                                          imagemBase64.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.memory(
                                          base64Decode(imagemBase64),
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Icon(
                                              Icons.error_outline,
                                              size: 50,
                                            );
                                          },
                                        ),
                                      )
                                      : const Icon(Icons.image_not_supported),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_shopping_cart),
                                onPressed: () {
                                  _adicionarAoCarrinho(bebida);
                                },
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black26, spreadRadius: 0, blurRadius: 8),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.deepPurple,
          selectedItemColor: const Color.fromARGB(255, 5, 5, 5),
          unselectedItemColor: const Color.fromARGB(
            255,
            2,
            2,
            2,
          ).withOpacity(0.6),
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Carrinho',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Acompanhar Pedido',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.exit_to_app),
              label: 'Logout',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                setState(() {
                  _carregarBebidas();
                });
                break;
              case 1:
                _mostrarCarrinho();
                break;
              case 3:
                _logout();
                break;
              case 2:
                _pedidos();
                break;
            }
          },
        ),
      ),
    );
  }

  void _mostrarCarrinho() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double total = 0.0;

        return AlertDialog(
          title: const Text("Carrinho"),
          content:
              carrinho.isEmpty
                  ? const Text("O carrinho está vazio.")
                  : StatefulBuilder(
                    builder: (context, setState) {
                      total = 0.0;
                      carrinho.forEach((bebida) {
                        String preco = bebida['preco'] ?? '0.00';
                        int quantidade = bebida['quantidade'] ?? 1;
                        double precoUnitario = double.tryParse(preco) ?? 0.0;
                        total += precoUnitario * quantidade;
                      });

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(carrinho.length, (index) {
                            var bebida = carrinho[index];
                            String nome =
                                bebida['nome'] ?? 'Nome não disponível';
                            String preco = bebida['preco'] ?? '0.00';
                            int quantidade = bebida['quantidade'] ?? 1;
                            double precoUnitario =
                                double.tryParse(preco) ?? 0.0;

                            return ListTile(
                              title: Text(
                                '$nome - R\$ ${precoUnitario.toStringAsFixed(2)}',
                              ),
                              subtitle: Row(
                                children: [
                                  Text('Qtd: $quantidade'),
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: () {
                                      _atualizarQuantidade(
                                        bebida,
                                        quantidade - 1,
                                        setState,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      _atualizarQuantidade(
                                        bebida,
                                        quantidade + 1,
                                        setState,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_shopping_cart),
                                onPressed: () {
                                  _removerDoCarrinho(bebida);
                                  setState(() {});
                                },
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          Text(
                            'Total: R\$ ${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Fechar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _finalizarCompra();
              },
              child: const Text("Finalizar Compra"),
            ),
          ],
        );
      },
    );
  }

  void _atualizarQuantidade(Map bebida, int novaQuantidade, Function setState) {
    if (novaQuantidade > 0) {
      setState(() {
        bebida['quantidade'] = novaQuantidade;
      });
      _salvarDados();
    }
  }

  void _finalizarCompra() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => PedidoScreen(carrinho: carrinho)),
    );
  }

  void _pedidos() async {
    try {
      final pedidos = await _carregarPedidos();

      if (pedidos.isEmpty) {
        _mostrarMensagem('Não há pedidos cadastrados.');
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Meus Pedidos"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      pedidos.map((pedido) {
                        String numero = pedido['idPedido'] ?? '—';
                        String nome = pedido['nome'] ?? 'Nome não disponível';

                        String status =
                            pedido['status'] ?? 'Status não disponível';
                        double valor = pedido['valor'] ?? 0.0;

                        List<Widget> itensWidgets = [];
                        List<dynamic> itens = pedido['itens'] ?? [];
                        for (var item in itens) {
                          itensWidgets.add(
                            Text(
                              '${item['nome']} x${item['quantidade']} - R\$ ${item['preco']}',
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pedido #$numero'),
                            Text('Nome: $nome'),
                            Column(children: itensWidgets),
                            Text(
                              'Valor Total: R\$ ${valor.toStringAsFixed(2)}',
                            ),
                            Text('Status: $status'),
                            const Divider(),
                          ],
                        );
                      }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Fechar"),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar pedidos: $e')));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _carregarPedidos() async {
    final url =
        'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/pedidos.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao carregar pedidos (status ${response.statusCode})',
      );
    }

    final data = json.decode(response.body);
    if (data == null) return [];

    List<Map<String, dynamic>> lista = [];
    data.forEach((chave, valor) {
      lista.add({
        'idPedido': valor['idPedido'] ?? chave,
        'nome': valor['nome'] ?? 'Nome não disponível',
        'itens': valor['itens'] ?? [],
        'valor': valor['precoTotal'] ?? 0.0,
        'status': valor['status'] ?? 'Status não disponível',
      });
    });
    return lista;
  }

  void _mostrarMensagem(String mensagem) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Aviso"),
            content: Text(mensagem),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }
}
