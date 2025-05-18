import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Para converter a resposta da API em JSON
import 'package:app_de_bebidas/Pedido.dart';
import 'package:app_de_bebidas/LoginScreen.dart'; // Importa a tela de login

class PrincipalClienteScreen extends StatefulWidget {
  const PrincipalClienteScreen({Key? key}) : super(key: key);

  @override
  _PrincipalClienteScreenState createState() => _PrincipalClienteScreenState();
}

class _PrincipalClienteScreenState extends State<PrincipalClienteScreen> {
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
  ]; // Categorias disponíveis

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

        // Verifique se a resposta tem um formato Map
        if (data is Map) {
          return data.entries.map((entry) {
            final bebida = entry.value;

            // Certifique-se de que o tipo é um Map e contenha os dados esperados
            if (bebida is Map) {
              return Map<String, dynamic>.from(bebida)..['id'] = entry.key;
            } else {
              return {};
            }
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

    // Salvar carrinho como uma lista de strings
    List<String> carrinhoStr = carrinho.map((e) => json.encode(e)).toList();
    prefs.setStringList('carrinho', carrinhoStr);

    prefs.setString('pedidoStatus', pedidoStatus);
  }

  void _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar carrinho e decodificar JSON para Map
    List<String>? carrinhoStr = prefs.getStringList('carrinho');
    if (carrinhoStr != null) {
      setState(() {
        carrinho =
            carrinhoStr
                .map((e) => json.decode(e) as Map<String, dynamic>)
                .toList();
      });
    }

    // Carregar status do pedido
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
    prefs.clear(); // Limpa todos os dados armazenados no SharedPreferences

    setState(() {
      carrinho = []; // Limpa o carrinho
      pedidoStatus = 'Aguardando'; // Reseta o status do pedido
    });

    // Redireciona para a tela de login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Função para adicionar uma bebida ao carrinho
  void _adicionarAoCarrinho(Map bebida) {
    setState(() {
      carrinho.add(bebida);
    });
    _salvarDados();
  }

  // Função para remover uma bebida do carrinho
  void _removerDoCarrinho(Map bebida) {
    setState(() {
      carrinho.remove(bebida);
    });
    _salvarDados();
    _mostrarMensagemDeRemocao(bebida);
  }

  // Função para mostrar um aviso após remover a bebida do carrinho
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

  // Função para filtrar as bebidas pelo nome
  void _filtrarBebidas(String query) {
    setState(() {
      searchQuery = query;
      bebidasFiltradas =
          bebidas.where((bebida) {
            return bebida['nome'].toLowerCase().contains(query.toLowerCase());
          }).toList();
    });
  }

  // Função para filtrar bebidas por categoria
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
    _carregarDados(); // Carrega os dados quando a tela for iniciada
    _carregarBebidas();
  }

  @override
  void dispose() {
    // Salva os dados ao fechar o app
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
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (String? newValue) {
                _filtrarPorCategoria(newValue!);
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
                          String imagem = bebida['imagem'] ?? '';

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
                                  imagem.isNotEmpty
                                      ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imagem,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
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
          borderRadius: BorderRadius.only(
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

  // Função para mostrar o carrinho
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
                    // Usando StatefulBuilder para garantir a atualização da UI
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
                          // Exibindo os itens do carrinho
                          ...List.generate(carrinho.length, (index) {
                            var bebida = carrinho[index];
                            String nome =
                                bebida['nome'] ?? 'Nome não disponível';
                            String preco = bebida['preco'] ?? '0.00';
                            int quantidade =
                                bebida['quantidade'] ?? 1; // Quantidade do item
                            double precoUnitario =
                                double.tryParse(preco) ?? 0.0;
                            double precoTotalItem =
                                precoUnitario *
                                quantidade; // Preço total do item

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
                                  setState(
                                    () {},
                                  ); // Atualiza o carrinho imediatamente após a remoção
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

  // Função para atualizar a quantidade de um item no carrinho
  void _atualizarQuantidade(Map bebida, int novaQuantidade, Function setState) {
    if (novaQuantidade > 0) {
      setState(() {
        bebida['quantidade'] = novaQuantidade;
      });
      _salvarDados();
    }
  }

  // Função para finalizar a compra
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
                        String numero = pedido['numero'] ?? '—';
                        String nome = pedido['nome'] ?? 'Nome não disponível';
                        String data = pedido['data'] ?? 'Data não disponível';
                        String status =
                            pedido['status'] ?? 'Status não disponível';
                        double valor = pedido['valor'] ?? 0.0;

                        // Exibe os itens do pedido
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
                            Text('Data: $data'),
                            Column(children: itensWidgets),
                            Text(
                              'Valor Total: R\$ ${valor.toStringAsFixed(2)}',
                            ),
                            Text('Status: $status'),
                            Divider(),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar pedidos: $e')));
    }
  }

  // Função para buscar todos os pedidos no Firebase Realtime Database
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
        'numero': chave,
        'nome': valor['nome'] ?? 'Nome não disponível',
        'data': valor['data'] ?? 'Data não disponível',
        'itens': valor['itens'] ?? [],
        'valor': valor['valor'] ?? 0.0,
        'status': valor['status'] ?? 'Status não disponível',
      });
    });
    return lista;
  }

  // Função para mostrar uma mensagem quando não houver pedidos
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
