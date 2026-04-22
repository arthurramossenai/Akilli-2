import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import '../models/tarefa.dart';
import '../models/sessao_foco.dart';

class SupabaseService {
  // Singleton - garante que o usuário logado persiste entre telas
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Armazena o usuário logado na sessão atual
  Usuario? _usuarioLogado;
  Usuario? get usuarioLogado => _usuarioLogado;

  // ==================== AUTENTICAÇÃO ====================

  /// Faz login verificando email e senha na tabela 'usuarios'
  Future<Usuario?> login(String email, String senha) async {
    try {
      final data = await _client
          .from('usuarios')
          .select()
          .eq('email', email)
          .eq('senha', senha)
          .maybeSingle();

      if (data != null) {
        _usuarioLogado = Usuario.fromJson(data);
        return _usuarioLogado;
      }
    } catch (e) {
      print('Erro no login: $e');
    }
    return null;
  }

  /// Cadastra um novo usuário na tabela 'usuarios'
  Future<bool> cadastrarUsuario(Map<String, String> dados) async {
    try {
      await _client.from('usuarios').insert({
        'nome': dados['nome'],
        'usuario': dados['usuario'],
        'email': dados['email'],
        'senha': dados['senha'],
        'confirmacao_senha': dados['confirmacao_senha'],
        'telefone': dados['telefone'],
        'plano_assinatura': 'free',
        'pontos': 0,
      });
      return true;
    } catch (e) {
      print('Erro no cadastro: $e');
      return false;
    }
  }

  /// Faz logout (limpa a sessão local)
  void logout() {
    _usuarioLogado = null;
  }

  // ==================== TAREFAS ====================

  /// Cadastra uma nova tarefa no Supabase
  Future<bool> cadastrarTarefa(Tarefa tarefa) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return false;

      await _client.from('tarefas').insert({
        'id_usuario': _usuarioLogado!.idUsuario,
        'titulo': tarefa.titulo,
        'prioridade': tarefa.prioridade,
        'data_inicio': tarefa.dataInicio,
        'data_fim': tarefa.dataFim,
        'descricao': tarefa.descricao,
        'andamento': tarefa.andamento,
        'modo_foco': tarefa.modoFoco,
        'app_produtividade': tarefa.appProdutividade,
        if (tarefa.appsBloqueados != null) 'apps_bloqueados': tarefa.appsBloqueados,
      });
      return true;
    } catch (e) {
      print('Erro ao cadastrar tarefa: $e');
      return false;
    }
  }

  /// Atualiza todos os campos de uma tarefa existente
  Future<bool> atualizarTarefa(Tarefa tarefa) async {
    try {
      if (tarefa.idTarefa == null) return false;

      await _client
          .from('tarefas')
          .update({
            'titulo': tarefa.titulo,
            'prioridade': tarefa.prioridade,
            'data_inicio': tarefa.dataInicio,
            'data_fim': tarefa.dataFim,
            'descricao': tarefa.descricao,
            'andamento': tarefa.andamento,
            'modo_foco': tarefa.modoFoco,
            'app_produtividade': tarefa.appProdutividade,
            'apps_bloqueados': tarefa.appsBloqueados,
          })
          .eq('id_tarefa', tarefa.idTarefa!);
      return true;
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
      return false;
    }
  }

  /// Busca todas as tarefas do usuário logado
  Future<List<Tarefa>> getTarefas() async {
    try {
      if (_usuarioLogado?.idUsuario == null) return [];

      final data = await _client
          .from('tarefas')
          .select()
          .eq('id_usuario', _usuarioLogado!.idUsuario!)
          .order('id_tarefa', ascending: false);

      return (data as List).map((item) => Tarefa.fromJson(item)).toList();
    } catch (e) {
      print('Erro ao buscar tarefas: $e');
      return [];
    }
  }

  /// Atualiza o andamento de uma tarefa
  Future<bool> atualizarAndamento(int tarefaId, String novoAndamento) async {
    try {
      await _client
          .from('tarefas')
          .update({'andamento': novoAndamento})
          .eq('id_tarefa', tarefaId);
      return true;
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
      return false;
    }
  }

  /// Deleta uma tarefa
  Future<bool> deletarTarefa(int tarefaId) async {
    try {
      await _client.from('tarefas').delete().eq('id_tarefa', tarefaId);
      return true;
    } catch (e) {
      print('Erro ao deletar tarefa: $e');
      return false;
    }
  }

  // ==================== SESSÕES DE FOCO ====================

  /// Salva uma sessão de foco finalizada e adiciona pontos ao usuário
  Future<bool> salvarSessaoFoco(SessaoFoco sessao) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return false;

      // Insere a sessão na tabela
      await _client.from('sessoes_foco').insert({
        'id_usuario': _usuarioLogado!.idUsuario,
        if (sessao.idTarefa != null) 'id_tarefa': sessao.idTarefa,
        'inicio_sessao': sessao.inicioSessao.toIso8601String(),
        'fim_sessao': sessao.fimSessao.toIso8601String(),
        'duracao_minutos': sessao.duracaoMinutos,
        'status_sessao': sessao.statusSessao,
        if (sessao.appsBloqueados != null) 'apps_bloqueados': sessao.appsBloqueados,
        'falhas': sessao.falhas,
        'pontos_ganhos': sessao.pontosGanhos,
      });

      // Atualiza os pontos do usuário
      if (sessao.pontosGanhos > 0) {
        int pontosAtuais = _usuarioLogado!.pontos ?? 0;
        int novosPontos = pontosAtuais + sessao.pontosGanhos;
        await _client
            .from('usuarios')
            .update({'pontos': novosPontos})
            .eq('id_usuario', _usuarioLogado!.idUsuario!);
        // Atualiza localmente também
        _usuarioLogado = Usuario.fromJson({
          ..._usuarioLogado!.toJson(),
          'pontos': novosPontos,
        });
      }

      return true;
    } catch (e) {
      print('Erro ao salvar sessão de foco: $e');
      return false;
    }
  }

  // ==================== RANKING ====================

  /// Busca todos os usuários ordenados por pontos (ranking global)
  Future<List<Map<String, dynamic>>> getRanking() async {
    try {
      final data = await _client
          .from('usuarios')
          .select('id_usuario, nome, usuario, pontos')
          .order('pontos', ascending: false)
          .limit(50);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar ranking: $e');
      return [];
    }
  }
}
