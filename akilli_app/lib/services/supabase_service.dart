import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Inicializa o usuário logado se ele existir no SharedPreferences
  Future<void> initLoggedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('logged_user');
    if (userJson != null) {
      try {
        _usuarioLogado = Usuario.fromJson(jsonDecode(userJson));
      } catch (e) {
        print('Erro ao carregar usuário salvo: $e');
      }
    }
  }

  // Último erro para exibição na UI
  String? lastError;

  // ==================== AUTENTICAÇÃO ====================

  /// Faz login via Supabase Auth e busca o perfil na tabela 'usuarios'
  /// Fallback: tenta login direto na tabela para contas criadas antes da migração
  Future<Usuario?> login(String email, String senha) async {
    lastError = null;
    try {
      // 1. Tenta via Supabase Auth (contas novas)
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: senha,
      );

      if (authResponse.user != null) {
        // Busca o perfil na tabela usuarios
        final data = await _client
            .from('usuarios')
            .select()
            .eq('email', email)
            .maybeSingle();

        if (data != null) {
          _usuarioLogado = Usuario.fromJson(data);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('logged_user', jsonEncode(data));
          return _usuarioLogado;
        }
      }
    } catch (e) {
      // Se falhar no Supabase Auth, tenta o método antigo (contas legadas)
      print('Supabase Auth falhou, tentando método legado: $e');
    }

    // 2. Fallback: login legado (contas criadas antes da migração para Supabase Auth)
    try {
      final data = await _client
          .from('usuarios')
          .select()
          .eq('email', email)
          .eq('senha', senha)
          .maybeSingle();

      if (data != null) {
        _usuarioLogado = Usuario.fromJson(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_user', jsonEncode(data));
        return _usuarioLogado;
      } else {
        lastError = 'E-mail ou senha incorretos.';
      }
    } catch (e) {
      lastError = e.toString();
      print('Erro no login legado: $e');
    }

    return null;
  }

  /// Cadastra via Supabase Auth e cria perfil na tabela 'usuarios'
  Future<bool> cadastrarUsuario(Map<String, String> dados) async {
    lastError = null;
    try {
      // 1. Cria o usuário no Supabase Auth
      final authResponse = await _client.auth.signUp(
        email: dados['email']!,
        password: dados['senha']!,
      );

      if (authResponse.user == null) {
        lastError = 'Falha ao criar conta. Tente outro e-mail.';
        return false;
      }

      // 2. Insere o perfil na tabela usuarios
      await _client.from('usuarios').insert({
        'nome': dados['nome'],
        'usuario': dados['usuario'],
        'email': dados['email'],
        'senha': 'supabase_auth', // Senha real gerenciada pelo Supabase Auth (≤20 chars)
        'telefone': dados['telefone'] ?? '', // Telefone é obrigatório no banco
        'plano_assinatura': 'free',
        'pontos': 0,
      });

      return true;
    } catch (e) {
      lastError = e.toString();
      print('Erro no cadastro: $e');
      return false;
    }
  }

  /// Atualiza as informações do perfil do usuário logado
  Future<bool> atualizarPerfil({
    String? nome,
    String? usuario,
    String? email,
    String? telefone,
    String? avatarUrl,
  }) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return false;

      final updateData = <String, dynamic>{};
      if (nome != null) updateData['nome'] = nome;
      if (usuario != null) updateData['usuario'] = usuario;
      if (email != null) updateData['email'] = email;
      if (telefone != null) updateData['telefone'] = telefone;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      await _client
          .from('usuarios')
          .update(updateData)
          .eq('id_usuario', _usuarioLogado!.idUsuario!);

      // Atualiza o usuário local
      _usuarioLogado = Usuario.fromJson({
        ..._usuarioLogado!.toJson(),
        ...updateData,
      });

      // Persiste no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('logged_user', jsonEncode(_usuarioLogado!.toJson()));

      return true;
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      return false;
    }
  }

  /// Verifica se um username já existe no banco
  Future<bool> checkUsernameExists(String username) async {
    try {
      final data = await _client
          .from('usuarios')
          .select('id_usuario')
          .eq('usuario', username);
      return data.isNotEmpty;
    } catch (e) {
      print('Erro ao checar username: $e');
      return false; // Assume não existente em caso de erro para não bloquear, ou trata melhor.
    }
  }

  /// Faz logout (limpa a sessão local e Supabase Auth)
  Future<void> logout() async {
    _usuarioLogado = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_user');
    
    try {
      await _client.auth.signOut();
    } catch (_) {}

    try {
      const channel = MethodChannel('com.akilli/app_blocker');
      await channel.invokeMethod('clearBlockedApps');
    } catch (_) {}
  }

  // ==================== TAREFAS ====================

  /// Cadastra uma nova tarefa no Supabase
  Future<Tarefa?> cadastrarTarefa(Tarefa tarefa) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return null;

      final data = await _client.from('tarefas').insert({
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
        if (tarefa.alertaMinutos != null) 'alerta_minutos': tarefa.alertaMinutos,
      }).select().single();
      return Tarefa.fromJson(data);
    } catch (e) {
      print('Erro ao cadastrar tarefa: $e');
      return null;
    }
  }

  /// Atualiza todos os campos de uma tarefa existente
  Future<Tarefa?> atualizarTarefa(Tarefa tarefa) async {
    try {
      if (tarefa.idTarefa == null) return null;

      final data = await _client
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
            'alerta_minutos': tarefa.alertaMinutos,
          })
          .eq('id_tarefa', tarefa.idTarefa!)
          .select().single();
      return Tarefa.fromJson(data);
    } catch (e) {
      print('Erro ao atualizar tarefa: $e');
      return null;
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

  /// Atualiza o andamento E a data de início de uma tarefa (para quando marca como "Em Andamento")
  Future<bool> atualizarAndamentoComInicio(int tarefaId, String novoAndamento, String novaDataInicio, {String? novaDataFim}) async {
    try {
      final updateData = {
        'andamento': novoAndamento,
        'data_inicio': novaDataInicio,
      };
      if (novaDataFim != null) {
        updateData['data_fim'] = novaDataFim;
      }

      await _client
          .from('tarefas')
          .update(updateData)
          .eq('id_tarefa', tarefaId);
      return true;
    } catch (e) {
      print('Erro ao atualizar tarefa com início: $e');
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

  /// Adiciona pontos diretos ao usuário logado (ex: por tempo poupado ou tarefa)
  Future<bool> adicionarPontos(int quantidade) async {
    try {
      if (_usuarioLogado?.idUsuario == null || quantidade <= 0) return false;
      int pontosAtuais = _usuarioLogado!.pontos ?? 0;
      int novosPontos = (pontosAtuais + quantidade).round();
      
      await _client
          .from('usuarios')
          .update({'pontos': novosPontos})
          .eq('id_usuario', _usuarioLogado!.idUsuario!);
          
      _usuarioLogado = Usuario.fromJson({
        ..._usuarioLogado!.toJson(),
        'pontos': novosPontos,
      });
      return true;
    } catch (e) {
      print('Erro ao adicionar pontos: $e');
      return false;
    }
  }

  // ==================== RANKING ====================

  /// Busca todos os usuários ordenados por pontos (ranking global)
  Future<List<Map<String, dynamic>>> getRanking() async {
    try {
      print('DEBUG getRanking: Iniciando busca...');
      print('DEBUG getRanking: Auth session = ${_client.auth.currentSession != null}');
      print('DEBUG getRanking: Auth user = ${_client.auth.currentUser?.id}');
      
      final data = await _client
          .from('usuarios')
          .select('id_usuario, nome, usuario, pontos')
          .order('pontos', ascending: false)
          .limit(50);

      print('DEBUG getRanking: Retornou ${data.length} registros');
      if (data.isNotEmpty) {
        print('DEBUG getRanking: Primeiro = ${data[0]}');
      }
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('ERRO getRanking: $e');
      return [];
    }
  }

  // ==================== GRUPOS ====================

  /// Gera um código aleatório de 6 caracteres (letras maiúsculas + números)
  String _gerarCodigoGrupo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(6, (i) => chars[(random * (i + 1) * 7 + i * 13) % chars.length]).join();
  }

  /// Cria um novo grupo e adiciona o criador como membro
  Future<Map<String, dynamic>?> criarGrupo(String nome) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return null;

      final codigo = _gerarCodigoGrupo();
      final pontosAtuais = _usuarioLogado!.pontos ?? 0;

      // Cria o grupo
      final grupoData = await _client
          .from('grupos')
          .insert({
            'nome': nome,
            'codigo': codigo,
            'id_criador': _usuarioLogado!.idUsuario!,
          })
          .select()
          .single();

      final idGrupo = grupoData['id_grupo'];

      // Adiciona o criador como membro com pontos_entrada = pontos atuais
      await _client
          .from('membros_grupo')
          .insert({
            'id_grupo': idGrupo,
            'id_usuario': _usuarioLogado!.idUsuario!,
            'pontos_entrada': pontosAtuais,
          });

      return grupoData;
    } catch (e) {
      print('Erro ao criar grupo: $e');
      return null;
    }
  }

  /// Entra em um grupo usando o código
  Future<Map<String, dynamic>?> entrarNoGrupo(String codigo) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return null;

      // Busca o grupo pelo código
      final grupoData = await _client
          .from('grupos')
          .select()
          .eq('codigo', codigo.toUpperCase().trim())
          .maybeSingle();

      if (grupoData == null) return null; // Grupo não encontrado

      final idGrupo = grupoData['id_grupo'];
      final pontosAtuais = _usuarioLogado!.pontos ?? 0;

      // Verifica se já é membro
      final jaExiste = await _client
          .from('membros_grupo')
          .select('id')
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', _usuarioLogado!.idUsuario!)
          .maybeSingle();

      if (jaExiste != null) return grupoData; // Já é membro, retorna o grupo

      // Adiciona como membro
      await _client
          .from('membros_grupo')
          .insert({
            'id_grupo': idGrupo,
            'id_usuario': _usuarioLogado!.idUsuario!,
            'pontos_entrada': pontosAtuais,
          });

      return grupoData;
    } catch (e) {
      print('Erro ao entrar no grupo: $e');
      return null;
    }
  }

  /// Sai de um grupo
  Future<bool> sairDoGrupo(int idGrupo) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return false;

      await _client
          .from('membros_grupo')
          .delete()
          .eq('id_grupo', idGrupo)
          .eq('id_usuario', _usuarioLogado!.idUsuario!);

      return true;
    } catch (e) {
      print('Erro ao sair do grupo: $e');
      return false;
    }
  }

  /// Busca os grupos do usuário logado
  Future<List<Map<String, dynamic>>> getMeusGrupos() async {
    try {
      if (_usuarioLogado?.idUsuario == null) return [];

      final membros = await _client
          .from('membros_grupo')
          .select('id_grupo, pontos_entrada, entrou_em, grupos(id_grupo, nome, codigo, id_criador, criado_em)')
          .eq('id_usuario', _usuarioLogado!.idUsuario!);

      return List<Map<String, dynamic>>.from(membros);
    } catch (e) {
      print('Erro ao buscar grupos: $e');
      return [];
    }
  }

  /// Busca o ranking de um grupo (pontos relativos à entrada)
  Future<List<Map<String, dynamic>>> getRankingGrupo(int idGrupo) async {
    try {
      final membros = await _client
          .from('membros_grupo')
          .select('id_usuario, pontos_entrada, entrou_em, usuarios(id_usuario, nome, usuario, pontos)')
          .eq('id_grupo', idGrupo);

      // Calcula pontos relativos e ordena
      List<Map<String, dynamic>> ranking = [];
      for (var m in membros) {
        final usuario = m['usuarios'];
        if (usuario == null) continue;
        final pontosAtuais = usuario['pontos'] ?? 0;
        final pontosEntrada = m['pontos_entrada'] ?? 0;
        final pontosNoGrupo = pontosAtuais - pontosEntrada;

        ranking.add({
          'id_usuario': usuario['id_usuario'],
          'nome': usuario['nome'] ?? 'Anônimo',
          'usuario': usuario['usuario'] ?? '',
          'pontos': pontosNoGrupo < 0 ? 0 : pontosNoGrupo,
          'entrou_em': m['entrou_em'],
        });
      }

      ranking.sort((a, b) => (b['pontos'] as int).compareTo(a['pontos'] as int));
      return ranking;
    } catch (e) {
      print('Erro ao buscar ranking do grupo: $e');
      return [];
    }
  }

  /// Busca a quantidade de membros de um grupo
  Future<int> getQuantidadeMembros(int idGrupo) async {
    try {
      final data = await _client
          .from('membros_grupo')
          .select('id')
          .eq('id_grupo', idGrupo);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  // ==================== SOCIAL / BUSCA ====================
  
  /// Busca usuários pelo 'usuario' ou 'nome'
  Future<List<Map<String, dynamic>>> buscarUsuarios(String query) async {
    try {
      if (_usuarioLogado?.idUsuario == null || query.trim().isEmpty) return [];

      final data = await _client
          .from('usuarios')
          .select('id_usuario, nome, usuario, pontos')
          .neq('id_usuario', _usuarioLogado!.idUsuario!)
          .or('usuario.ilike.%$query%,nome.ilike.%$query%')
          .limit(20);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      return [];
    }
  }

  /// Verifica status de amizade
  Future<String?> checarStatusAmizade(int outroUserId) async {
    try {
      final meuId = _usuarioLogado!.idUsuario!;
      final data = await _client
          .from('amizades')
          .select('status, usuario1_id')
          .or('and(usuario1_id.eq.$meuId,usuario2_id.eq.$outroUserId),and(usuario1_id.eq.$outroUserId,usuario2_id.eq.$meuId)')
          .maybeSingle();

      if (data == null) return null; // Não há registro
      
      final status = data['status'];
      if (status == 'pendente') {
        return data['usuario1_id'] == meuId ? 'enviado' : 'recebido';
      }
      return status; // 'aceito' ou 'recusado'
    } catch (e) {
      return null;
    }
  }

  /// Envia solicitação de amizade
  Future<bool> enviarSolicitacaoAmizade(int outroUserId) async {
    try {
      await _client.from('amizades').insert({
        'usuario1_id': _usuarioLogado!.idUsuario!,
        'usuario2_id': outroUserId,
        'status': 'pendente',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Aceita ou recusa amizade
  Future<bool> responderSolicitacaoAmizade(int outroUserId, String resposta) async {
    try {
      final meuId = _usuarioLogado!.idUsuario!;
      await _client
          .from('amizades')
          .update({'status': resposta})
          .eq('usuario1_id', outroUserId)
          .eq('usuario2_id', meuId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Busca o ranking de amigos do usuário atual
  Future<List<Map<String, dynamic>>> getRankingAmigos() async {
    try {
      if (_usuarioLogado?.idUsuario == null) return [];
      
      final meuId = _usuarioLogado!.idUsuario!;
      
      // Busca as amizades aceitas
      final amizadesData = await _client
          .from('amizades')
          .select('usuario1_id, usuario2_id')
          .eq('status', 'aceito')
          .or('usuario1_id.eq.$meuId,usuario2_id.eq.$meuId');
          
      List<int> amigosIds = [meuId]; // Inclui o próprio usuário no ranking
      
      for (var a in amizadesData) {
        final u1 = a['usuario1_id'] is int ? a['usuario1_id'] as int : int.tryParse(a['usuario1_id'].toString()) ?? 0;
        final u2 = a['usuario2_id'] is int ? a['usuario2_id'] as int : int.tryParse(a['usuario2_id'].toString()) ?? 0;
        if (u1 == meuId) {
          amigosIds.add(u2);
        } else {
          amigosIds.add(u1);
        }
      }
      
      // Remove duplicatas
      amigosIds = amigosIds.toSet().toList();
      
      print('DEBUG getRankingAmigos: meuId=$meuId, amizadesData=${amizadesData.length}, amigosIds=$amigosIds');
      
      // Busca os detalhes dos usuários
      final usuariosData = await _client
          .from('usuarios')
          .select('id_usuario, nome, usuario, pontos')
          .inFilter('id_usuario', amigosIds)
          .order('pontos', ascending: false);
      
      print('DEBUG getRankingAmigos: usuariosData retornados=${usuariosData.length}');
          
      return List<Map<String, dynamic>>.from(usuariosData);
    } catch (e) {
      print('Erro ao buscar ranking de amigos: $e');
      return [];
    }
  }

  /// Envia convite de grupo
  Future<bool> convidarParaGrupo(int destinatarioId, int grupoId) async {
    try {
      await _client.from('convites_grupo').insert({
        'remetente_id': _usuarioLogado!.idUsuario!,
        'destinatario_id': destinatarioId,
        'grupo_id': grupoId,
        'status': 'pendente',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== NOTIFICAÇÕES ====================

  /// Busca solicitações de amizade pendentes RECEBIDAS pelo usuário logado
  Future<List<Map<String, dynamic>>> getSolicitacoesAmizadePendentes() async {
    try {
      if (_usuarioLogado?.idUsuario == null) return [];

      final meuId = _usuarioLogado!.idUsuario!;

      // Busca amizades pendentes onde EU sou o usuario2 (receptor)
      final data = await _client
          .from('amizades')
          .select('id, usuario1_id, usuario2_id, status, criado_em, usuarios!amizades_usuario1_id_fkey(id_usuario, nome, usuario, pontos)')
          .eq('usuario2_id', meuId)
          .eq('status', 'pendente')
          .order('criado_em', ascending: false);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Erro ao buscar solicitações de amizade: $e');
      // Fallback: tenta sem o join caso a FK não exista
      try {
        final meuId = _usuarioLogado!.idUsuario!;
        final amizades = await _client
            .from('amizades')
            .select('id, usuario1_id, usuario2_id, status, criado_em')
            .eq('usuario2_id', meuId)
            .eq('status', 'pendente');

        // Busca os dados dos remetentes manualmente
        List<Map<String, dynamic>> result = [];
        for (var a in amizades) {
          final remetenteData = await _client
              .from('usuarios')
              .select('id_usuario, nome, usuario, pontos')
              .eq('id_usuario', a['usuario1_id'])
              .maybeSingle();

          result.add({
            ...a,
            'usuarios': remetenteData,
          });
        }
        return result;
      } catch (e2) {
        print('Erro no fallback de solicitações: $e2');
        return [];
      }
    }
  }

  /// Busca convites de grupo pendentes RECEBIDOS pelo usuário logado
  Future<List<Map<String, dynamic>>> getConvitesGrupoPendentes() async {
    try {
      if (_usuarioLogado?.idUsuario == null) return [];

      final meuId = _usuarioLogado!.idUsuario!;

      // Busca convites pendentes com dados do remetente e do grupo
      final data = await _client
          .from('convites_grupo')
          .select('id, remetente_id, destinatario_id, grupo_id, status, criado_em')
          .eq('destinatario_id', meuId)
          .eq('status', 'pendente')
          .order('criado_em', ascending: false);

      // Enriquece com dados do remetente e do grupo
      List<Map<String, dynamic>> result = [];
      for (var c in data) {
        final remetenteData = await _client
            .from('usuarios')
            .select('id_usuario, nome, usuario')
            .eq('id_usuario', c['remetente_id'])
            .maybeSingle();

        final grupoData = await _client
            .from('grupos')
            .select('id_grupo, nome, codigo')
            .eq('id_grupo', c['grupo_id'])
            .maybeSingle();

        result.add({
          ...c,
          'remetente': remetenteData,
          'grupo': grupoData,
        });
      }

      return result;
    } catch (e) {
      print('Erro ao buscar convites de grupo: $e');
      return [];
    }
  }

  /// Responde a um convite de grupo (aceitar ou recusar)
  Future<bool> responderConviteGrupo(int conviteId, int grupoId, String resposta) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return false;

      // Atualiza o status do convite
      await _client
          .from('convites_grupo')
          .update({'status': resposta})
          .eq('id', conviteId);

      // Se aceitou, adiciona ao grupo
      if (resposta == 'aceito') {
        final pontosAtuais = _usuarioLogado!.pontos ?? 0;

        // Verifica se já é membro
        final jaExiste = await _client
            .from('membros_grupo')
            .select('id')
            .eq('id_grupo', grupoId)
            .eq('id_usuario', _usuarioLogado!.idUsuario!)
            .maybeSingle();

        if (jaExiste == null) {
          await _client
              .from('membros_grupo')
              .insert({
                'id_grupo': grupoId,
                'id_usuario': _usuarioLogado!.idUsuario!,
                'pontos_entrada': pontosAtuais,
              });
        }
      }

      return true;
    } catch (e) {
      print('Erro ao responder convite de grupo: $e');
      return false;
    }
  }

  /// Conta o total de notificações pendentes (amizades + convites de grupo)
  Future<int> contarNotificacoesPendentes() async {
    try {
      if (_usuarioLogado?.idUsuario == null) return 0;

      final meuId = _usuarioLogado!.idUsuario!;

      // Conta amizades pendentes recebidas
      final amizades = await _client
          .from('amizades')
          .select('id')
          .eq('usuario2_id', meuId)
          .eq('status', 'pendente');

      // Conta convites de grupo pendentes
      final convites = await _client
          .from('convites_grupo')
          .select('id')
          .eq('destinatario_id', meuId)
          .eq('status', 'pendente');

      return (amizades as List).length + (convites as List).length;
    } catch (e) {
      print('Erro ao contar notificações: $e');
      return 0;
    }
  }


  // ==================== ARQUIVOS ====================
  Future<String?> uploadAvatar(String imagePath, String fileName) async {
    try {
      if (_usuarioLogado?.idUsuario == null) return null;

      final file = File(imagePath);
      final filePath = '${_usuarioLogado!.idUsuario}/$fileName';
      
      await _client.storage.from('avatars').upload(filePath, file, fileOptions: const FileOptions(upsert: true));
      
      final imageUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      
      // Update user in the database
      await atualizarPerfil(avatarUrl: imageUrl);
      
      return imageUrl;
    } catch (e) {
      print('Erro ao fazer upload do avatar: $e');
      return null;
    }
  }
}
