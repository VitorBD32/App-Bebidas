import 'dart:convert';
import 'package:http/http.dart' as http;

// URL do seu Realtime Database no Firebase
const String apiUrl =
    'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas.json';

// Função para carregar as bebidas do Firebase
Future<List<Map>> getBebidas() async {
  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map>.from(data.values);
    } else {
      throw Exception('Falha ao carregar bebidas');
    }
  } catch (e) {
    throw Exception('Erro ao buscar bebidas: $e');
  }
}

// Função para adicionar bebida ao Firebase
Future<void> adicionarBebida(Map bebida) async {
  try {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bebida),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao adicionar bebida');
    }
  } catch (e) {
    throw Exception('Erro ao adicionar bebida: $e');
  }
}

// Função para editar bebida no Firebase
Future<void> editarBebida(String id, Map bebida) async {
  try {
    final response = await http.put(
      Uri.parse(
        'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas/$id.json',
      ),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bebida),
    );

    // Verificando se a resposta foi bem-sucedida
    if (response.statusCode != 200) {
      throw Exception('Falha ao editar bebida');
    }
  } catch (e) {
    throw Exception('Erro ao editar bebida: $e');
  }
}

// Função para excluir bebida do Firebase
Future<void> excluirBebida(String id) async {
  try {
    final response = await http.delete(
      Uri.parse(
        'https://app-de-bebidas-826aa-default-rtdb.firebaseio.com/bebidas/$id.json',
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Falha ao excluir bebida');
    }
  } catch (e) {
    throw Exception('Erro ao excluir bebida: $e');
  }
}
