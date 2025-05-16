import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_de_bebidas/Pedido.dart';
import 'package:app_de_bebidas/LoginScreen.dart'; // Importa a tela de login

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

    // Redireciona para a tela de login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
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
            // Exibindo a lista de bebidas
            Text(
              'Escolha suas bebidas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_shopping_cart,
                                    ),
                                    onPressed: () {
                                      _removerDoCarrinho(bebida);
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                _adicionarAoCarrinho(bebida);
                              },
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
                setState(() {
                  _getBebidas();
                });
                break;
              case 1:
                _mostrarAcompanharPedido();
                break;
              case 2:
                _mostrarFavoritos();
                break;
              case 3:
                _mostrarCarrinho();
                break;
              case 4:
                _logout(); // Chama a função de logout
                break;
            }
          },
        ),
      ),
    );
  }

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
                Navigator.of(context).pop();
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  void _adicionarAoCarrinho(Map bebida) {
    setState(() {
      carrinho.add(bebida);
    });
    _mostrarMensagemDeAviso(bebida);
    _salvarDados();
  }

  void _adicionarRemoverFavoritos(Map bebida) {
    setState(() {
      if (favoritos.contains(bebida)) {
        favoritos.remove(bebida);
        _mostrarMensagemDeAvisoFavorito(bebida, "removido");
      } else {
        favoritos.add(bebida);
        _mostrarMensagemDeAvisoFavorito(bebida, "adicionado");
      }
    });
    _salvarDados();
  }

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
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

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
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

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
                Navigator.of(context).pop();
              },
              child: const Text("Fechar"),
            ),
          ],
        );
      },
    );
  }

  void _moverParaCarrinho(Map bebida) {
    setState(() {
      carrinho.add(bebida);
      favoritos.remove(bebida);
    });
    _mostrarMensagemDeMovimento(bebida, "adicionada ao carrinho");
    _salvarDados();
  }

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
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

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
                Navigator.of(context).pop();
              },
              child: const Text("Fechar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o carrinho
                _finalizarCompra();
              },
              child: const Text("Finalizar Compra"),
            ),
          ],
        );
      },
    );
  }

  void _finalizarCompra() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PedidoScreen()));
  }
}
