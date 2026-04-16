class Tarefa {
  final int? idTarefa;
  final int? idUsuario;
  final String titulo;
  final String prioridade; // Alta, Média, Baixa (prioridade_enum)
  final String? dataInicio;
  final String? dataFim;
  final String descricao;
  final String andamento; // Pendente, Em Andamento, Concluída, Cancelada (andamento_enum)
  final String? appProdutividade; // Package_name do app de foco ligado à tarefa (Opcional)
  final bool modoFoco; // Indica se a tarefa usará bloqueio de foco

  Tarefa({
    this.idTarefa,
    this.idUsuario,
    required this.titulo,
    required this.prioridade,
    this.dataInicio,
    this.dataFim,
    required this.descricao,
    required this.andamento,
    this.appProdutividade,
    this.modoFoco = false,
  });

  factory Tarefa.fromJson(Map<String, dynamic> json) {
    return Tarefa(
      idTarefa: json['id_tarefa'],
      idUsuario: json['id_usuario'],
      titulo: json['titulo'] ?? '',
      prioridade: json['prioridade'] ?? 'Média',
      dataInicio: json['data_inicio']?.toString(),
      dataFim: json['data_fim']?.toString(),
      descricao: json['descricao'] ?? '',
      andamento: json['andamento'] ?? 'Pendente',
      appProdutividade: json['app_produtividade'],
      modoFoco: json['modo_foco'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (idTarefa != null) 'id_tarefa': idTarefa,
        if (idUsuario != null) 'id_usuario': idUsuario,
        'titulo': titulo,
        'prioridade': prioridade,
        'data_inicio': dataInicio,
        'data_fim': dataFim,
        'descricao': descricao,
        'andamento': andamento,
        'app_produtividade': appProdutividade,
        'modo_foco': modoFoco,
      };
}
