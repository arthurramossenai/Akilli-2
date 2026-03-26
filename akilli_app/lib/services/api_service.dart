import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/usuario.dart';
import '../models/tarefa.dart';
import '../config.dart';

class AkilliApiService {
  // Endereço recuperado dinamicamente do Node.js
  final String baseUrl = ApiConfig.baseUrl; 

  Future<Usuario?> login(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        body: {'email': email, 'senha': senha},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Usuario.fromJson(data['user']);
      }
    } catch (e) {
      print('Erro no login: $e');
    }
    return null;
  }

  Future<bool> cadastrarUsuario(Map<String, String> dados) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cadastro'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(dados),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Erro no cadastro de usuario: $e');
      return false;
    }
  }

  Future<bool> cadastrarTarefa(Tarefa tarefa) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addTarefa'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(tarefa.toJson()),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Erro ao cadastrar tarefa: $e');
      return false;
    }
  }

  // Opcional: Fetch Tarefas
  Future<List<Tarefa>> getTarefas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/tarefas'));
      if (response.statusCode == 200) {
        Iterable l = jsonDecode(response.body);
        return List<Tarefa>.from(l.map((model) => Tarefa.fromJson(model)));
      }
    } catch (e) {
        print('Erro ao buscar tarefas: $e');
    }
    return [];
  }
}
