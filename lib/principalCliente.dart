import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrincipalClienteScreen extends StatefulWidget {
  const PrincipalClienteScreen({Key? key}) : super(key: key);

  @override
  _PrincipalClienteScreenState createState() => _PrincipalClienteScreenState();
}

class _PrincipalClienteScreenState extends State<PrincipalClienteScreen> {
  final dbRef = FirebaseDatabase.instance.ref('bebidas');
  List<Map> bebidas = [];
  List<Map> carrinho = [];
  List<Map> favoritos = [];
  String pedidoStatus = 'Aguardando'; // Exemplo de status do pedido

  // Função para obter as bebidas do banco de dados
  void _getBebidas() async {
    final snapshot = await dbRef.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        bebidas = data.values.map((e) => Map.from(e)).toList();
      });
    } else {
      setState(() {
        bebidas = []; // Caso não haja dados no banco
      });
    }
  }

  // Função para salvar os dados no SharedPreferences
  void _salvarDados() async {
    final prefs = await SharedPreferences.getInstance();

    // Salvar carrinho como uma lista de strings
    List<String> carrinhoStr = carrinho.map((e) => e.toString()).toList();
    prefs.setStringList('carrinho', carrinhoStr);

    // Salvar favoritos como uma lista de strings
    List<String> favoritosStr = favoritos.map((e) => e.toString()).toList();
    prefs.setStringList('favoritos', favoritosStr);

    // Salvar o status do pedido
    prefs.setString('pedidoStatus', pedidoStatus);
  }

  // Função para carregar os dados do SharedPreferences
  void _carregarDados() async {
    final prefs = await SharedPreferences.getInstance();

    // Carregar carrinho
    List<String>? carrinhoStr = prefs.getStringList('carrinho');
    if (carrinhoStr != null) {
      setState(() {
        carrinho = carrinhoStr.map((e) => Map.from(e as Map)).toList();
      });
    }

    // Carregar favoritos
    List<String>? favoritosStr = prefs.getStringList('favoritos');
    if (favoritosStr != null) {
      setState(() {
        favoritos = favoritosStr.map((e) => Map.from(e as Map)).toList();
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

  // Função para limpar os dados no SharedPreferences (simula o logout)
  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear(); // Limpa todos os dados armazenados no SharedPreferences
    setState(() {
      carrinho = [];
      favoritos = [];
      pedidoStatus = 'Aguardando'; // Reseta o status do pedido
    });
  }

  // Função para remover uma bebida do carrinho
  void _removerDoCarrinho(Map bebida) {
    setState(() {
      carrinho.remove(bebida);
    });
    _salvarDados(); // Salva as alterações
    _mostrarMensagemDeRemocao(bebida); // Mostrar o aviso
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
                Navigator.of(context).pop(); // Fecha o aviso
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _carregarDados(); // Carrega os dados quando a tela for iniciada
    _getBebidas(); // Obtém as bebidas do banco de dados
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bebidas - Cliente')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Exibindo a lista de bebidas
            Expanded(
              child:
                  bebidas.isEmpty
                      ? const Center(child: Text('Nenhuma bebida disponível.'))
                      : ListView.builder(
                        itemCount: bebidas.length,
                        itemBuilder: (context, index) {
                          var bebida = bebidas[index];
                          String nome = bebida['nome'] ?? 'Nome não disponível';
                          String preco = bebida['preco'] ?? '0.00';
                          String imagem = bebida['imagem'] ?? '';

                          bool isFavorito = favoritos.contains(bebida);

                          return ListTile(
                            title: Text(nome),
                            subtitle: Text('Preço: R\$ $preco'),
                            leading:
                                imagem.isNotEmpty
                                    ? Image.network(imagem)
                                    : const Icon(Icons.image_not_supported),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Ícone de favoritar
                                IconButton(
                                  icon: Icon(
                                    isFavorito
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorito ? Colors.red : null,
                                  ),
                                  onPressed: () {
                                    _adicionarRemoverFavoritos(bebida);
                                  },
                                ),
                                // Ícone de remover do carrinho
                                IconButton(
                                  icon: const Icon(Icons.remove_shopping_cart),
                                  onPressed: () {
                                    _removerDoCarrinho(bebida);
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              // Adiciona a bebida ao carrinho
                              _adicionarAoCarrinho(bebida);
                            },
                          );
                        },
                      ),
            ),
            // Barra de navegação inferior
            BottomNavigationBar(
              backgroundColor: const Color.fromARGB(255, 6, 8, 10),
              selectedItemColor: const Color.fromARGB(255, 221, 37, 37),
              unselectedItemColor: const Color.fromARGB(153, 37, 179, 68),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.check_circle),
                  label: 'Acompanhar Pedido',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Favoritos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Carrinho',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.exit_to_app),
                  label: 'Logout',
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Voltar à tela inicial
                    setState(() {
                      _getBebidas();
                    });
                    break;
                  case 1:
                    // Ir para a tela de Acompanhar Pedido
                    _mostrarAcompanharPedido();
                    break;
                  case 2:
                    // Mostrar os favoritos
                    _mostrarFavoritos();
                    break;
                  case 3:
                    // Mostrar o carrinho
                    _mostrarCarrinho();
                    break;
                  case 4:
                    // Logout
                    _logout();
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Função para exibir o status do pedido
  void _mostrarAcompanharPedido() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Acompanhar Pedido"),
          content: Text("Status do pedido: $pedidoStatus"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o status do pedido
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  // Função para adicionar bebida ao carrinho
  void _adicionarAoCarrinho(Map bebida) {
    setState(() {
      carrinho.add(bebida);
    });
    _mostrarMensagemDeAviso(bebida); // Mostrar o aviso
    _salvarDados(); // Salva os dados
  }

  // Função para adicionar/remover bebida dos favoritos
  void _adicionarRemoverFavoritos(Map bebida) {
    setState(() {
      if (favoritos.contains(bebida)) {
        favoritos.remove(bebida); // Remove se já estiver nos favoritos
        _mostrarMensagemDeAvisoFavorito(bebida, "removido");
      } else {
        favoritos.add(bebida); // Adiciona aos favoritos
        _mostrarMensagemDeAvisoFavorito(bebida, "adicionado");
      }
    });
    _salvarDados(); // Salva os dados
  }

  // Função para mostrar um aviso após adicionar ou remover dos favoritos
  void _mostrarMensagemDeAvisoFavorito(Map bebida, String acao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Favoritos"),
          content: Text("${bebida['nome']} foi $acao aos favoritos."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o aviso
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Função para mostrar um aviso após adicionar a bebida ao carrinho
  void _mostrarMensagemDeAviso(Map bebida) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bebida Adicionada"),
          content: Text("${bebida['nome']} foi adicionada ao carrinho."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o aviso
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Função para mostrar os favoritos na tela
  void _mostrarFavoritos() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Favoritos"),
          content:
              favoritos.isEmpty
                  ? const Text("Não há bebidas nos favoritos.")
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(favoritos.length, (index) {
                      var bebida = favoritos[index];
                      String nome = bebida['nome'] ?? 'Nome não disponível';
                      String preco = bebida['preco'] ?? '0.00';
                      return ListTile(
                        title: Text('$nome - R\$ $preco'),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          onPressed: () {
                            _moverParaCarrinho(bebida);
                          },
                        ),
                      );
                    }),
                  ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha os favoritos
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  // Função para mover favorito para o carrinho
  void _moverParaCarrinho(Map bebida) {
    setState(() {
      carrinho.add(bebida);
      favoritos.remove(bebida);
    });
    _mostrarMensagemDeMovimento(bebida, "adicionada ao carrinho");
    _salvarDados(); // Salva os dados
  }

  // Função para mostrar um aviso após mover a bebida para o carrinho
  void _mostrarMensagemDeMovimento(Map bebida, String acao) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Movido"),
          content: Text("${bebida['nome']} foi $acao."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o aviso
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Função para mostrar o carrinho na tela
  void _mostrarCarrinho() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Carrinho"),
          content:
              carrinho.isEmpty
                  ? const Text("O carrinho está vazio.")
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(carrinho.length, (index) {
                      var bebida = carrinho[index];
                      String nome = bebida['nome'] ?? 'Nome não disponível';
                      String preco = bebida['preco'] ?? '0.00';
                      return ListTile(
                        title: Text('$nome - R\$ $preco'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_shopping_cart),
                          onPressed: () {
                            _removerDoCarrinho(bebida);
                          },
                        ),
                      );
                    }),
                  ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o carrinho
              },
              child: const Text("Fechar"),
            ),
            TextButton(
              onPressed: () {
                // Finalizar a compra
                // Adicionar a lógica de pagamento ou finalização aqui
                Navigator.of(context).pop(); // Fecha o carrinho
                _finalizarCompra(); // Exibe a confirmação de compra
              },
              child: const Text("Finalizar Compra"),
            ),
          ],
        );
      },
    );
  }

  // Função para finalizar a compra
  void _finalizarCompra() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Compra Finalizada"),
          content: const Text("Sua compra foi finalizada com sucesso!"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha a confirmação
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
