import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class PedidoScreen extends StatefulWidget {
  const PedidoScreen({Key? key}) : super(key: key);

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
  final _modoPagamentoController = TextEditingController();
  late GoogleMapController mapController;

  late LatLng _endereco;
  bool _enderecoCarregado = false;
  bool _carregandoEndereco = false;
  String _rua = '';
  String _bairro = '';
  String _cidade = '';
  String _uf = '';

  // Debounce para evitar requisição a cada caractere digitado
  Timer? _debounce;

  // Função para buscar o endereço usando a API dos Correios
  void _buscarEndereco() async {
    setState(() {
      _carregandoEndereco = true;
    });
    String cep = _cepController.text.trim();

    // Verifica se o CEP tem 8 caracteres, caso contrário, não faz a requisição
    if (cep.length != 8 || !cep.contains('-')) {
      setState(() {
        _carregandoEndereco = false;
      });
      _mostrarErro("CEP inválido. O CEP deve ter 8 dígitos, incluindo o '-'.");
      return;
    }

    final response = await http.get(
      Uri.parse('https://viacep.com.br/ws/$cep/json/'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['erro'] == null) {
        setState(() {
          _rua = data['logradouro'];
          _bairro = data['bairro'];
          _cidade = data['localidade'];
          _uf = data['uf'];
          _ruaController.text = _rua;
          _enderecoCarregado = true;
          _carregandoEndereco = false;

          // Atualiza o mapa
          _buscarCoordenadas();
        });
      } else {
        setState(() {
          _enderecoCarregado = false;
          _carregandoEndereco = false;
        });
        _mostrarErro("CEP não encontrado");
      }
    } else {
      setState(() {
        _enderecoCarregado = false;
        _carregandoEndereco = false;
      });
      _mostrarErro("Erro ao buscar o CEP");
    }
  }

  // Função para buscar as coordenadas a partir do endereço
  void _buscarCoordenadas() async {
    List<Location> locations = await locationFromAddress(
      '$_rua, $_bairro, $_cidade, $_uf',
    ); // Monta o endereço completo
    if (locations.isNotEmpty) {
      setState(() {
        _endereco = LatLng(locations[0].latitude, locations[0].longitude);
      });
    } else {
      setState(() {
        _enderecoCarregado = false;
      });
    }
  }

  // Função para mostrar mensagens de erro
  void _mostrarErro(String mensagem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Erro"),
          content: Text(mensagem),
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

  // Função para configurar o mapa
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void dispose() {
    // Limpa o debounce quando a tela for descartada
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido - Finalizar Compra'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulário de entrada
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _sobrenomeController,
              decoration: InputDecoration(labelText: 'Sobrenome'),
            ),
            TextField(
              controller: _telefoneController,
              decoration: InputDecoration(labelText: 'Telefone'),
            ),
            TextField(
              controller: _cepController,
              decoration: InputDecoration(labelText: 'CEP'),
              onChanged: (value) {
                // Utilizando debounce para chamar a função de forma eficiente
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (value.length == 8) {
                    _buscarEndereco();
                  }
                });
              },
            ),
            TextField(
              controller: _ruaController,
              decoration: InputDecoration(labelText: 'Rua'),
              enabled: false, // Campo somente leitura
            ),
            TextField(
              controller: _numeroController,
              decoration: InputDecoration(labelText: 'Número'),
            ),
            TextField(
              controller: _modoPagamentoController,
              decoration: InputDecoration(labelText: 'Modo de Pagamento'),
            ),
            const SizedBox(height: 20),

            // Exibe o mapa
            _enderecoCarregado
                ? SizedBox(
                  height: 300,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _endereco,
                      zoom: 14,
                    ),
                    onMapCreated: _onMapCreated,
                    markers: {
                      Marker(
                        markerId: MarkerId('endereco'),
                        position: _endereco,
                        infoWindow: InfoWindow(title: 'Endereço de Entrega'),
                      ),
                    },
                  ),
                )
                : _carregandoEndereco
                ? const Center(child: CircularProgressIndicator())
                : const Text('Endereço não encontrado ou inválido.'),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Lógica para finalizar o pedido
                _finalizarPedido();
              },
              child: const Text('Finalizar Pedido'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 32,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função para finalizar o pedido
  void _finalizarPedido() {
    // Aqui você pode adicionar a lógica para finalizar o pedido, como salvar no banco de dados ou enviar para um servidor.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Pedido Finalizado"),
          content: const Text("Seu pedido foi finalizado com sucesso!"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha a confirmação de pedido
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
