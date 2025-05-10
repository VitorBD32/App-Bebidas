import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PrincipalClienteScreen extends StatefulWidget {
  const PrincipalClienteScreen({Key? key}) : super(key: key);

  @override
  _PrincipalClienteScreenState createState() => _PrincipalClienteScreenState();
}

class _PrincipalClienteScreenState extends State<PrincipalClienteScreen> {
  final dbRef = FirebaseDatabase.instance.ref('bebidas');
  List<Map> bebidas = [];

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

  @override
  void initState() {
    super.initState();
    _getBebidas(); // Obtém as bebidas ao iniciar a tela
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
                          // Verificação de null para cada campo
                          String nome = bebida['nome'] ?? 'Nome não disponível';
                          String preco = bebida['preco'] ?? '0.00';
                          String imagem = bebida['imagem'] ?? '';

                          return ListTile(
                            title: Text(nome),
                            subtitle: Text('Preço: R\$ $preco'),
                            leading:
                                imagem.isNotEmpty
                                    ? Image.network(imagem)
                                    : const Icon(Icons.image_not_supported),
                            onTap: () {
                              // Implementar ação ao clicar na bebida (ex. adicionar ao carrinho)
                            },
                          );
                        },
                      ),
            ),
            // Barra de navegação inferior
            BottomNavigationBar(
              backgroundColor: const Color.fromARGB(
                255,
                6,
                8,
                10,
              ), // Cor de fundo da barra
              selectedItemColor: const Color.fromARGB(
                255,
                221,
                37,
                37,
              ), // Cor para o ícone selecionado
              unselectedItemColor: const Color.fromARGB(
                153,
                37,
                179,
                68,
              ), // Cor para ícones não selecionados
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_cart),
                  label: 'Carrinho',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Favoritos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Configurações',
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    // Voltar à tela inicial
                    setState(() {
                      // Recarregar a tela de bebidas
                      _getBebidas();
                    });
                    break;
                  case 1:
                    // Ir para a tela de Carrinho
                    // Adicione o código para navegação do carrinho
                    break;
                  case 2:
                    // Ir para a tela de Favoritos
                    // Adicione o código para navegação de favoritos
                    break;
                  case 3:
                    // Ir para a tela de Configurações
                    // Adicione o código para navegação de configurações
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
