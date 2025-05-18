import 'package:flutter/material.dart';

class TelaConfirmacaoCompra extends StatelessWidget {
  final double total;
  final List<Map> carrinho;

  const TelaConfirmacaoCompra({
    Key? key,
    required this.total,
    required this.carrinho,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirmação da Compra")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Resumo da Compra",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            carrinho.isEmpty
                ? const Text("Nenhum item no carrinho.")
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(carrinho.length, (index) {
                    var bebida = carrinho[index];
                    String nome = bebida['nome'] ?? 'Nome não disponível';
                    String preco = bebida['preco'] ?? '0.00';
                    return Text('$nome - R\$ $preco');
                  }),
                ),
            const SizedBox(height: 20),
            Text(
              'Total: R\$ ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _mostrarCompraFinalizada(context);
              },
              child: const Text("Finalizar Compra"),
            ),
          ],
        ),
      ),
    );
  }

  // Função para mostrar a confirmação de finalização
  void _mostrarCompraFinalizada(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Compra Finalizada"),
          content: const Text("Sua compra foi finalizada com sucesso!"),
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
}
